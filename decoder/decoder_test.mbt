///|
fn ints_to_bytes(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length(), fn(i) { xs[i].to_byte() })
}

///|
fn wav_mono(samples : Array[Int], bits_per_sample : Int) -> Bytes {
  let channels = 1
  let bytes_per_sample = bits_per_sample / 8
  let data_len = samples.length() * 2
  let riff_size = 36 + data_len
  let sr = 44_100
  let br = sr * channels * bytes_per_sample
  let block_align = channels * bytes_per_sample

  let xs = [
    0x52,
    0x49,
    0x46,
    0x46,
    riff_size & 0xff,
    (riff_size >> 8) & 0xff,
    (riff_size >> 16) & 0xff,
    (riff_size >> 24) & 0xff,
    0x57,
    0x41,
    0x56,
    0x45,
    0x66,
    0x6d,
    0x74,
    0x20,
    16,
    0,
    0,
    0,
    1,
    0,
    channels,
    0,
    sr & 0xff,
    (sr >> 8) & 0xff,
    (sr >> 16) & 0xff,
    (sr >> 24) & 0xff,
    br & 0xff,
    (br >> 8) & 0xff,
    (br >> 16) & 0xff,
    (br >> 24) & 0xff,
    block_align,
    0,
    bits_per_sample,
    0,
    0x64,
    0x61,
    0x74,
    0x61,
    data_len & 0xff,
    (data_len >> 8) & 0xff,
    (data_len >> 16) & 0xff,
    (data_len >> 24) & 0xff,
  ]

  for s in samples {
    let u = if s < 0 { s + 0x10000 } else { s }
    xs.push(u & 0xff)
    xs.push((u >> 8) & 0xff)
  }

  ints_to_bytes(xs)
}

///|
test "rodio::decoder::wav::decode_pcm16_mono" {
  let bytes = wav_mono([0, 32767, -32768], 16)
  let src = decode_wav_bytes(bytes)
  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 44_100)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.99)
  assert_eq(src.next(), Some(-1.0))
  assert_eq(src.next(), None)
}

///|
test "rodio::decoder::wav::reject_non_pcm16" {
  let bytes = wav_mono([0, 1], 24)
  let unsupported = try {
    ignore(decode_wav_bytes(bytes))
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
