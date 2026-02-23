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
fn read_file_bytes(path : String) -> Bytes {
  try @fs.read_file_to_bytes(path) catch {
    _ => panic()
  } noraise {
    bytes => bytes
  }
}

///|
fn write_file_bytes(path : String, bytes : Bytes) -> Unit {
  @fs.write_bytes_to_file(path, bytes) catch {
    _ => panic()
  }
}

///|
fn remove_file_if_exists(path : String) -> Unit {
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => panic()
    }
  }
}

///|
fn resolve_reference_asset_path(path : String) -> String {
  let mut prefix = ""
  for _ in 0..<64 {
    let full_path = prefix + "test_assets/rodio/" + path
    if @fs.path_exists(full_path) {
      return full_path
    }
    prefix = prefix + "../"
  }
  "test_assets/rodio/" + path
}

///|
fn read_reference_asset(path : String) -> Bytes {
  read_file_bytes(resolve_reference_asset_path(path))
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn count_decoder_samples(decoder : Decoder) -> Int {
  let mut total = 0
  while true {
    match decoder.next() {
      Some(_) => total += 1
      None => break
    }
  }
  total
}

///|
fn decode_all_samples(decoder : Decoder) -> Array[Sample] {
  let samples : Array[Sample] = []
  while true {
    match decoder.next() {
      Some(v) => samples.push(v)
      None => break
    }
  }
  samples
}

///|
fn[S : Source] collect_n_samples(source : S, n : Int) -> Array[Sample] {
  let samples : Array[Sample] = []
  for _ in 0..<n {
    match source.next() {
      Some(v) => samples.push(v)
      None => break
    }
  }
  samples
}

///|
fn duration_from_sample_count_test(
  total_samples : Int,
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> @moon_cpal.Duration {
  if total_samples <= 0 || channels <= 0 || sample_rate <= 0 {
    return @moon_cpal.Duration::from_secs((0 : UInt64))
  }
  let per_second = channels.to_uint64() * sample_rate.to_uint64()
  let total = total_samples.to_uint64()
  let secs = total / per_second
  let rem_samples = total % per_second
  let nanos = (rem_samples * (1_000_000_000 : UInt64) / per_second).to_int()
  @moon_cpal.Duration::new(secs, nanos)
}

///|
fn duration_to_nanos_test(duration : @moon_cpal.Duration) -> Int {
  duration.secs.to_int() * 1_000_000_000 + duration.nanos
}

///|
fn next_multiple_of(value : Int, n : Int) -> Int {
  if n <= 0 {
    value
  } else {
    let rem = value % n
    if rem == 0 {
      value
    } else {
      value + n - rem
    }
  }
}

///|
fn second_channel_beep_range(
  samples : Array[Sample],
  channels : Int,
) -> (Int, Int) {
  guard channels > 1 else { panic() }
  let window = 50
  let threshold = 0.1
  let basically_zero = 0.0001

  let mut beep_start = -1
  let mut chunk_start = 0
  while chunk_start + window <= samples.length() {
    let mut sum = 0.0
    let mut i = chunk_start + 1
    while i < chunk_start + window {
      sum += samples[i].abs()
      i += channels
    }
    if sum > threshold {
      beep_start = chunk_start
      break
    }
    chunk_start += window
  }
  guard beep_start >= 0 else { panic() }
  beep_start = next_multiple_of(beep_start, channels)

  let mut beep_end = -1
  chunk_start = beep_start / window * window
  while chunk_start + window <= samples.length() {
    let mut silent = true
    let mut i = chunk_start + 1
    while i < chunk_start + window {
      if samples[i].abs() >= basically_zero {
        silent = false
        break
      }
      i += channels
    }
    if silent {
      beep_end = chunk_start
      break
    }
    chunk_start += window
  }
  guard beep_end >= 0 else { panic() }
  (beep_start, next_multiple_of(beep_end, channels))
}

///|
fn channel_is_silent(
  samples : Array[Sample],
  channels : ChannelCount,
  channel : Int,
) -> Bool {
  guard samples.length() == 100 else { panic() }
  let mut sum = 0.0
  let mut i = channel
  while i < samples.length() {
    sum += samples[i].abs()
    i += channels
  }
  let volume = sum /
    Double::from_int(samples.length()) *
    Double::from_int(channels)
  volume < 0.0001
}

///|
fn assert_total_duration_matches_counted(path : String) -> Unit {
  let full_path = resolve_reference_asset_path(path)
  let d = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  let reported = d.total_duration().unwrap()
  let channels = d.channels()
  let sample_rate = d.sample_rate()

  let counted_source = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  let counted_samples = count_decoder_samples(counted_source)
  let counted = duration_from_sample_count_test(
    counted_samples, channels, sample_rate,
  )
  let diff = abs_int(
    duration_to_nanos_test(reported) - duration_to_nanos_test(counted),
  )
  // Keep a small tolerance for rounding and decoder backend differences.
  guard diff <= 50_000_000 else { panic() }
}

///|
fn assert_seek_remaining_playtime(path : String) -> Unit {
  let full_path = resolve_reference_asset_path(path)
  let base = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  let channels = base.channels()
  let sample_rate = base.sample_rate()
  let total_samples = count_decoder_samples(base)

  let target_remaining = channels * sample_rate * 5
  guard total_samples > target_remaining + channels else { panic() }

  let seek_target = total_samples - target_remaining
  let d = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  d.try_seek(
    duration_from_sample_count_test(seek_target, channels, sample_rate),
  ) catch {
    _ => panic()
  }
  let remaining = count_decoder_samples(d)
  let tolerance = channels * sample_rate / 4
  let diff = abs_int(remaining - target_remaining)
  guard diff <= tolerance else { panic() }
}

///|
fn assert_seek_keeps_channel_order(path : String) -> Unit {
  let full_path = resolve_reference_asset_path(path)
  let scan = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  let channels = scan.channels()
  guard channels == 2 else { panic() }
  let sample_rate = scan.sample_rate()
  let all_samples = decode_all_samples(scan)
  let (beep_start, _beep_end) = second_channel_beep_range(all_samples, channels)
  let mut channel_offset = 0

  let source = try Decoder::try_from_file(full_path) catch {
    _ => panic()
  } noraise {
    decoder => decoder
  }
  for offset in [1, 4, 7, 40, 41, 120, 179] {
    ignore(source.next())
    channel_offset = (channel_offset + 1) % 2

    let target = beep_start + offset * channels
    source.try_seek(
      duration_from_sample_count_test(target, channels, sample_rate),
    ) catch {
      _ => panic()
    }
    let samples = collect_n_samples(source, 100)
    let channel0 = channel_offset
    guard channel_is_silent(samples, channels, channel0) else { panic() }
    let channel1 = (channel_offset + 1) % 2
    guard !channel_is_silent(samples, channels, channel1) else { panic() }
  }
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
#cfg(target="native")
test "rodio::decoder_api::mp4a_native_decode_and_builder_paths" {
  let bytes = read_reference_asset("monkeys.mp4a")

  let decode_supported = try {
    let d = Decoder::new_mp4a(bytes)
    assert_true(d.channels() > 0)
    assert_true(d.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(d))
    true
  } catch {
    DecoderError::Backend(@decoder.DecoderError::Unsupported(_)) => false
    _ => false
  }

  if decode_supported {
    let aac = Decoder::new_aac(bytes)
    assert_true(aac.channels() > 0)
    assert_true(aac.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(aac))

    let mp4 = Decoder::new_mp4(bytes)
    assert_true(mp4.channels() > 0)
    assert_true(mp4.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(mp4))

    let hinted = Decoder::builder().with_data(bytes).with_hint("m4a").build()
    assert_true(hinted.channels() > 0)
    assert_true(hinted.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(hinted))

    let mime = Decoder::builder()
      .with_data(bytes)
      .with_mime_type("audio/mp4")
      .build()
    assert_true(mime.channels() > 0)
    assert_true(mime.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(mime))

    let auto = Decoder::new(bytes)
    assert_true(auto.channels() > 0)
    assert_true(auto.sample_rate() > 0)
    assert_true(decoder_has_non_zero_sample(auto))

    let seekable = Decoder::new_mp4a(bytes)
    let total = seekable.total_duration().unwrap()
    assert_true(total.secs > (0 : UInt64) || total.nanos > 0)
    seekable.try_seek(@moon_cpal.Duration::new((0 : UInt64), 0))
    assert_true(decoder_has_non_zero_sample(seekable))
  } else {
    let hinted_fails = try {
      ignore(Decoder::builder().with_data(bytes).with_hint("m4a").build())
      false
    } catch {
      DecoderError::UnrecognizedFormat => true
      DecoderError::Backend(@decoder.DecoderError::Unsupported(_)) => true
      _ => false
    }
    assert_true(hinted_fails)
  }
}

///|
test "rodio::decoder_api::reject_unknown_format" {
  let bad = try {
    ignore(Decoder::new(b"abc"))
    false
  } catch {
    DecoderError::UnrecognizedFormat => true
    _ => false
  }
  assert_true(bad)
}

///|
test "rodio::decoder_api::play" {
  let (tx, rx) = mixer(1, 44_100)
  let sink = play(tx, Reader::from_bytes(@decoder.flac_pop_bytes()))

  assert_true(!sink.empty())
  assert_eq(rx.next(), Some(0.0))
  assert_true(rx.next().unwrap() > 0.06)
}

///|
test "rodio::decoder_api::play_decode_error_variant" {
  let (tx, _rx) = mixer(1, 44_100)
  let got = try {
    ignore(play(tx, Reader::from_bytes(b"not audio")))
    false
  } catch {
    PlayError::DecoderError(DecoderError::UnrecognizedFormat) => true
    _ => false
  }
  assert_true(got)
}

///|
test "rodio::decoder_api::play_bytes_compat" {
  let (tx, rx) = mixer(1, 44_100)
  let player = play_bytes(tx, @decoder.flac_pop_bytes())

  assert_true(!player.empty())
  assert_eq(rx.next(), Some(0.0))
  assert_true(rx.next().unwrap() > 0.06)
}

///|
test "rodio::decoder_api::play_reader" {
  let (tx, rx) = mixer(1, 44_100)
  let reader = Reader::from_bytes(@decoder.flac_pop_bytes())
  let player = play_reader(tx, reader)

  assert_true(!player.empty())
  assert_eq(rx.next(), Some(0.0))
  assert_true(rx.next().unwrap() > 0.06)
}

///|
#cfg(target="native")
test "rodio::decoder_api::play_file" {
  let path = "_build/rodio_play_file_test.wav"
  remove_file_if_exists(path)
  write_file_bytes(path, wav_mono([0, 16000, -16000], 16))

  let (tx, rx) = mixer(1, 44_100)
  let player = play_file(tx, path)
  assert_true(!player.empty())
  assert_eq(rx.next(), Some(0.0))
  assert_true(rx.next().unwrap() > 0.45)

  remove_file_if_exists(path)
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
    DecoderError::UnrecognizedFormat => true
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
test "rodio::decoder_api::mp3_seek_without_byte_len_is_forward_only" {
  let bytes = @decoder.mp3_ill2_mono_bytes()

  let forward_only = Decoder::builder()
    .with_data(bytes)
    .with_hint("mp3")
    .with_seekable(true)
    .build()
  forward_only.try_seek(@moon_cpal.Duration::new((0 : UInt64), 20_000_000))
  let backward_blocked = try {
    forward_only.try_seek(@moon_cpal.Duration::new((0 : UInt64), 5_000_000))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(backward_blocked)

  let random_access = Decoder::builder()
    .with_data(bytes)
    .with_hint("mp3")
    .with_byte_len(bytes.length())
    .with_seekable(true)
    .build()
  random_access.try_seek(@moon_cpal.Duration::new((0 : UInt64), 20_000_000))
  random_access.try_seek(@moon_cpal.Duration::new((0 : UInt64), 5_000_000))
  assert_true(random_access.next() is Some(_))
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
test "rodio::decoder_api::seek_preserves_stereo_channel_offset" {
  let stereo = wav_stereo_with_rate(
    [(0, 30_000), (0, 30_000), (0, 30_000), (0, 30_000)],
    16,
    10,
  )
  let d = Decoder::builder().with_data(stereo).with_seekable(true).build()
  assert_eq(d.channels(), 2)

  assert_eq(d.next(), Some(0.0))
  assert_true(d.next().unwrap() > 0.9)

  // Consume a single sample to force an odd channel offset before seek.
  assert_eq(d.next(), Some(0.0))
  d.try_seek(@moon_cpal.Duration::new((0 : UInt64), 100_000_000))
  assert_true(d.next().unwrap() > 0.9)
  assert_eq(d.next(), Some(0.0))
}

///|
#cfg(target="native")
fn decoder_has_non_zero_sample(decoder : Decoder) -> Bool {
  let mut found = false
  let mut done = false
  while !done {
    match decoder.next() {
      Some(v) =>
        if v != 0.0 {
          found = true
          done = true
        }
      None => done = true
    }
  }
  found
}

///|
#cfg(target="native")
test "rodio::decoder_api::wav_encodings_reference_assets" {
  let files = [
    "audacity16bit.wav", "lmms16bit.wav", "lmms24bit.wav", "audacity32bit.wav", "lmms32bit.wav",
    "audacity32bit_int.wav",
  ]
  for path in files {
    let bytes = read_reference_asset(path)
    let decoder = Decoder::new_wav(bytes)
    assert_true(decoder_has_non_zero_sample(decoder))
  }
}

///|
#cfg(target="native")
test "rodio::decoder_api::flac_encodings_reference_assets" {
  let base = Decoder::new_flac(
    read_reference_asset("audacity16bit_level5.flac"),
  )
  assert_true(decoder_has_non_zero_sample(base))
  assert_eq(base.total_duration().unwrap().secs, (3 : UInt64))

  let files = [
    "audacity24bit_level0.flac", "audacity24bit_level5.flac", "audacity24bit_level8.flac",
  ]
  for path in files {
    let decoder = Decoder::new_flac(read_reference_asset(path))
    assert_true(decoder_has_non_zero_sample(decoder))
    assert_eq(decoder.total_duration().unwrap().secs, (3 : UInt64))
  }
}

///|
#cfg(target="native")
test "rodio::decoder_api::total_duration_reference_assets_matrix" {
  for path in ["music.wav", "music.flac", "music.mp3", "music.ogg"] {
    assert_total_duration_matches_counted(path)
  }
}

///|
#cfg(target="native")
test "rodio::decoder_api::seek_remaining_playtime_reference_assets" {
  for path in ["music.wav", "music.flac", "music.mp3", "music.ogg"] {
    assert_seek_remaining_playtime(path)
  }
}

///|
#cfg(target="native")
test "rodio::decoder_api::seek_channel_order_reference_assets" {
  for path in ["RL.wav", "RL.flac", "RL.mp3", "RL.ogg"] {
    assert_seek_keeps_channel_order(path)
  }
}

///|
#cfg(target="native")
test "rodio::decoder_api::try_from_file_variants" {
  let path = "rodio_decoder_try_from_file_test.wav"
  remove_file_if_exists(path)
  write_file_bytes(path, wav_mono([0, 12000, -12000], 16))

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

  remove_file_if_exists(path)
}
