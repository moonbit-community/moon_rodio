// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
fn ints_to_bytes(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length(), fn(i) { xs[i].to_byte() })
}

///|
fn push_u16_le(xs : Array[Int], v : Int) -> Unit {
  xs.push(v & 0xff)
  xs.push((v >> 8) & 0xff)
}

///|
fn push_u24_le(xs : Array[Int], v : Int) -> Unit {
  xs.push(v & 0xff)
  xs.push((v >> 8) & 0xff)
  xs.push((v >> 16) & 0xff)
}

///|
fn push_u32_le(xs : Array[Int], v : Int) -> Unit {
  xs.push(v & 0xff)
  xs.push((v >> 8) & 0xff)
  xs.push((v >> 16) & 0xff)
  xs.push((v >> 24) & 0xff)
}

///|
fn append_pcm_sample(
  xs : Array[Int],
  sample : Int,
  bits_per_sample : Int,
) -> Unit {
  match bits_per_sample {
    8 => xs.push(sample & 0xff)
    16 => {
      let u = if sample < 0 { sample + 0x10000 } else { sample }
      push_u16_le(xs, u)
    }
    24 => {
      let u = if sample < 0 { sample + 0x1000000 } else { sample }
      push_u24_le(xs, u)
    }
    32 => push_u32_le(xs, sample)
    _ => panic()
  }
}

///|
fn wav_mono_pcm(samples : Array[Int], bits_per_sample : Int) -> Bytes {
  let channels = 1
  let bytes_per_sample = bits_per_sample / 8
  let data_len = samples.length() * bytes_per_sample
  let riff_size = 36 + data_len
  let sr = 44_100
  let br = sr * channels * bytes_per_sample
  let block_align = channels * bytes_per_sample

  let xs : Array[Int] = [0x52, 0x49, 0x46, 0x46]
  push_u32_le(xs, riff_size)
  xs.push(0x57)
  xs.push(0x41)
  xs.push(0x56)
  xs.push(0x45)
  xs.push(0x66)
  xs.push(0x6d)
  xs.push(0x74)
  xs.push(0x20)
  push_u32_le(xs, 16)
  push_u16_le(xs, 1)
  push_u16_le(xs, channels)
  push_u32_le(xs, sr)
  push_u32_le(xs, br)
  push_u16_le(xs, block_align)
  push_u16_le(xs, bits_per_sample)
  xs.push(0x64)
  xs.push(0x61)
  xs.push(0x74)
  xs.push(0x61)
  push_u32_le(xs, data_len)

  for s in samples {
    append_pcm_sample(xs, s, bits_per_sample)
  }

  ints_to_bytes(xs)
}

///|
fn wav_mono_float32(float_bits : Array[Int]) -> Bytes {
  let channels = 1
  let bits_per_sample = 32
  let bytes_per_sample = 4
  let data_len = float_bits.length() * bytes_per_sample
  let riff_size = 36 + data_len
  let sr = 44_100
  let br = sr * channels * bytes_per_sample
  let block_align = channels * bytes_per_sample

  let xs : Array[Int] = [0x52, 0x49, 0x46, 0x46]
  push_u32_le(xs, riff_size)
  xs.push(0x57)
  xs.push(0x41)
  xs.push(0x56)
  xs.push(0x45)
  xs.push(0x66)
  xs.push(0x6d)
  xs.push(0x74)
  xs.push(0x20)
  push_u32_le(xs, 16)
  push_u16_le(xs, 3)
  push_u16_le(xs, channels)
  push_u32_le(xs, sr)
  push_u32_le(xs, br)
  push_u16_le(xs, block_align)
  push_u16_le(xs, bits_per_sample)
  xs.push(0x64)
  xs.push(0x61)
  xs.push(0x74)
  xs.push(0x61)
  push_u32_le(xs, data_len)

  for bits in float_bits {
    push_u32_le(xs, bits)
  }

  ints_to_bytes(xs)
}

///|
test "rodio::decoder::wav::decode_pcm16_mono" {
  let bytes = wav_mono_pcm([0, 32767, -32768], 16)
  let src = decode_wav_bytes(bytes)
  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 44_100)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.99)
  assert_eq(src.next(), Some(-1.0))
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::decode_pcm8_mono" {
  let bytes = wav_mono_pcm([0, 128, 255], 8)
  let src = decode_wav_bytes(bytes)
  assert_true(src.next().unwrap() <= -0.99)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.99)
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::decode_pcm24_mono" {
  let bytes = wav_mono_pcm([0, 8_388_607, -8_388_608], 24)
  let src = decode_wav_bytes(bytes)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.99)
  assert_eq(src.next(), Some(-1.0))
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::decode_pcm32_mono" {
  let bytes = wav_mono_pcm([0, 2_147_483_647, -2_147_483_648], 32)
  let src = decode_wav_bytes(bytes)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.99)
  assert_eq(src.next(), Some(-1.0))
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::decode_float32_mono" {
  let bytes = wav_mono_float32([0, 1_056_964_608, -1_082_130_432])
  let src = decode_wav_bytes(bytes)
  assert_eq(src.next(), Some(0.0))
  assert_eq(src.next(), Some(0.5))
  assert_eq(src.next(), Some(-1.0))
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::reject_unsupported_format" {
  let bytes = wav_mono_pcm([0, 1], 16)
  let ints : Array[Int] = []
  for i in 0..<bytes.length() {
    ints.push(bytes[i].to_int())
  }
  ints[20] = 0x02
  ints[21] = 0x00
  let unsupported = try {
    ignore(decode_wav_bytes(ints_to_bytes(ints)))
    false
  } catch {
    DecoderError::Unsupported(_) => true
    _ => false
  }
  assert_true(unsupported)
}

///|
test "rodio::decoder::mp3::decode_ill2_mono" {
  let bytes = mp3_ill2_mono_bytes()
  let src = decode_mp3_bytes(bytes)

  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 48_000)

  let mut sample_259 = 0.0
  let mut sample_500 = 0.0
  let mut sample_800 = 0.0
  let mut sample_1000 = 0.0
  let mut sample_count = 0
  let mut done = false
  while !done {
    match src.next() {
      Some(v) => {
        if sample_count == 259 {
          sample_259 = v
        }
        if sample_count == 500 {
          sample_500 = v
        }
        if sample_count == 800 {
          sample_800 = v
        }
        if sample_count == 1000 {
          sample_1000 = v
        }
        sample_count += 1
      }
      None => done = true
    }
  }

  assert_eq(sample_count, 1152)
  assert_true(sample_259 < 0.0 && sample_259 > -0.0001)
  assert_true(sample_500 > 0.012 && sample_500 < 0.013)
  assert_true(sample_800 > 0.51 && sample_800 < 0.53)
  assert_true(sample_1000 < -0.14 && sample_1000 > -0.15)
}

///|
test "rodio::decoder::mp3::reject_invalid_data" {
  let invalid = try {
    ignore(decode_mp3_bytes(b"test"))
    false
  } catch {
    DecoderError::InvalidFormat(_) => true
    _ => false
  }
  assert_true(invalid)
}

///|
test "rodio::decoder::flac::decode_pop" {
  let src = decode_flac_bytes(flac_pop_bytes())

  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 44_100)

  let mut sample_count = 0
  let mut s_1 = 0.0
  let mut s_20 = 0.0
  let mut s_60 = 0.0
  let mut s_99 = 0.0
  let mut done = false
  while !done {
    match src.next() {
      Some(v) => {
        if sample_count == 1 {
          s_1 = v
        }
        if sample_count == 20 {
          s_20 = v
        }
        if sample_count == 60 {
          s_60 = v
        }
        if sample_count == 99 {
          s_99 = v
        }
        sample_count += 1
      }
      None => done = true
    }
  }

  assert_eq(sample_count, 100)
  assert_true(s_1 > 0.062 && s_1 < 0.063)
  assert_true(s_20 > 0.95 && s_20 < 0.951)
  assert_true(s_60 < -0.58 && s_60 > -0.581)
  assert_true(s_99 < -0.076 && s_99 > -0.077)
}

///|
test "rodio::decoder::flac::reject_invalid_data" {
  let invalid = try {
    ignore(decode_flac_bytes(b"test"))
    false
  } catch {
    DecoderError::InvalidFormat(_) => true
    _ => false
  }
  assert_true(invalid)
}

///|
test "rodio::decoder::vorbis::decode_sine_48k_mono" {
  let src = decode_vorbis_bytes(vorbis_sine_48k_mono_bytes())

  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 48_000)

  let mut sample_count = 0
  let mut s_0 = 0.0
  let mut s_20 = 0.0
  let mut s_60 = 0.0
  let mut s_2000 = 0.0
  let mut s_2399 = 0.0
  let mut done = false
  while !done {
    match src.next() {
      Some(v) => {
        if sample_count == 0 {
          s_0 = v
        }
        if sample_count == 20 {
          s_20 = v
        }
        if sample_count == 60 {
          s_60 = v
        }
        if sample_count == 2000 {
          s_2000 = v
        }
        if sample_count == 2399 {
          s_2399 = v
        }
        sample_count += 1
      }
      None => done = true
    }
  }

  assert_eq(sample_count, 2400)
  assert_true(s_0 > 0.0018 && s_0 < 0.0019)
  assert_true(s_20 > 0.112 && s_20 < 0.113)
  assert_true(s_60 < -0.041 && s_60 > -0.043)
  assert_true(s_2000 > 0.109 && s_2000 < 0.11)
  assert_true(s_2399 < -0.01 && s_2399 > -0.011)
}

///|
test "rodio::decoder::vorbis::reject_invalid_data" {
  let invalid = try {
    ignore(decode_vorbis_bytes(b"test"))
    false
  } catch {
    DecoderError::InvalidFormat(_) => true
    _ => false
  }
  assert_true(invalid)
}
