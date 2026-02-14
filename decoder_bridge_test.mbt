///|
fn ints_to_bytes(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length(), fn(i) { xs[i].to_byte() })
}

///|
fn wav_mono_with_rate(
  samples : Array[Int],
  bits_per_sample : Int,
  sample_rate : Int,
) -> Bytes {
  guard sample_rate > 0 else { panic() }
  let channels = 1
  let bytes_per_sample = bits_per_sample / 8
  let data_len = samples.length() * 2
  let riff_size = 36 + data_len
  let sr = sample_rate
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
fn wav_mono(samples : Array[Int], bits_per_sample : Int) -> Bytes {
  wav_mono_with_rate(samples, bits_per_sample, 44_100)
}

///|
fn wav_stereo_with_rate(
  samples : Array[(Int, Int)],
  bits_per_sample : Int,
  sample_rate : Int,
) -> Bytes {
  guard sample_rate > 0 else { panic() }
  let channels = 2
  let bytes_per_sample = bits_per_sample / 8
  let data_len = samples.length() * channels * bytes_per_sample
  let riff_size = 36 + data_len
  let sr = sample_rate
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

  for sample in samples {
    let channels = [sample.0, sample.1]
    for ch in channels {
      let u = if ch < 0 { ch + 0x10000 } else { ch }
      xs.push(u & 0xff)
      xs.push((u >> 8) & 0xff)
    }
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

///|
test "rodio::decoder_api::builder_build" {
  let decoder = Decoder::builder()
    .with_data(@decoder.mp3_ill2_mono_bytes())
    .with_hint("mp3")
    .with_gapless(true)
    .with_seekable(true)
    .build()

  assert_eq(decoder.channels(), 1)
  assert_eq(decoder.sample_rate(), 48_000)
}

///|
test "rodio::decoder_api::builder_mime_and_hint_fallbacks" {
  let from_mime = Decoder::builder()
    .with_data(@decoder.flac_pop_bytes())
    .with_mime_type("audio/flac")
    .build()
  assert_eq(from_mime.channels(), 1)
  assert_eq(from_mime.sample_rate(), 44_100)

  let bad_hint_fallback = Decoder::builder()
    .with_data(@decoder.flac_pop_bytes())
    .with_hint("mp3")
    .build()
  assert_eq(bad_hint_fallback.channels(), 1)
  assert_eq(bad_hint_fallback.sample_rate(), 44_100)
}

///|
test "rodio::decoder_api::builder_requires_data" {
  let failed = try {
    ignore(Decoder::builder().build())
    false
  } catch {
    DecoderError::UnknownFormat => true
    _ => false
  }
  assert_true(failed)
}

///|
test "rodio::decoder_api::looped_decoder_repeats" {
  let looped = Decoder::builder()
    .with_data(wav_mono([0, 32767], 16))
    .with_hint("wav")
    .build_looped()

  assert_eq(looped.channels(), 1)
  assert_eq(looped.sample_rate(), 44_100)
  assert_eq(looped.current_span_len(), Some(2))
  assert_eq(looped.total_duration(), None)
  assert_eq(looped.next(), Some(0.0))
  assert_true(looped.next().unwrap() > 0.99)
  assert_eq(looped.next(), Some(0.0))
  assert_true(looped.next().unwrap() > 0.99)
}

///|
test "rodio::decoder_api::builder_seekability_controls_try_seek" {
  let non_seekable = Decoder::builder()
    .with_data(wav_mono([0, 10_000, 20_000, 30_000], 16))
    .build()
  let err = try {
    non_seekable.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(err)

  let seekable = Decoder::builder()
    .with_data(wav_mono([0, 10_000, 20_000, 30_000], 16))
    .with_seekable(true)
    .build()
  seekable.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(seekable.next(), None)

  let disabled_again = Decoder::builder()
    .with_data(wav_mono([0, 10_000, 20_000, 30_000], 16))
    .with_byte_len(52)
    .with_seekable(false)
    .build()
  let err2 = try {
    disabled_again.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(err2)
}

///|
test "rodio::decoder_api::metadata_methods" {
  let d = Decoder::new(wav_mono([0, 32767], 16))
  assert_eq(d.current_span_len(), Some(2))
  let total = d.total_duration().unwrap()
  assert_eq(total.secs, (0 : UInt64))
  assert_eq(d.next(), Some(0.0))
  assert_eq(d.current_span_len(), Some(1))
}

///|
test "rodio::decoder_api::seek_beyond_end_saturates" {
  let d = Decoder::builder()
    .with_data(wav_mono([0, 10_000, 20_000, 30_000], 16))
    .with_seekable(true)
    .build()

  d.try_seek(@moon_cpal.Duration::from_secs((999 : UInt64)))
  assert_eq(d.next(), None)
  assert_eq(d.current_span_len(), Some(0))
}

///|
test "rodio::decoder_api::seek_possible_after_exhausting_source" {
  let d = Decoder::builder()
    .with_data(wav_mono([0, 12_000], 16))
    .with_seekable(true)
    .build()

  assert_eq(d.next(), Some(0.0))
  assert_true(d.next().unwrap() > 0.35)
  assert_eq(d.next(), None)

  d.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(d.next(), Some(0.0))
}

///|
test "rodio::decoder_api::seek_results_in_correct_remaining_playtime" {
  let d = Decoder::builder()
    .with_data(wav_mono_with_rate([0, 10_000, 20_000, 30_000], 16, 1))
    .with_seekable(true)
    .build()

  let total = d.total_duration().unwrap()
  assert_eq(total.secs, (4 : UInt64))
  d.try_seek(@moon_cpal.Duration::from_secs((3 : UInt64)))
  assert_eq(d.current_span_len(), Some(1))
  assert_true(d.next().unwrap() > 0.9)
  assert_eq(d.next(), None)
}

///|
test "rodio::decoder_api::total_duration_for_reference_formats" {
  let mp3_total = Decoder::new_mp3(@decoder.mp3_ill2_mono_bytes())
    .total_duration()
    .unwrap()
  assert_eq(mp3_total.secs, (0 : UInt64))
  assert_eq(mp3_total.nanos, 24_000_000)

  let flac_total = Decoder::new_flac(@decoder.flac_pop_bytes())
    .total_duration()
    .unwrap()
  assert_eq(flac_total.secs, (0 : UInt64))
  assert_eq(flac_total.nanos, 2_267_573)

  let vorbis_total = Decoder::new_vorbis(@decoder.vorbis_sine_48k_mono_bytes())
    .total_duration()
    .unwrap()
  assert_eq(vorbis_total.secs, (0 : UInt64))
  assert_eq(vorbis_total.nanos, 50_000_000)
}

///|
test "rodio::decoder_api::seek_resets_stereo_channel_alignment" {
  let stereo = wav_stereo_with_rate(
    [(0, 30_000), (0, 30_000), (0, 30_000), (0, 30_000)],
    16,
    10,
  )
  let d = Decoder::builder().with_data(stereo).with_seekable(true).build()
  assert_eq(d.channels(), 2)

  assert_eq(d.next(), Some(0.0))
  assert_true(d.next().unwrap() > 0.9)

  // Consume a single sample to force an odd sample index before seek.
  assert_eq(d.next(), Some(0.0))
  d.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(d.next(), Some(0.0))
  assert_true(d.next().unwrap() > 0.9)
}

///|
#cfg(target="native")
async test "rodio::decoder_api::try_from_file_variants" {
  let path = "rodio_decoder_try_from_file_test.wav"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  @fs.write_file(
    path,
    wav_mono([0, 12000, -12000], 16),
    create=0o644,
    truncate=true,
  )

  let d = Decoder::try_from_file(path)
  assert_eq(d.channels(), 1)
  assert_eq(d.sample_rate(), 44_100)
  assert_eq(d.next(), Some(0.0))

  let looped = Decoder::try_from_file_looped(path)
  assert_eq(looped.channels(), 1)
  assert_eq(looped.sample_rate(), 44_100)
  assert_eq(looped.next(), Some(0.0))
  assert_true(looped.next().unwrap() > 0.35)
  assert_true(looped.next().unwrap() < -0.35)
  assert_eq(looped.next(), Some(0.0))

  @fs.remove(path)
}
