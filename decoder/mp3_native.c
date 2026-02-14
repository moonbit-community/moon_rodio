#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

#define MINIMP3_IMPLEMENTATION
#include "third_party/minimp3/minimp3.h"

static int append_pcm_i16(int16_t **buf,
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

moonbit_bytes_t moon_rodio_mp3_decode_all_i16le(uint8_t *input,
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
      out_meta[0] = 1; // invalid input
    }
    return moonbit_make_bytes_raw(0);
  }

  mp3dec_t dec;
  mp3dec_init(&dec);

  int pos = 0;
  int got_frame = 0;
  int channels = 0;
  int sample_rate = 0;

  int16_t *pcm_all = NULL;
  size_t pcm_len = 0;
  size_t pcm_cap = 0;

  while (pos < input_len) {
    mp3dec_frame_info_t info;
    int16_t frame_pcm[MINIMP3_MAX_SAMPLES_PER_FRAME];
    int samples = mp3dec_decode_frame(&dec, input + pos, input_len - pos, frame_pcm, &info);

    if (samples > 0 && info.channels > 0 && info.hz > 0) {
      size_t frame_count = (size_t)samples * (size_t)info.channels;
      if (append_pcm_i16(&pcm_all, &pcm_len, &pcm_cap, frame_pcm, frame_count) != 0) {
        free(pcm_all);
        if (out_meta != NULL && out_meta_len >= 1) {
          out_meta[0] = 3; // OOM
        }
        return moonbit_make_bytes_raw(0);
      }
      if (!got_frame) {
        channels = info.channels;
        sample_rate = info.hz;
      }
      got_frame = 1;
    }

    if (info.frame_bytes <= 0) {
      break;
    }
    pos += info.frame_bytes;
  }

  if (!got_frame || channels <= 0 || sample_rate <= 0 || pcm_len == 0) {
    free(pcm_all);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 2; // no decodable frame
    }
    return moonbit_make_bytes_raw(0);
  }

  size_t out_bytes_len = pcm_len * sizeof(int16_t);
  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_bytes_len);
  if (out == NULL) {
    free(pcm_all);
    if (out_meta != NULL && out_meta_len >= 1) {
      out_meta[0] = 3; // OOM
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
}
