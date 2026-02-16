#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

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

#if !defined(__APPLE__)
  (void)input;
  (void)input_len;
  if (out_meta != NULL && out_meta_len >= 1) {
    out_meta[0] = 100;
  }
  return moonbit_make_bytes_raw(0);
#else
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
#endif
}
