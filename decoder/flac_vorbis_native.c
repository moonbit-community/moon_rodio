#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

#define DR_FLAC_IMPLEMENTATION
#include "third_party/dr_libs/dr_flac.h"

#include "third_party/stb/stb_vorbis.c"

static void set_meta(uint32_t *out_meta,
                     int32_t out_meta_len,
                     uint32_t status,
                     uint32_t channels,
                     uint32_t sample_rate) {
  if (out_meta == NULL || out_meta_len <= 0) {
    return;
  }
  out_meta[0] = status;
  if (out_meta_len > 1) {
    out_meta[1] = channels;
  }
  if (out_meta_len > 2) {
    out_meta[2] = sample_rate;
  }
}

moonbit_bytes_t moon_rodio_flac_decode_all_i16le(uint8_t *input,
                                                  int32_t input_len,
                                                  uint32_t *out_meta,
                                                  int32_t out_meta_len) {
  // status:
  // 0 = ok
  // 1 = invalid input
  // 2 = decode failed
  // 3 = out of memory
  // 4 = output too large
  set_meta(out_meta, out_meta_len, 0, 0, 0);

  if (input == NULL || input_len <= 0) {
    set_meta(out_meta, out_meta_len, 1, 0, 0);
    return moonbit_make_bytes_raw(0);
  }

  unsigned int channels = 0;
  unsigned int sample_rate = 0;
  drflac_uint64 total_frames = 0;

  drflac_int16 *pcm = drflac_open_memory_and_read_pcm_frames_s16(input,
                                                                  (size_t)input_len,
                                                                  &channels,
                                                                  &sample_rate,
                                                                  &total_frames,
                                                                  NULL);
  if (pcm == NULL || channels == 0 || sample_rate == 0 || total_frames == 0) {
    if (pcm != NULL) {
      drflac_free(pcm, NULL);
    }
    set_meta(out_meta, out_meta_len, 2, 0, 0);
    return moonbit_make_bytes_raw(0);
  }

  uint64_t sample_count64 = ((uint64_t)total_frames) * ((uint64_t)channels);
  if (sample_count64 > ((uint64_t)INT32_MAX / 2u)) {
    drflac_free(pcm, NULL);
    set_meta(out_meta, out_meta_len, 4, channels, sample_rate);
    return moonbit_make_bytes_raw(0);
  }

  size_t out_len = (size_t)sample_count64 * sizeof(int16_t);
  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_len);
  if (out == NULL) {
    drflac_free(pcm, NULL);
    set_meta(out_meta, out_meta_len, 3, channels, sample_rate);
    return moonbit_make_bytes_raw(0);
  }

  memcpy(out, pcm, out_len);
  drflac_free(pcm, NULL);

  set_meta(out_meta, out_meta_len, 0, channels, sample_rate);
  return out;
}

moonbit_bytes_t moon_rodio_vorbis_decode_all_i16le(uint8_t *input,
                                                    int32_t input_len,
                                                    uint32_t *out_meta,
                                                    int32_t out_meta_len) {
  // status:
  // 0 = ok
  // 1 = invalid input
  // 2 = decode failed
  // 3 = out of memory
  // 4 = output too large
  set_meta(out_meta, out_meta_len, 0, 0, 0);

  if (input == NULL || input_len <= 0) {
    set_meta(out_meta, out_meta_len, 1, 0, 0);
    return moonbit_make_bytes_raw(0);
  }

  int channels = 0;
  int sample_rate = 0;
  short *pcm = NULL;
  int samples_per_channel = stb_vorbis_decode_memory(input,
                                                     input_len,
                                                     &channels,
                                                     &sample_rate,
                                                     &pcm);
  if (samples_per_channel <= 0 || channels <= 0 || sample_rate <= 0 || pcm == NULL) {
    if (pcm != NULL) {
      free(pcm);
    }
    set_meta(out_meta, out_meta_len, 2, 0, 0);
    return moonbit_make_bytes_raw(0);
  }

  uint64_t sample_count64 = ((uint64_t)(unsigned int)samples_per_channel) *
                            ((uint64_t)(unsigned int)channels);
  if (sample_count64 > ((uint64_t)INT32_MAX / 2u)) {
    free(pcm);
    set_meta(out_meta, out_meta_len, 4, (uint32_t)channels, (uint32_t)sample_rate);
    return moonbit_make_bytes_raw(0);
  }

  size_t out_len = (size_t)sample_count64 * sizeof(int16_t);
  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_len);
  if (out == NULL) {
    free(pcm);
    set_meta(out_meta, out_meta_len, 3, (uint32_t)channels, (uint32_t)sample_rate);
    return moonbit_make_bytes_raw(0);
  }

  memcpy(out, pcm, out_len);
  free(pcm);

  set_meta(out_meta, out_meta_len, 0, (uint32_t)channels, (uint32_t)sample_rate);
  return out;
}
