#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#if !defined(_WIN32)
#include <unistd.h>
#endif

#include "moonbit.h"

static int moon_rodio_append_pcm_i16(int16_t **buf,
                                     size_t *len,
                                     size_t *cap,
                                     const int16_t *src,
                                     size_t src_len) {
  if (src_len == 0) {
    return 0;
  }
  if (*len + src_len > *cap) {
    size_t new_cap = (*cap == 0) ? 4096 : *cap;
    while (new_cap < *len + src_len) {
      new_cap *= 2;
    }
    int16_t *new_buf = (int16_t *)realloc(*buf, new_cap * sizeof(int16_t));
    if (new_buf == NULL) {
      return -1;
    }
    *buf = new_buf;
    *cap = new_cap;
  }

  memcpy(*buf + *len, src, src_len * sizeof(int16_t));
  *len += src_len;
  return 0;
}

#if defined(__APPLE__)
#include <AudioToolbox/AudioToolbox.h>

typedef struct {
  const uint8_t *data;
  int64_t len;
} moon_rodio_memory_file_t;

static OSStatus moon_rodio_read_proc(void *inClientData,
                                     SInt64 inPosition,
                                     UInt32 requestCount,
                                     void *buffer,
                                     UInt32 *actualCount) {
  moon_rodio_memory_file_t *file = (moon_rodio_memory_file_t *)inClientData;
  if (actualCount == NULL || file == NULL || buffer == NULL) {
    return -50;
  }
  if (inPosition < 0 || inPosition >= file->len) {
    *actualCount = 0;
    return noErr;
  }

  uint64_t available = (uint64_t)(file->len - inPosition);
  uint32_t to_copy = requestCount;
  if ((uint64_t)to_copy > available) {
    to_copy = (uint32_t)available;
  }

  if (to_copy > 0) {
    memcpy(buffer, file->data + inPosition, to_copy);
  }
  *actualCount = to_copy;
  return noErr;
}

static SInt64 moon_rodio_get_size_proc(void *inClientData) {
  moon_rodio_memory_file_t *file = (moon_rodio_memory_file_t *)inClientData;
  if (file == NULL) {
    return 0;
  }
  return (SInt64)file->len;
}
#endif

#if defined(MOON_RODIO_ENABLE_FFMPEG) && MOON_RODIO_ENABLE_FFMPEG
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/mem.h>
#include <libavutil/opt.h>
#include <libavutil/samplefmt.h>
#include <libavutil/version.h>
#include <libavutil/channel_layout.h>

static int moon_rodio_write_temp_file(const uint8_t *input, int32_t input_len, char *path, size_t path_len) {
  if (input == NULL || input_len <= 0 || path == NULL || path_len == 0) {
    return -1;
  }

#if defined(_WIN32)
  if (tmpnam_s(path, path_len) != 0) {
    return -1;
  }
#else
  const char *tmpl = "/tmp/moon_rodio_mp4a_XXXXXX";
  size_t tmpl_len = strlen(tmpl);
  if (path_len <= tmpl_len) {
    return -1;
  }
  memcpy(path, tmpl, tmpl_len + 1);
  int fd = mkstemp(path);
  if (fd < 0) {
    return -1;
  }
  FILE *f = fdopen(fd, "wb");
  if (f == NULL) {
    close(fd);
    remove(path);
    return -1;
  }
#endif

#if defined(_WIN32)
  FILE *f = fopen(path, "wb");
  if (f == NULL) {
    return -1;
  }
#endif

  size_t wrote = fwrite(input, 1, (size_t)input_len, f);
  fclose(f);
  if (wrote != (size_t)input_len) {
    remove(path);
    return -1;
  }
  return 0;
}

static int moon_rodio_get_channels_from_codec_ctx(const AVCodecContext *ctx) {
  if (ctx == NULL) {
    return 0;
  }
#if LIBAVUTIL_VERSION_MAJOR >= 57
  if (ctx->ch_layout.nb_channels > 0) {
    return (int)ctx->ch_layout.nb_channels;
  }
#else
  if (ctx->channels > 0) {
    return ctx->channels;
  }
#endif
  return 0;
}

static int moon_rodio_get_channels_from_codecpar(const AVCodecParameters *codecpar) {
  if (codecpar == NULL) {
    return 0;
  }
#if LIBAVUTIL_VERSION_MAJOR >= 57
  if (codecpar->ch_layout.nb_channels > 0) {
    return (int)codecpar->ch_layout.nb_channels;
  }
#else
  if (codecpar->channels > 0) {
    return codecpar->channels;
  }
#endif
  return 0;
}

#if LIBAVUTIL_VERSION_MAJOR < 57
static int64_t moon_rodio_get_channel_layout(const AVCodecContext *ctx, int channels) {
  if (ctx == NULL) {
    return 0;
  }
  if (ctx->channel_layout != 0) {
    return (int64_t)ctx->channel_layout;
  }
  if (channels <= 0) {
    channels = ctx->channels;
  }
  if (channels <= 0) {
    return 0;
  }
  return av_get_default_channel_layout(channels);
}
#endif

static int moon_rodio_convert_frame_to_s16(SwrContext *swr,
                                           AVFrame *frame,
                                           int sample_rate,
                                           int channels,
                                           int16_t **pcm_all,
                                           size_t *pcm_len,
                                           size_t *pcm_cap) {
  if (swr == NULL || frame == NULL || channels <= 0 || sample_rate <= 0) {
    return -1;
  }

  int dst_nb_samples = (int)av_rescale_rnd(
      swr_get_delay(swr, sample_rate) + frame->nb_samples,
      sample_rate,
      sample_rate,
      AV_ROUND_UP);
  if (dst_nb_samples <= 0) {
    return -1;
  }

  uint8_t **dst_data = NULL;
  int dst_linesize = 0;
  if (av_samples_alloc_array_and_samples(
          &dst_data,
          &dst_linesize,
          channels,
          dst_nb_samples,
          AV_SAMPLE_FMT_S16,
          0) < 0) {
    return -1;
  }

  int converted = swr_convert(
      swr,
      dst_data,
      dst_nb_samples,
      (const uint8_t **)frame->extended_data,
      frame->nb_samples);
  if (converted < 0) {
    av_freep(&dst_data[0]);
    av_freep(&dst_data);
    return -1;
  }

  size_t sample_count = (size_t)converted * (size_t)channels;
  int append_status = moon_rodio_append_pcm_i16(
      pcm_all,
      pcm_len,
      pcm_cap,
      (const int16_t *)dst_data[0],
      sample_count);
  av_freep(&dst_data[0]);
  av_freep(&dst_data);
  return append_status;
}

static int moon_rodio_decode_mp4a_ffmpeg(const uint8_t *input,
                                         int32_t input_len,
                                         int16_t **pcm_out,
                                         size_t *sample_count_out,
                                         int *channels_out,
                                         int *sample_rate_out) {
  char temp_path[512];
  temp_path[0] = '\0';
  if (moon_rodio_write_temp_file(input, input_len, temp_path, sizeof(temp_path)) != 0) {
    return 101;
  }

  int status_code = 0;
  AVFormatContext *format_ctx = NULL;
  AVCodecContext *codec_ctx = NULL;
  SwrContext *swr = NULL;
  AVPacket *packet = NULL;
  AVFrame *frame = NULL;
#if LIBAVUTIL_VERSION_MAJOR >= 57
  AVChannelLayout input_layout = {0};
  AVChannelLayout output_layout = {0};
  int input_layout_initialized = 0;
  int output_layout_initialized = 0;
#endif

  int16_t *pcm_all = NULL;
  size_t pcm_len = 0;
  size_t pcm_cap = 0;

  if (avformat_open_input(&format_ctx, temp_path, NULL, NULL) < 0) {
    status_code = 102;
    goto cleanup;
  }
  if (avformat_find_stream_info(format_ctx, NULL) < 0) {
    status_code = 103;
    goto cleanup;
  }

  int audio_stream_index = av_find_best_stream(format_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
  if (audio_stream_index < 0) {
    status_code = 104;
    goto cleanup;
  }

  AVStream *audio_stream = format_ctx->streams[audio_stream_index];
  const AVCodec *codec = avcodec_find_decoder(audio_stream->codecpar->codec_id);
  if (codec == NULL) {
    status_code = 105;
    goto cleanup;
  }

  codec_ctx = avcodec_alloc_context3(codec);
  if (codec_ctx == NULL) {
    status_code = 106;
    goto cleanup;
  }
  if (avcodec_parameters_to_context(codec_ctx, audio_stream->codecpar) < 0) {
    status_code = 105;
    goto cleanup;
  }
  if (avcodec_open2(codec_ctx, codec, NULL) < 0) {
    status_code = 105;
    goto cleanup;
  }

  int channels = moon_rodio_get_channels_from_codec_ctx(codec_ctx);
  if (channels <= 0) {
    channels = moon_rodio_get_channels_from_codecpar(audio_stream->codecpar);
  }
  int sample_rate = codec_ctx->sample_rate;
  if (sample_rate <= 0) {
    sample_rate = audio_stream->codecpar->sample_rate;
  }
  if (channels <= 0 || sample_rate <= 0) {
    status_code = 105;
    goto cleanup;
  }

#if LIBAVUTIL_VERSION_MAJOR >= 57
  if (codec_ctx->ch_layout.nb_channels > 0) {
    if (av_channel_layout_copy(&input_layout, &codec_ctx->ch_layout) < 0) {
      status_code = 106;
      goto cleanup;
    }
  } else {
    av_channel_layout_default(&input_layout, channels);
  }
  input_layout_initialized = 1;

  av_channel_layout_default(&output_layout, channels);
  output_layout_initialized = 1;

  if (swr_alloc_set_opts2(
          &swr,
          &output_layout,
          AV_SAMPLE_FMT_S16,
          sample_rate,
          &input_layout,
          codec_ctx->sample_fmt,
          sample_rate,
          0,
          NULL) < 0 ||
      swr == NULL ||
      swr_init(swr) < 0) {
    status_code = 106;
    goto cleanup;
  }
#else
  int64_t input_layout = moon_rodio_get_channel_layout(codec_ctx, channels);
  if (input_layout == 0) {
    status_code = 105;
    goto cleanup;
  }
  int64_t output_layout = av_get_default_channel_layout(channels);
  swr = swr_alloc_set_opts(
      NULL,
      output_layout,
      AV_SAMPLE_FMT_S16,
      sample_rate,
      input_layout,
      codec_ctx->sample_fmt,
      sample_rate,
      0,
      NULL);
  if (swr == NULL || swr_init(swr) < 0) {
    status_code = 106;
    goto cleanup;
  }
#endif

  packet = av_packet_alloc();
  frame = av_frame_alloc();
  if (packet == NULL || frame == NULL) {
    status_code = 106;
    goto cleanup;
  }

  int decode_failed = 0;
  while (av_read_frame(format_ctx, packet) >= 0) {
    if (packet->stream_index == audio_stream_index) {
      if (avcodec_send_packet(codec_ctx, packet) < 0) {
        decode_failed = 1;
      } else {
        while (!decode_failed) {
          int recv = avcodec_receive_frame(codec_ctx, frame);
          if (recv == AVERROR(EAGAIN) || recv == AVERROR_EOF) {
            break;
          }
          if (recv < 0 || moon_rodio_convert_frame_to_s16(
                              swr,
                              frame,
                              sample_rate,
                              channels,
                              &pcm_all,
                              &pcm_len,
                              &pcm_cap) != 0) {
            decode_failed = 1;
            break;
          }
        }
      }
    }
    av_packet_unref(packet);
    if (decode_failed) {
      break;
    }
  }

  if (!decode_failed) {
    if (avcodec_send_packet(codec_ctx, NULL) < 0) {
      decode_failed = 1;
    } else {
      while (!decode_failed) {
        int recv = avcodec_receive_frame(codec_ctx, frame);
        if (recv == AVERROR(EAGAIN) || recv == AVERROR_EOF) {
          break;
        }
        if (recv < 0 || moon_rodio_convert_frame_to_s16(
                            swr,
                            frame,
                            sample_rate,
                            channels,
                            &pcm_all,
                            &pcm_len,
                            &pcm_cap) != 0) {
          decode_failed = 1;
          break;
        }
      }
    }
  }

  if (decode_failed || pcm_len == 0) {
    status_code = 107;
    goto cleanup;
  }

  *pcm_out = pcm_all;
  *sample_count_out = pcm_len;
  *channels_out = channels;
  *sample_rate_out = sample_rate;
  pcm_all = NULL; /* ownership moved */

cleanup:
  if (packet != NULL) {
    av_packet_free(&packet);
  }
  if (frame != NULL) {
    av_frame_free(&frame);
  }
  if (swr != NULL) {
    swr_free(&swr);
  }
#if LIBAVUTIL_VERSION_MAJOR >= 57
  if (input_layout_initialized) {
    av_channel_layout_uninit(&input_layout);
  }
  if (output_layout_initialized) {
    av_channel_layout_uninit(&output_layout);
  }
#endif
  if (codec_ctx != NULL) {
    avcodec_free_context(&codec_ctx);
  }
  if (format_ctx != NULL) {
    avformat_close_input(&format_ctx);
  }
  if (temp_path[0] != '\0') {
    remove(temp_path);
  }
  if (pcm_all != NULL) {
    free(pcm_all);
  }
  return status_code;
}
#endif

moonbit_bytes_t moon_rodio_mp4a_decode_all_i16le(uint8_t *input,
                                                  int32_t input_len,
                                                  uint32_t *out_meta,
                                                  int32_t out_meta_len) {
  // out_meta layout: [status, channels, sample_rate]
  if (out_meta != NULL && out_meta_len >= 3) {
    out_meta[0] = 0;
    out_meta[1] = 0;
    out_meta[2] = 0;
  }

  if (input == NULL || input_len <= 0) {
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 1;
    }
    return moonbit_make_bytes_raw(0);
  }

#if defined(__APPLE__)
  moon_rodio_memory_file_t file = {
      .data = input,
      .len = (int64_t)input_len,
  };

  AudioFileID audio_file = NULL;
  OSStatus status = AudioFileOpenWithCallbacks(&file,
                                               moon_rodio_read_proc,
                                               NULL,
                                               moon_rodio_get_size_proc,
                                               NULL,
                                               kAudioFileM4AType,
                                               &audio_file);
  if (status != noErr || audio_file == NULL) {
    status = AudioFileOpenWithCallbacks(&file,
                                        moon_rodio_read_proc,
                                        NULL,
                                        moon_rodio_get_size_proc,
                                        NULL,
                                        0,
                                        &audio_file);
  }
  if (status != noErr || audio_file == NULL) {
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 2;
    }
    return moonbit_make_bytes_raw(0);
  }

  ExtAudioFileRef ext_file = NULL;
  status = ExtAudioFileWrapAudioFileID(audio_file, true, &ext_file);
  if (status != noErr || ext_file == NULL) {
    AudioFileClose(audio_file);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 3;
    }
    return moonbit_make_bytes_raw(0);
  }

  AudioStreamBasicDescription file_format;
  memset(&file_format, 0, sizeof(file_format));
  UInt32 property_size = (UInt32)sizeof(file_format);
  status = ExtAudioFileGetProperty(ext_file,
                                   kExtAudioFileProperty_FileDataFormat,
                                   &property_size,
                                   &file_format);
  if (status != noErr || file_format.mChannelsPerFrame == 0 || file_format.mSampleRate <= 0) {
    ExtAudioFileDispose(ext_file);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 4;
    }
    return moonbit_make_bytes_raw(0);
  }

  AudioStreamBasicDescription client_format;
  memset(&client_format, 0, sizeof(client_format));
  client_format.mSampleRate = file_format.mSampleRate;
  client_format.mFormatID = kAudioFormatLinearPCM;
  client_format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  client_format.mBitsPerChannel = 16;
  client_format.mChannelsPerFrame = file_format.mChannelsPerFrame;
  client_format.mFramesPerPacket = 1;
  client_format.mBytesPerFrame = client_format.mChannelsPerFrame * sizeof(int16_t);
  client_format.mBytesPerPacket = client_format.mBytesPerFrame;

  status = ExtAudioFileSetProperty(ext_file,
                                   kExtAudioFileProperty_ClientDataFormat,
                                   (UInt32)sizeof(client_format),
                                   &client_format);
  if (status != noErr) {
    ExtAudioFileDispose(ext_file);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 5;
    }
    return moonbit_make_bytes_raw(0);
  }

  const UInt32 frames_per_read = 4096;
  const size_t chunk_bytes = (size_t)frames_per_read * (size_t)client_format.mBytesPerFrame;
  uint8_t *chunk = (uint8_t *)malloc(chunk_bytes);
  if (chunk == NULL) {
    ExtAudioFileDispose(ext_file);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 6;
    }
    return moonbit_make_bytes_raw(0);
  }

  int16_t *pcm_all = NULL;
  size_t pcm_len = 0;
  size_t pcm_cap = 0;

  while (1) {
    UInt32 frames = frames_per_read;
    AudioBufferList buffers;
    buffers.mNumberBuffers = 1;
    buffers.mBuffers[0].mNumberChannels = client_format.mChannelsPerFrame;
    buffers.mBuffers[0].mData = chunk;
    buffers.mBuffers[0].mDataByteSize = (UInt32)chunk_bytes;

    status = ExtAudioFileRead(ext_file, &frames, &buffers);
    if (status != noErr) {
      free(chunk);
      free(pcm_all);
      ExtAudioFileDispose(ext_file);
      if (out_meta != NULL && out_meta_len >= 1) {
        out_meta[0] = 7;
      }
      return moonbit_make_bytes_raw(0);
    }

    if (frames == 0) {
      break;
    }

    size_t sample_count = (size_t)frames * (size_t)client_format.mChannelsPerFrame;
    if (moon_rodio_append_pcm_i16(&pcm_all,
                                  &pcm_len,
                                  &pcm_cap,
                                  (const int16_t *)chunk,
                                  sample_count) != 0) {
      free(chunk);
      free(pcm_all);
      ExtAudioFileDispose(ext_file);
      if (out_meta != NULL && out_meta_len >= 1) {
        out_meta[0] = 6;
      }
      return moonbit_make_bytes_raw(0);
    }
  }

  free(chunk);
  ExtAudioFileDispose(ext_file);

  if (pcm_len == 0) {
    free(pcm_all);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 8;
    }
    return moonbit_make_bytes_raw(0);
  }

  size_t out_bytes_len = pcm_len * sizeof(int16_t);
  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_bytes_len);
  if (out == NULL) {
    free(pcm_all);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 6;
    }
    return moonbit_make_bytes_raw(0);
  }

  memcpy(out, pcm_all, out_bytes_len);
  free(pcm_all);

  if (out_meta != NULL && out_meta_len >= 3) {
    out_meta[0] = 0;
    out_meta[1] = (uint32_t)client_format.mChannelsPerFrame;
    out_meta[2] = (uint32_t)(client_format.mSampleRate + 0.5);
  }

  return out;
#elif defined(MOON_RODIO_ENABLE_FFMPEG) && MOON_RODIO_ENABLE_FFMPEG
  int16_t *pcm_all = NULL;
  size_t pcm_sample_count = 0;
  int channels = 0;
  int sample_rate = 0;
  int status = moon_rodio_decode_mp4a_ffmpeg(
      input,
      input_len,
      &pcm_all,
      &pcm_sample_count,
      &channels,
      &sample_rate);
  if (status != 0) {
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = (uint32_t)status;
    }
    return moonbit_make_bytes_raw(0);
  }

  size_t out_bytes_len = pcm_sample_count * sizeof(int16_t);
  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_bytes_len);
  if (out == NULL) {
    free(pcm_all);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 106;
    }
    return moonbit_make_bytes_raw(0);
  }

  memcpy(out, pcm_all, out_bytes_len);
  free(pcm_all);

  if (out_meta != NULL && out_meta_len >= 3) {
    out_meta[0] = 0;
    out_meta[1] = (uint32_t)channels;
    out_meta[2] = (uint32_t)sample_rate;
  }

  return out;
#else
  (void)input;
  (void)input_len;
  if (out_meta != NULL && out_meta_len >= 1) {
    out_meta[0] = 100;
  }
  return moonbit_make_bytes_raw(0);
#endif
}
