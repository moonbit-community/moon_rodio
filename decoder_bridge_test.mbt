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
test "rodio::decoder_api::new_wav" {
  let d = Decoder::new(wav_mono([0, 32767, -32768], 16))
  assert_eq(d.channels(), 1)
  assert_eq(d.sample_rate(), 44_100)
  assert_eq(d.next(), Some(0.0))
  assert_true(d.next().unwrap() > 0.99)
  assert_eq(d.next(), Some(-1.0))
  assert_eq(d.next(), None)
}

///|
test "rodio::decoder_api::new_mp3" {
  let d = Decoder::new_mp3(@decoder.mp3_ill2_mono_bytes())
  assert_eq(d.channels(), 1)
  assert_eq(d.sample_rate(), 48_000)
}

///|
test "rodio::decoder_api::new_flac" {
  let d = Decoder::new_flac(@decoder.flac_pop_bytes())
  assert_eq(d.channels(), 1)
  assert_eq(d.sample_rate(), 44_100)
}

///|
test "rodio::decoder_api::new_vorbis" {
  let d = Decoder::new_vorbis(@decoder.vorbis_sine_48k_mono_bytes())
  assert_eq(d.channels(), 1)
  assert_eq(d.sample_rate(), 48_000)
}

///|
test "rodio::decoder_api::reject_unknown_format" {
  let bad = try {
    ignore(Decoder::new(b"abc"))
    false
  } catch {
    DecoderError::UnknownFormat => true
    _ => false
  }
  assert_true(bad)
}

///|
test "rodio::decoder_api::play" {
  let (tx, rx) = mixer(1, 44_100)
  let sink = play(tx, @decoder.flac_pop_bytes())

  assert_true(!sink.empty())
  assert_eq(rx.next(), Some(0.0))
  assert_true(rx.next().unwrap() > 0.06)
}
