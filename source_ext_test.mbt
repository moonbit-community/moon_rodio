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
fn[S : Source] collect_n(source : S, n : Int) -> Array[Sample] {
  let out : Array[Sample] = []
  for _ in 0..<n {
    match source.next() {
      None => break
      Some(v) => out.push(v)
    }
  }
  out
}

///|
fn mean_of(samples : Array[Sample]) -> Sample {
  if samples.is_empty() {
    return 0.0
  }
  let mut sum = 0.0
  for x in samples {
    sum += x
  }
  sum / Double::from_int(samples.length())
}

///|
fn consecutive_correlation(samples : Array[Sample]) -> Sample {
  if samples.length() < 2 {
    return 0.0
  }
  let mut sum = 0.0
  for i in 0..<(samples.length() - 1) {
    sum += samples[i] * samples[i + 1]
  }
  sum / Double::from_int(samples.length() - 1)
}

///|
struct TestNoiseRng {
  inner : LcgNoiseRng
}

///|
fn TestNoiseRng::new(seed : UInt64) -> TestNoiseRng {
  { inner: LcgNoiseRng::new(seed) }
}

///|
impl NoiseRng for TestNoiseRng with next_u64(self : TestNoiseRng) {
  self.inner.next_u64()
}

///|
struct ExternalSource {
  samples : Array[Sample]
  cursor : Ref[Int]
  channels : ChannelCount
  sample_rate : SampleRate
}

///|
fn ExternalSource::new(
  samples : Array[Sample],
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> ExternalSource {
  { samples, cursor: @ref.new(0), channels, sample_rate }
}

///|
impl Source for ExternalSource with next(self : ExternalSource) {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let value = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(value)
  }
}

///|
impl Source for ExternalSource with channels(self : ExternalSource) {
  self.channels
}

///|
impl Source for ExternalSource with sample_rate(self : ExternalSource) {
  self.sample_rate
}

///|
impl Source for ExternalSource with current_span_len(self : ExternalSource) {
  let remaining = self.samples.length() - self.cursor.val
  Some(if remaining < 0 { 0 } else { remaining })
}

///|
impl Source for ExternalSource with total_duration(_self : ExternalSource) {
  None
}

///|
impl Source for ExternalSource with try_seek(
  _self : ExternalSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  Empty::new(1, 1).try_seek(pos)
}

///|
fn skip_duration_samples_left(
  channels : ChannelCount,
  sample_rate : SampleRate,
  seconds : Int,
  seconds_to_skip : Int,
) -> Int {
  let len = channels * sample_rate * seconds
  let samples : Array[Sample] = []
  for _ in 0..<len {
    samples.push(0.0)
  }
  let src = SamplesBuffer::new(channels, sample_rate, samples)
  let skipped = skip_duration(
    src,
    @moon_cpal.Duration::from_secs(seconds_to_skip.to_uint64()),
  )
  collect_n(skipped, len + 4).length()
}

///|
test "rodio::source::open_trait_impl_and_is_exhausted" {
  let src = ExternalSource::new([1.0, 2.0], 1, 4)
  assert_true(!is_exhausted(src))
  assert_eq(src.next(), Some(1.0))
  assert_true(!is_exhausted(src))
  assert_eq(src.next(), Some(2.0))
  assert_true(is_exhausted(src))
  assert_eq(src.next(), None)
  assert_true(is_exhausted(src))
}

///|
test "rodio::source::record_and_record_source_alias" {
  let src = ExternalSource::new([1.0, -2.0, 3.0], 1, 8)
  let recorded = record(src)
  assert_eq(recorded.channels(), 1)
  assert_eq(recorded.sample_rate(), 8)
  assert_eq(collect_n(recorded, 8), [1.0, -2.0, 3.0])

  let src2 = ExternalSource::new([4.0, 5.0], 1, 16)
  let recorded2 = SamplesBuffer::record_source(src2)
  assert_eq(recorded2.channels(), 1)
  assert_eq(recorded2.sample_rate(), 16)
  assert_eq(collect_n(recorded2, 8), [4.0, 5.0])
}

///|
test "rodio::source::sine_wave" {
  let s = SineWave::new(440.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 48_000)
  assert_true(s.next().unwrap().abs() < 1.0e-12)
  let v1 = s.next().unwrap()
  assert_true(v1 > 0.05 && v1 < 0.06)
}

///|
test "rodio::source::square_wave" {
  let s = SquareWave::new(440.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 48_000)
  assert_eq(s.next(), Some(1.0))
}

///|
test "rodio::source::sawtooth_wave" {
  let s = SawtoothWave::new(440.0)
  assert_eq(s.next(), Some(0.0))
  assert_true(s.next().unwrap() > 0.0)
}

///|
test "rodio::source::triangle_wave" {
  let s = TriangleWave::new(440.0)
  assert_eq(s.next(), Some(-1.0))
  assert_true(s.next().unwrap() > -1.0)
}

///|
test "rodio::source::signal_generator_waveforms" {
  let square = SignalGenerator::from_function(2_000, 500.0, Function::square())
  assert_eq(square.next(), Some(1.0))
  assert_eq(square.next(), Some(1.0))
  assert_eq(square.next(), Some(-1.0))
  assert_eq(square.next(), Some(-1.0))

  let triangle = SignalGenerator::from_function(
    8_000,
    1_000.0,
    Function::triangle(),
  )
  assert_eq(triangle.next(), Some(-1.0))
  assert_eq(triangle.next(), Some(-0.5))
  assert_eq(triangle.next(), Some(0.0))
  assert_eq(triangle.next(), Some(0.5))
  assert_eq(triangle.next(), Some(1.0))
  assert_eq(triangle.next(), Some(0.5))

  let saw = SignalGenerator::from_function(200, 50.0, Function::sawtooth())
  assert_eq(saw.next(), Some(0.0))
  assert_eq(saw.next(), Some(0.5))
  assert_eq(saw.next(), Some(-1.0))
  assert_eq(saw.next(), Some(-0.5))

  let sine = SignalGenerator::from_function(1_000, 100.0, Function::sine())
  assert_eq(sine.next(), Some(0.0))
  assert_true(sine.next().unwrap() > 0.58)
  assert_true(sine.next().unwrap() > 0.94)
}

///|
test "rodio::source::empty_and_zero" {
  let e = empty(1, 44_100)
  assert_eq(e.next(), None)
  let e_total = e.total_duration().unwrap()
  assert_eq(e_total.secs, (0 : UInt64))
  assert_eq(e_total.nanos, 0)

  let z = zero(1, 44_100)
  z.try_seek(@moon_cpal.Duration::from_secs((123 : UInt64)))
  assert_eq(collect_n(z, 4), [0.0, 0.0, 0.0, 0.0])

  let zf = zero_samples(1, 44_100, 3)
  assert_eq(zf.current_span_len(), Some(3))
  zf.try_seek(@moon_cpal.Duration::from_secs((99 : UInt64)))
  assert_eq(collect_n(zf, 10), [0.0, 0.0, 0.0])
}

///|
test "rodio::source::metadata_and_seek_on_samples_buffer" {
  let src = SamplesBuffer::new(2, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])

  assert_eq(src.current_span_len(), Some(6))
  let total = src.total_duration().unwrap()
  assert_eq(total.secs, (0 : UInt64))
  assert_eq(total.nanos, 750_000_000)

  src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(src.current_span_len(), Some(0))
  assert_eq(src.next(), None)

  src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(src.current_span_len(), Some(6))
  assert_eq(src.next(), Some(1.0))
}

///|
test "rodio::source::duration_precision_and_subsecond_seek" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0])
  let total = src.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  assert_eq(total.nanos, 500_000_000)

  src.try_seek(@moon_cpal.Duration::new((0 : UInt64), 500_000_000))
  assert_eq(src.next(), Some(2.0))
}

///|
test "rodio::source::samples_buffer_seek_preserves_channel_order" {
  let src = SamplesBuffer::new(2, 100, [
    0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0,
  ])
  src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(src.next(), Some(0.0))
  assert_eq(src.next(), Some(1.0))
  // Consume one extra sample so current channel offset is odd.
  assert_eq(src.next(), Some(2.0))

  src.try_seek(@moon_cpal.Duration::new((0 : UInt64), 20_000_000))
  assert_eq(src.next(), Some(3.0))
}

///|
test "rodio::source::samples_buffer_seek_channel_order_reference_regression" {
  let samples : Array[Sample] = []
  for i in 0..<2_000 {
    samples.push(Double::from_int(i))
  }
  let src = SamplesBuffer::new(2, 100, samples)

  src.try_seek(@moon_cpal.Duration::from_secs((5 : UInt64)))
  assert_eq(src.next(), Some(1_000.0))
  assert_true(src.next().map(fn(v) { v.to_int() % 2 == 1 }).unwrap_or(false))
  assert_true(src.next().map(fn(v) { v.to_int() % 2 == 0 }).unwrap_or(false))

  src.try_seek(@moon_cpal.Duration::from_secs((6 : UInt64)))
  assert_true(src.next().map(fn(v) { v.to_int() % 2 == 1 }).unwrap_or(false))
}

///|
test "rodio::source::default_try_seek_not_supported" {
  let src = Empty::new(1, 44_100)
  let got_not_supported = try {
    src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(got_not_supported)
}

///|
test "rodio::source::signal_generator_seek" {
  let src = SineWave::new(100.0)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.01)
  src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(src.next(), Some(0.0))

  let saw = SawtoothWave::new(50.0)
  assert_eq(saw.next(), Some(0.0))
  saw.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(saw.next(), Some(0.0))
}

///|
test "rodio::source::to_dyn_preserves_seek_metadata" {
  let src = SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0])
  let dyn_src = to_dyn(src)
  assert_eq(dyn_src.current_span_len(), Some(4))
  dyn_src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(dyn_src.next(), None)
}

///|
test "rodio::source::named_wrapper_forwards_seek" {
  let amp = Amplify::new(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]), 1.0)
  assert_eq(amp.current_span_len(), Some(4))
  amp.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(amp.next(), None)
}

///|
test "rodio::source::amplify_take" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, -2.0, 3.0, -4.0])
  let amp = amplify(src, 0.5)
  let t = take(amp, 3)
  assert_eq(collect_n(t, 10), [0.5, -1.0, 1.5])
}

///|
test "rodio::source::mix" {
  let a = SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  let b = SamplesBuffer::new(1, 44_100, [4.0, 5.0])
  let m = mix(a, b)
  assert_eq(collect_n(m, 5), [5.0, 7.0, 3.0])
}

///|
test "rodio::source::mix_metadata" {
  let left = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0])
  let right = SamplesBuffer::new(1, 2, [10.0, 20.0])
  let mixed = mix(left, right)

  assert_eq(mixed.channels(), 1)
  assert_eq(mixed.sample_rate(), 2)
  assert_eq(mixed.current_span_len(), None)
  let total = mixed.total_duration().unwrap()
  assert_eq(total.secs, (2 : UInt64))
  assert_eq(total.nanos, 0)
  assert_eq(collect_n(mixed, 10), [11.0, 22.0, 3.0, 4.0])
}

///|
test "rodio::source::speed" {
  let a = SamplesBuffer::new(1, 44_100, [1.0, 2.0])
  let s = speed(a, 2.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 88_200)
  assert_eq(collect_n(s, 3), [1.0, 2.0])

  let s2 = speed(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    2.0,
  )
  let total = s2.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  s2.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(s2.next(), None)
}

///|
test "rodio::source::repeat_infinite" {
  let a = SamplesBuffer::new(1, 44_100, [2.0, -1.0])
  let r = a.repeat_infinite()
  assert_eq(collect_n(r, 6), [2.0, -1.0, 2.0, -1.0, 2.0, -1.0])
}

///|
test "rodio::source::repeat_infinite_seek_and_span" {
  let repeated = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]).repeat_infinite()
  assert_eq(repeated.current_span_len(), Some(4))
  let seek_err = try {
    repeated.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(seek_err)
  assert_eq(repeated.next(), Some(1.0))
}

///|
test "rodio::source::buffered_and_repeat_infinite_fn" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  let b = buffered(src)
  assert_eq(collect_n(b, 10), [1.0, 2.0, 3.0])

  let src2 = SamplesBuffer::new(1, 44_100, [2.0, -1.0])
  let r = repeat_infinite(src2)
  assert_eq(collect_n(r, 6), [2.0, -1.0, 2.0, -1.0, 2.0, -1.0])

  let src3 = SamplesBuffer::new(1, 44_100, [3.0])
  assert_eq(collect_n(repeat(src3), 4), [3.0, 3.0, 3.0, 3.0])
}

///|
test "rodio::source::duration_filters" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0, 5.0])
  let t = take_duration(src, @moon_cpal.Duration::from_secs((2 : UInt64)))
  assert_eq(collect_n(t, 10), [1.0, 2.0, 3.0, 4.0])

  let src2 = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0, 5.0])
  let sk = skip_duration(src2, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(sk, 10), [3.0, 4.0, 5.0])

  let src3 = SamplesBuffer::new(1, 2, [9.0, 8.0])
  let d = delay(src3, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(d, 6), [0.0, 0.0, 9.0, 8.0])
}

///|
test "rodio::source::skip_duration_length_cases" {
  assert_eq(skip_duration_samples_left(1, 44_100, 5, 3), 88_200)
  assert_eq(skip_duration_samples_left(2, 44_100, 5, 3), 176_400)
  assert_eq(skip_duration_samples_left(1, 44_100, 1, 5), 0)
  assert_eq(skip_duration_samples_left(2, 44_100, 1, 1), 0)
  assert_eq(skip_duration_samples_left(1, 96_000, 5, 0), 480_000)
}

///|
test "rodio::source::duration_filters_metadata_and_seek" {
  let td = take_duration(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    @moon_cpal.Duration::new((1 : UInt64), 500_000_000),
  )
  assert_eq(td.current_span_len(), Some(6))
  let td_total = td.total_duration().unwrap()
  assert_eq(td_total.secs, (1 : UInt64))
  assert_eq(td_total.nanos, 500_000_000)
  td.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(td.next(), Some(5.0))

  let dd = delay(
    SamplesBuffer::new(1, 2, [9.0, 8.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(dd.current_span_len(), Some(4))
  let dd_total = dd.total_duration().unwrap()
  assert_eq(dd_total.secs, (2 : UInt64))
  assert_eq(dd_total.nanos, 0)
  dd.try_seek(@moon_cpal.Duration::new((0 : UInt64), 500_000_000))
  assert_eq(dd.next(), Some(0.0))
  assert_eq(dd.next(), Some(9.0))
  dd.try_seek(@moon_cpal.Duration::new((1 : UInt64), 500_000_000))
  assert_eq(dd.next(), Some(8.0))

  let sd = skip_duration(
    SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  let sd_total = sd.total_duration().unwrap()
  assert_eq(sd_total.secs, (1 : UInt64))
  assert_eq(sd_total.nanos, 0)
}

///|
test "rodio::source::amplify_db_and_normalized" {
  let a = SamplesBuffer::new(1, 44_100, [1.0])
  let db = amplify_decibel(a, 6.0206)
  let dbv = db.next().unwrap()
  assert_true(dbv > 1.99 && dbv < 2.01)

  let b = SamplesBuffer::new(1, 44_100, [1.0])
  let n0 = amplify_normalized(b, 0.0)
  assert_eq(n0.next(), Some(0.0))

  let c = SamplesBuffer::new(1, 44_100, [1.0])
  let n1 = amplify_normalized(c, 1.0)
  assert_true(n1.next().unwrap() > 0.99)
}

///|
test "rodio::source::track_position" {
  let t = track_position(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0]))
  assert_eq(t.inner().channels(), 1)
  assert_eq(t.inner_mut().sample_rate(), 2)
  assert_eq(t.into_inner().channels(), 1)
  assert_eq(t.get_pos().secs, (0 : UInt64))
  ignore(t.next())
  ignore(t.next())
  assert_eq(t.get_pos().secs, (1 : UInt64))
  t.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(t.get_pos().secs, (1 : UInt64))
}

///|
test "rodio::source::track_position_subsecond" {
  let t = track_position(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0]))
  ignore(t.next())
  let pos = t.get_pos()
  assert_eq(pos.secs, (0 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
}

///|
test "rodio::source::track_position_in_presence_of_speedup" {
  let t = track_position(
    speed(
      SamplesBuffer::new(1, 1, [10.0, -10.0, 10.0, -10.0, 20.0, -20.0]),
      2.0,
    ),
  )
  assert_eq(t.get_pos().secs, (0 : UInt64))
  ignore(t.next())
  let pos = t.get_pos()
  assert_eq(pos.secs, (0 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
  ignore(t.next())
  assert_eq(t.get_pos().secs, (1 : UInt64))
  t.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(t.get_pos().secs, (1 : UInt64))
}

///|
test "rodio::source::track_position_across_spans" {
  let idx = @ref.new(0)
  let t = track_position(
    from_factory(fn() {
      let current = idx.val
      idx.val += 1
      if current == 0 {
        Some(SamplesBuffer::new(1, 1, [1.0, 2.0]))
      } else if current == 1 {
        Some(SamplesBuffer::new(1, 2, [3.0, 4.0]))
      } else {
        None
      }
    }),
  )
  ignore(t.next())
  ignore(t.next())
  ignore(t.next())
  assert_eq(t.sample_rate(), 2)
  let pos = t.get_pos()
  assert_eq(pos.secs, (2 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
}

///|
test "rodio::source::periodic_access" {
  let call_count = @ref.new(0)
  let p = periodic_access(
    SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0, 4.0, 5.0]),
    2,
    fn() { call_count.val += 1 },
  )
  assert_eq(p.inner().channels(), 1)
  assert_eq(p.inner_mut().sample_rate(), 44_100)
  assert_eq(p.into_inner().channels(), 1)
  assert_eq(collect_n(p, 10), [1.0, 2.0, 3.0, 4.0, 5.0])
  assert_eq(call_count.val, 3)
}

///|
test "rodio::source::periodic_alias" {
  let calls = @ref.new(0)
  let p = periodic(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    fn() { calls.val += 1 },
  )
  assert_eq(collect_n(p, 10), [1.0, 2.0, 3.0, 4.0])
  assert_eq(calls.val, 2)
}

///|
test "rodio::source::periodic_stereo_access" {
  let calls = @ref.new(0)
  let p = periodic(
    SamplesBuffer::new(2, 1, [10.0, -10.0, 10.0, -10.0, 20.0, -20.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    fn() { calls.val += 1 },
  )
  assert_eq(p.next(), Some(10.0))
  assert_eq(p.next(), Some(-10.0))
  assert_eq(p.next(), Some(10.0))
  assert_eq(p.next(), Some(-10.0))
  assert_eq(p.next(), Some(20.0))
  assert_eq(p.next(), Some(-20.0))
  assert_eq(calls.val, 3)
}

///|
test "rodio::source::periodic_fast_access_overflow" {
  let p = periodic(
    SamplesBuffer::new(1, 1, [10.0, -10.0, 10.0, -10.0, 20.0, -20.0]),
    @moon_cpal.Duration::new((0 : UInt64), 5_000_000),
    fn() { () },
  )
  ignore(p.next())
  ignore(p.next())
}

///|
test "rodio::source::periodic_access_with_source" {
  let p = periodic_access_with_source(
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0]),
    2,
    fn(src) {
      ignore(
        try {
          src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
          Ok(())
        } catch {
          _ => Err(())
        },
      )
    },
  )
  assert_eq(collect_n(p, 8), [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0])
}

///|
test "rodio::source::channel_volume" {
  let s = SamplesBuffer::new(2, 44_100, [2.0, 6.0, 4.0, 8.0])
  let out = channel_volume(s, [1.0, 0.5, 2.0])
  assert_eq(out.channels(), 3)
  assert_eq(collect_n(out, 10), [4.0, 2.0, 8.0, 6.0, 3.0, 12.0])
}

///|
test "rodio::source::linear_ramp_and_fades" {
  let s = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0])
  let ramp = linear_gain_ramp(
    s,
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  let rv = collect_n(ramp, 10)
  assert_eq(rv[0], 0.0)
  assert_true(rv[1] > 0.49 && rv[1] < 0.51)
  assert_eq(rv[2], 1.0)

  let s2 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0])
  let fin = fade_in(s2, @moon_cpal.Duration::from_secs((2 : UInt64)))
  let fv = collect_n(fin, 10)
  assert_eq(fv[0], 0.0)
  assert_true(fv[1] > 0.49 && fv[1] < 0.51)
  assert_eq(fv[2], 1.0)

  let s3 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0, 1.0])
  let fout = fade_out(s3, @moon_cpal.Duration::from_secs((2 : UInt64)))
  assert_eq(collect_n(fout, 10), [1.0, 0.5, 0.0, 0.0])

  let s4 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0, 1.0])
  let unclamped = linear_gain_ramp_with_clamp(
    s4,
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((2 : UInt64)),
    false,
  )
  assert_eq(collect_n(unclamped, 10), [0.0, 0.5, 1.0, 1.0])

  let s5 = SamplesBuffer::new(1, 1, [1.0, 1.0])
  assert_eq(
    collect_n(fadein(s5, @moon_cpal.Duration::from_secs((1 : UInt64))), 10),
    [0.0, 1.0],
  )

  let s6 = SamplesBuffer::new(1, 1, [1.0, 1.0])
  assert_eq(
    collect_n(fadeout(s6, @moon_cpal.Duration::from_secs((1 : UInt64))), 10),
    [1.0, 0.0],
  )

  let seek_ramp = linear_gain_ramp(
    SamplesBuffer::new(1, 1, [
      0.0, 0.4, 0.8, 0.0, 0.4, 0.8, 0.0, 0.4, 0.8, 0.0, 0.4, 0.8,
    ]),
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((10 : UInt64)),
  )
  assert_eq(seek_ramp.next(), Some(0.0))
  let a1 = seek_ramp.next().unwrap()
  let a2 = seek_ramp.next().unwrap()
  assert_true(a1 > 0.039 && a1 < 0.041)
  assert_true(a2 > 0.159 && a2 < 0.161)

  seek_ramp.try_seek(@moon_cpal.Duration::from_secs((5 : UInt64)))
  let b0 = seek_ramp.next().unwrap()
  assert_true(b0 > 0.39 && b0 < 0.41)
  assert_eq(seek_ramp.next(), Some(0.0))
  let b2 = seek_ramp.next().unwrap()
  assert_true(b2 > 0.27 && b2 < 0.29)

  seek_ramp.try_seek(@moon_cpal.Duration::from_secs((10 : UInt64)))
  let c0 = seek_ramp.next().unwrap()
  assert_true(c0 > 0.39 && c0 < 0.41)

  let named_unclamped = LinearGainRamp::new_with_clamp(
    SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0, 1.0]),
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((2 : UInt64)),
    false,
  )
  assert_eq(collect_n(named_unclamped, 10), [0.0, 0.5, 1.0, 1.0])
}

///|
test "rodio::source::limit_and_distortion" {
  let a = SamplesBuffer::new(1, 44_100, [-2.0, -0.5, 0.2, 3.0])
  let l = limit(
    a,
    LimitSettings::new()
    .with_min(-1.0)
    .with_max(1.0)
    .with_knee_width(0.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let lv = collect_n(l, 10)
  assert_true((lv[0] + 1.0).abs() < 1.0e-9)
  assert_eq(lv[1], -0.5)
  assert_eq(lv[2], 0.2)
  assert_true((lv[3] - 1.0).abs() < 1.0e-9)

  let b = SamplesBuffer::new(1, 44_100, [-2.0, -0.5, 0.2, 3.0])
  let d = distortion(b, 1.0, 0.4)
  assert_eq(collect_n(d, 10), [-0.4, -0.4, 0.2, 0.4])

  let c = SamplesBuffer::new(1, 44_100, [0.25, 0.6, -0.8])
  assert_eq(collect_n(distortion_threshold(c, 10.0), 10), [0.25, 0.6, -0.8])
}

///|
test "rodio::source::limit_passthrough_below_threshold" {
  let dry = take_duration(
    amplify(SineWave::new(1_000.0), 0.2),
    @moon_cpal.Duration::new((0 : UInt64), 20_000_000),
  )
  let limited = Limit::new(
    take_duration(
      amplify(SineWave::new(1_000.0), 0.2),
      @moon_cpal.Duration::new((0 : UInt64), 20_000_000),
    ),
    LimitSettings::default().with_threshold(-6.0),
  )

  let original_samples = collect_n(dry, 1_200)
  let limited_samples = collect_n(limited, 1_200)
  assert_eq(original_samples.length(), limited_samples.length())
  for i in 0..<original_samples.length() {
    let diff = (original_samples[i] - limited_samples[i]).abs()
    assert_true(diff < 0.01)
  }
}

///|
test "rodio::source::limit_stereo_processing" {
  let stereo_samples : Array[Sample] = []
  for i in 0..<1_000 {
    let wave = @math.sin(Double::from_int(i) * 0.01)
    stereo_samples.push(wave * 1.5)
    stereo_samples.push(wave * 0.8)
  }

  let limited = Limit::new(
    SamplesBuffer::new(2, 44_100, stereo_samples),
    LimitSettings::default().with_threshold(-3.0),
  )
  let out = collect_n(limited, 5_000)

  let left_peak = @ref.new(0.0)
  let right_peak = @ref.new(0.0)
  for i in 0..<out.length() {
    let peak = out[i].abs()
    if i % 2 == 0 {
      if peak > left_peak.val {
        left_peak.val = peak
      }
    } else if peak > right_peak.val {
      right_peak.val = peak
    }
  }

  assert_true(left_peak.val <= 1.5)
  assert_true(right_peak.val <= 1.5)
  assert_true(left_peak.val >= right_peak.val)
}

///|
test "rodio::source::limit_specialized_wrappers_match_base_limit" {
  let settings = LimitSettings::default().with_threshold(-3.0)

  let mono_samples = [1.5, -1.2, 0.6, -0.8, 0.2]
  let mono_base = collect_n(
    Limit::new(SamplesBuffer::new(1, 44_100, mono_samples), settings),
    16,
  )
  let mono_wrapped = collect_n(
    LimitMono::new(SamplesBuffer::new(1, 44_100, mono_samples), settings),
    16,
  )
  assert_eq(mono_base, mono_wrapped)

  let stereo_samples : Array[Sample] = []
  for i in 0..<20 {
    let x = @math.sin(Double::from_int(i) * 0.2)
    stereo_samples.push(x * 1.4)
    stereo_samples.push(-x * 1.1)
  }
  let stereo_base = collect_n(
    Limit::new(SamplesBuffer::new(2, 44_100, stereo_samples), settings),
    200,
  )
  let stereo_wrapped = collect_n(
    LimitStereo::new(SamplesBuffer::new(2, 44_100, stereo_samples), settings),
    200,
  )
  assert_eq(stereo_base, stereo_wrapped)

  let multi_samples : Array[Sample] = []
  for i in 0..<20 {
    let x = @math.sin(Double::from_int(i) * 0.15)
    multi_samples.push(x * 1.3)
    multi_samples.push(x * -0.7)
    multi_samples.push(x * 0.4)
  }
  let multi_base = collect_n(
    Limit::new(SamplesBuffer::new(3, 44_100, multi_samples), settings),
    300,
  )
  let multi_wrapped = collect_n(
    LimitMulti::new(SamplesBuffer::new(3, 44_100, multi_samples), settings),
    300,
  )
  assert_eq(multi_base, multi_wrapped)

  let mono_view = LimitMono::new(SamplesBuffer::new(1, 44_100, [0.0]), settings)
  assert_eq(mono_view.inner().channels(), 1)
  assert_eq(mono_view.inner_mut().sample_rate(), 44_100)
  assert_eq(mono_view.into_inner().channels(), 1)
}

///|
test "rodio::source::crossfade" {
  let a = SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
  let b = zero(1, 1)
  let x = crossfade(a, b, @moon_cpal.Duration::new((5 : UInt64), 1))
  let v = collect_n(x, 10)
  assert_eq(v.length(), 5)
  assert_eq(v[0], 1.0)
  assert_true(v[1] > 1.59 && v[1] < 1.61)
  assert_true(v[2] > 1.79 && v[2] < 1.81)
  assert_true(v[3] > 1.59 && v[3] < 1.61)
  assert_true(v[4] > 0.99 && v[4] < 1.01)

  let y = take_crossfade_with(
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
    zero(1, 1),
    @moon_cpal.Duration::new((5 : UInt64), 1),
  )
  assert_eq(collect_n(y, 10).length(), 5)

  let self_mix = crossfade(
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
    @moon_cpal.Duration::new((5 : UInt64), 1),
  )
  let self_mix_out = collect_n(self_mix, 10)
  assert_eq(self_mix_out.length(), 5)
  assert_true(self_mix_out[0] > 0.999999 && self_mix_out[0] < 1.000001)
  assert_true(self_mix_out[1] > 1.999999 && self_mix_out[1] < 2.000001)
  assert_true(self_mix_out[2] > 2.999999 && self_mix_out[2] < 3.000001)
  assert_true(self_mix_out[3] > 3.999999 && self_mix_out[3] < 4.000001)
  assert_true(self_mix_out[4] > 4.999999 && self_mix_out[4] < 5.000001)
}

///|
test "rodio::source::chirp" {
  let c = chirp(10, 10.0, 20.0, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(c.channels(), 1)
  assert_eq(c.sample_rate(), 10)
  let out = collect_n(c, 20)
  assert_eq(out.length(), 10)
}

///|
test "rodio::source::from_factory" {
  let idx = @ref.new(0)
  let src = from_factory(fn() {
    let current = idx.val
    idx.val += 1
    if current == 0 {
      Some(SamplesBuffer::new(1, 44_100, [1.0, 2.0]))
    } else if current == 1 {
      Some(SamplesBuffer::new(1, 44_100, [3.0]))
    } else {
      None
    }
  })

  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 44_100)
  assert_eq(src.current_span_len(), Some(2))
  assert_eq(collect_n(src, 10), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::from_factory_metadata_and_seek" {
  let idx = @ref.new(0)
  let src = from_factory(fn() {
    let current = idx.val
    idx.val += 1
    if current == 0 {
      Some(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]))
    } else if current == 1 {
      Some(SamplesBuffer::new(1, 2, [5.0]))
    } else {
      None
    }
  })

  assert_eq(src.current_span_len(), Some(4))
  src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(src.next(), Some(3.0))
  assert_eq(collect_n(src, 10), [4.0, 5.0])
}

///|
test "rodio::source::done" {
  let signal = @ref.new(2)
  let d = Done::new(SamplesBuffer::new(1, 44_100, [1.0]), signal)
  assert_eq(d.inner().channels(), 1)
  assert_eq(d.inner_mut().sample_rate(), 44_100)
  assert_eq(d.into_inner().channels(), 1)
  assert_eq(d.next(), Some(1.0))
  assert_eq(signal.val, 2)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
}

///|
test "rodio::source::done_metadata_and_seek_forwarding" {
  let d = Done::new(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]), @ref.new(1))
  assert_eq(d.current_span_len(), Some(4))
  let total = d.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  d.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(d.next(), None)
}

///|
test "rodio::source::empty_callback" {
  let calls = @ref.new(0)
  let e = EmptyCallback::new(fn() { calls.val += 1 })
  assert_eq(e.next(), None)
  assert_eq(e.next(), None)
  assert_eq(calls.val, 2)
  let total = e.total_duration().unwrap()
  assert_eq(total.secs, (0 : UInt64))
  assert_eq(total.nanos, 0)
}

///|
test "rodio::source::uniform_source_iterator" {
  let s = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let u = UniformSourceIterator::new(s, 2, 4)
  assert_eq(u.inner_mut().channels(), 2)
  assert_eq(u.channels(), 2)
  assert_eq(u.sample_rate(), 4)
  assert_eq(u.current_span_len(), None)
  let total = u.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  let vals = collect_n(u, 10)
  assert_eq(vals[0], 0.0)
  assert_eq(vals[1], 0.0)
  assert_true(vals[2] > 0.99 && vals[2] < 1.01)
}

///|
test "rodio::source::from_iter_sources" {
  let a = to_dyn(SamplesBuffer::new(1, 44_100, [1.0, 2.0]))
  let b = to_dyn(SamplesBuffer::new(1, 44_100, [3.0]))
  let it = from_iter([a, b])
  assert_eq(it.channels(), 1)
  assert_eq(it.sample_rate(), 44_100)
  assert_eq(collect_n(it, 10), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::from_iter_generic_sources" {
  let it = from_iter([
    SamplesBuffer::new(1, 44_100, [0.25, 0.5]),
    SamplesBuffer::new(1, 44_100, [0.75]),
  ])
  assert_eq(it.channels(), 1)
  assert_eq(it.sample_rate(), 44_100)
  assert_eq(collect_n(it, 10), [0.25, 0.5, 0.75])
}

///|
test "rodio::source::from_iter_metadata_and_seek" {
  let it = from_iter([SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0])])
  assert_eq(it.current_span_len(), Some(4))
  it.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(it.next(), None)
}

///|
test "rodio::queue::current_span_len_behavior" {
  let (tx, rx) = queue(true)
  assert_eq(rx.current_span_len(), Some(512))

  tx.append(SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0]))
  let span = rx.current_span_len().unwrap()
  assert_true(span > 0)
  assert_eq(span, 3)
}

///|
test "rodio::source::function_chain" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0])
  let out = take_duration(
    delay(amplify(src, 2.0), @moon_cpal.Duration::from_secs((1 : UInt64))),
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  assert_eq(collect_n(out, 10), [0.0, 0.0, 2.0, 4.0])
}

///|
test "rodio::source::named_wrappers_basic" {
  let a = Amplify::new(SamplesBuffer::new(1, 1, [1.0, 2.0]), 0.5)
  assert_eq(a.inner().channels(), 1)
  a.set_factor(2.0)
  assert_eq(a.next(), Some(2.0))
  a.set_log_factor(6.0206)
  let next_amp = a.next().unwrap()
  assert_true(next_amp > 3.98 && next_amp < 4.02)
  assert_eq(a.next(), None)

  let a2 = Amplify::new(SamplesBuffer::new(1, 1, [1.0, 2.0]), 0.5)
  assert_eq(collect_n(a2, 10), [0.5, 1.0])

  let z = Zero::new(1, 44_100)
  assert_eq(z.inner_mut().sample_rate(), 44_100)
  assert_eq(collect_n(z, 3), [0.0, 0.0, 0.0])
  let zf = Zero::new_samples(1, 44_100, 2)
  assert_eq(collect_n(zf, 10), [0.0, 0.0])

  let l = Limit::new(
    SamplesBuffer::new(1, 1, [-2.0, 0.5, 3.0]),
    LimitSettings::default(),
  )
  let lv0 = collect_n(l, 10)
  assert_true(lv0[0] > -0.95 && lv0[0] < -0.85)
  assert_true(lv0[1] > 0.49 && lv0[1] <= 0.5)
  assert_true(lv0[2] > 0.85 && lv0[2] < 0.95)

  let set = LimitSettings::new().with_threshold(-6.0)
  let l2 = Limit::new(SamplesBuffer::new(1, 1, [-1.0, -0.5, 0.5, 1.0]), set)
  let lv = collect_n(l2, 10)
  assert_true(lv[0] <= -0.49 && lv[0] >= -0.51)
  assert_true(lv[3] >= 0.49 && lv[3] <= 0.51)

  let hard = Limit::new(
    SamplesBuffer::new(1, 1_000, [0.9]),
    LimitSettings::new()
    .with_threshold(-1.0)
    .with_knee_width(0.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let soft = Limit::new(
    SamplesBuffer::new(1, 1_000, [0.9]),
    LimitSettings::new()
    .with_threshold(-1.0)
    .with_knee_width(8.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let hard_v = collect_n(hard, 10)
  let soft_v = collect_n(soft, 10)
  assert_true(hard_v[0] > soft_v[0])

  let fast_attack = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let slow_attack = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::new((1 : UInt64), 0))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let fast_attack_v = collect_n(fast_attack, 10)
  let slow_attack_v = collect_n(slow_attack, 10)
  assert_true(slow_attack_v[0] > fast_attack_v[0])

  let fast_release = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0, 0.2]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let slow_release = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0, 0.2]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::new((2 : UInt64), 0)),
  )
  let fast_release_v = collect_n(fast_release, 10)
  let slow_release_v = collect_n(slow_release, 10)
  assert_true(slow_release_v[1] < fast_release_v[1])

  ignore(LimitSettings::dynamic_content())
  ignore(LimitSettings::broadcast())
  ignore(LimitSettings::mastering())
  ignore(LimitSettings::gaming())
  ignore(LimitSettings::live_performance())

  let dg = Distortion::with_gain(
    SamplesBuffer::new(1, 1, [0.5, -0.75]),
    2.0,
    0.8,
  )
  dg.set_threshold(0.7)
  dg.set_gain(1.0)
  assert_eq(collect_n(dg, 10), [0.5, -0.7])

  let cv = ChannelVolume::new(
    SamplesBuffer::new(2, 44_100, [2.0, 6.0, 4.0, 8.0]),
    [1.0, 1.0, 1.0],
  )
  cv.set_volume(1, 0.5)
  cv.set_volume(2, 2.0)
  assert_eq(cv.channels(), 3)
  assert_eq(collect_n(cv, 10), [4.0, 2.0, 8.0, 6.0, 3.0, 12.0])

  let sp = Speed::new(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    2.0,
  )
  assert_eq(sp.sample_rate(), 8)
  let total_sp = sp.total_duration().unwrap()
  assert_eq(total_sp.secs, (1 : UInt64))
  sp.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(sp.next(), None)
  sp.set_factor(0.5)
  assert_eq(sp.sample_rate(), 2)
}

///|
test "rodio::source::named_wrappers_signal_and_spatial" {
  let g = SignalGenerator::from_function(48_000, 440.0, Function::sine())
  assert_eq(g.channels(), 1)
  let g2 = SignalGenerator::with_function(48_000, 440.0, Function::triangle())
  assert_eq(g2.sample_rate(), 48_000)

  let custom = SignalGenerator::with_generator(
    48_000,
    440.0,
    GeneratorFunction::new(fn(_phase) { 0.25 }),
  )
  assert_eq(custom.next(), Some(0.25))

  let s = Spatial::new(
    SamplesBuffer::new(1, 44_100, [1.0, 1.0]),
    [0.0, 0.0, 0.0],
    [-1.0, 0.0, 0.0],
    [1.0, 0.0, 0.0],
  )
  assert_eq(s.inner().sample_rate(), 44_100)
  assert_eq(s.inner_mut().channels(), 2)
  assert_eq(s.into_inner().sample_rate(), 44_100)
  assert_eq(s.channels(), 2)
  assert_eq(s.sample_rate(), 44_100)
}

///|
test "rodio::source::named_wrappers_inner_accessors" {
  let buf = Buffered::new(SamplesBuffer::new(1, 1, [1.0, 2.0]))
  assert_eq(buf.inner().channels(), 1)
  let buf_seek_err = try {
    buf.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(buf_seek_err)

  let d = Delay::new(
    SamplesBuffer::new(1, 1, [1.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(d.inner().channels(), 1)
  assert_eq(d.inner_mut().sample_rate(), 1)
  assert_eq(d.into_inner().channels(), 1)

  let r = Repeat::new(SamplesBuffer::new(1, 1, [1.0]))
  assert_eq(r.inner().channels(), 1)
  assert_eq(r.inner_mut().sample_rate(), 1)
  assert_eq(r.into_inner().channels(), 1)

  let td = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 2.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  td.set_filter_fadeout()
  td.clear_filter()
  assert_eq(td.inner().channels(), 1)
  assert_eq(td.inner_mut().sample_rate(), 1)
  assert_eq(td.into_inner().channels(), 1)

  let m = Mix::new(
    SamplesBuffer::new(1, 1, [1.0]),
    SamplesBuffer::new(1, 1, [2.0]),
  )
  assert_eq(m.inner().channels(), 1)
  assert_eq(m.inner_mut().sample_rate(), 1)
  assert_eq(m.into_inner().channels(), 1)

  let c = Crossfade::new(
    SamplesBuffer::new(1, 1, [1.0]),
    SamplesBuffer::new(1, 1, [2.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(c.inner().channels(), 1)
  assert_eq(c.inner_mut().sample_rate(), 1)
  assert_eq(c.into_inner().channels(), 1)
}

///|
test "rodio::source::named_takeduration_filter_and_seek" {
  let td = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0]),
    @moon_cpal.Duration::from_secs((3 : UInt64)),
  )
  td.set_filter_fadeout()
  let vals = collect_n(td, 10)
  assert_eq(vals.length(), 3)
  assert_eq(vals[0], 1.0)
  assert_true(vals[1] > 0.66 && vals[1] < 0.67)
  assert_true(vals[2] > 0.33 && vals[2] < 0.34)

  let td2 = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0]),
    @moon_cpal.Duration::from_secs((3 : UInt64)),
  )
  td2.set_filter_fadeout()
  td2.clear_filter()
  assert_eq(collect_n(td2, 10), [1.0, 1.0, 1.0])

  let td3 = TakeDuration::new(
    SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  td3.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(td3, 10), [3.0, 4.0])
}

///|
test "rodio::source::agc" {
  let src = SamplesBuffer::new(1, 10, [0.1, 0.1, 0.1, 0.1])
  let settings = AutomaticGainControlSettings::new()
    .with_target_level(1.0)
    .with_attack(@moon_cpal.Duration::from_secs((1 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((1 : UInt64)))
    .with_absolute_max_gain(10.0)
  let agc = AutomaticGainControl::new(src, settings)
  let v = collect_n(agc, 4)
  assert_true(v[0] > 0.1)
  assert_true(v[3] > v[0])
}

///|
test "rodio::source::agc_controls" {
  let src = SamplesBuffer::new(1, 10, [0.1, 0.1, 0.1, 0.1])
  let settings = AutomaticGainControlSettings::new()
    .with_target_level(1.0)
    .with_attack(@moon_cpal.Duration::from_secs((1 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((1 : UInt64)))
    .with_absolute_max_gain(10.0)
  let agc = automatic_gain_control(src, settings)
  let ctrl = agc.get_agc_control()
  assert_true(ctrl.val)
  agc.set_enabled(false)
  assert_true(!ctrl.val)
  assert_eq(agc.next(), Some(0.1))
  agc.set_enabled(true)
  assert_true(agc.next().unwrap() > 0.1)
  assert_true(agc.get_target_level().val > 0.9)
  assert_true(agc.get_absolute_max_gain().val > 9.9)
  assert_eq(agc.inner().channels(), 1)
  assert_eq(agc.inner_mut().sample_rate(), 10)
}

///|
test "rodio::source::agc_settings_and_floor" {
  let defaults = AutomaticGainControlSettings::default()
  assert_eq(defaults.target_level, 1.0)
  assert_eq(defaults.attack_time.secs, (4 : UInt64))
  assert_eq(defaults.attack_time.nanos, 0)
  assert_eq(defaults.release_time.secs, (0 : UInt64))
  assert_eq(defaults.release_time.nanos, 0)
  assert_eq(defaults.absolute_max_gain, 7.0)

  let settings = AutomaticGainControlSettings::new()
    .with_target_level(0.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_absolute_max_gain(2.0)
  let agc = automatic_gain_control(
    SamplesBuffer::new(1, 10, [1.0, 1.0, 1.0]),
    settings,
  )
  let agc_compat = automatic_gain_control_with_params(
    SamplesBuffer::new(1, 10, [1.0, 1.0, 1.0]),
    0.0,
    @moon_cpal.Duration::from_secs((0 : UInt64)),
    @moon_cpal.Duration::from_secs((0 : UInt64)),
    2.0,
  )

  agc.set_floor(Some(0.5))
  assert_true(agc.next().unwrap() > 0.49)
  agc.set_floor(None)
  assert_true(agc.next().unwrap().abs() < 1.0e-9)
  assert_true(agc_compat.next().unwrap().abs() < 1.0e-9)
}

///|
test "rodio::source::blt_filter_smoke" {
  let lp = low_pass_with_q(
    SamplesBuffer::new(1, 48_000, [1.0, 0.0, 0.0, 0.0]),
    1_000,
    0.7,
  )
  let hp = high_pass(SamplesBuffer::new(1, 48_000, [1.0, 0.0, 0.0, 0.0]), 1_000)
  assert_eq(lp.channels(), 1)
  assert_eq(hp.sample_rate(), 48_000)
  assert_eq(lp.inner().channels(), 1)
  assert_eq(hp.inner_mut().sample_rate(), 48_000)
  assert_true(lp.next() is Some(_))
  assert_true(hp.next() is Some(_))
}

///|
test "rodio::source::noise_white_and_pink" {
  let w = WhiteUniform::new(44_100)
  let p = Pink::new(44_100)

  let wv = collect_n(w, 8)
  let pv = collect_n(p, 8)
  assert_eq(wv.length(), 8)
  assert_eq(pv.length(), 8)
  for x in wv {
    assert_true(x >= -1.0 && x <= 1.0)
  }
}

///|
test "rodio::source::distortion_with_gain" {
  let s = SamplesBuffer::new(1, 44_100, [0.25, 0.6, -0.8])
  let d0 = distortion(s, 2.0, 0.9)
  assert_eq(collect_n(d0, 10), [0.5, 0.9, -0.9])

  let s = SamplesBuffer::new(1, 44_100, [0.25, 0.6, -0.8])
  let d = distortion_with_gain(s, 2.0, 0.9)
  assert_eq(collect_n(d, 10), [0.5, 0.9, -0.9])
}

///|
test "rodio::source::reverb" {
  let src = SamplesBuffer::new(1, 1, [1.0, 0.0, 0.0, 0.0])
  let out = reverb(src, @moon_cpal.Duration::from_secs((1 : UInt64)), 0.5)
  assert_eq(collect_n(out, 10), [1.0, 0.5, 0.0, 0.0, 0.0])

  let pulls = @ref.new(0)
  let streaming = DynSource::new(
    fn() {
      pulls.val += 1
      if pulls.val <= 3 {
        Some(1.0)
      } else {
        None
      }
    },
    1,
    1,
  )
  let streaming_reverb = reverb(
    streaming,
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    0.5,
  )
  // Ensure reverb no longer pre-buffers all input on construction.
  assert_eq(pulls.val, 0)
  assert_eq(collect_n(streaming_reverb, 10), [1.0, 1.5, 1.5, 0.5])
}

///|
test "rodio::source::noise_extended" {
  let tri = WhiteTriangular::new(44_100)
  let gauss = WhiteGaussian::new(44_100)
  let velvet = Velvet::new(44_100)
  let blue = Blue::new(44_100)
  let violet = Violet::new(44_100)
  let brown = Brownian::new(44_100)
  let red = Red::new(44_100)

  let tri_v = collect_n(tri, 64)
  let gauss_v = collect_n(gauss, 64)
  let velvet_v = collect_n(velvet, 64)
  let blue_v = collect_n(blue, 64)
  let violet_v = collect_n(violet, 64)
  let brown_v = collect_n(brown, 64)
  let red_v = collect_n(red, 64)

  assert_eq(tri_v.length(), 64)
  assert_eq(gauss_v.length(), 64)
  assert_eq(velvet_v.length(), 64)
  assert_eq(blue_v.length(), 64)
  assert_eq(violet_v.length(), 64)
  assert_eq(brown_v.length(), 64)
  assert_eq(red_v.length(), 64)

  for x in tri_v {
    assert_true(x >= -1.0 && x <= 1.0)
  }
  for x in velvet_v {
    assert_true(x == -1.0 || x == 0.0 || x == 1.0)
  }
  for x in gauss_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in blue_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in violet_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in brown_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in red_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }

  let old_white = white(44_100)
  let old_pink = pink(44_100)
  assert_eq(old_white.sample_rate(), 44_100)
  assert_eq(old_pink.sample_rate(), 44_100)
}

///|
test "rodio::source::noise_generators_trait_and_seek_parity" {
  let sources : Array[DynSource] = [
    to_dyn(WhiteUniform::new(44_100)),
    to_dyn(WhiteTriangular::new(44_100)),
    to_dyn(WhiteGaussian::new(44_100)),
    to_dyn(Pink::new(44_100)),
    to_dyn(Blue::new(44_100)),
    to_dyn(Violet::new(44_100)),
    to_dyn(Brownian::new(44_100)),
    to_dyn(Red::new(44_100)),
    to_dyn(Velvet::new(44_100)),
  ]

  for source in sources {
    assert_eq(source.channels(), 1)
    assert_eq(source.sample_rate(), 44_100)
    assert_eq(source.total_duration(), None)
    assert_eq(source.current_span_len(), None)
    source.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  }
}

///|
test "rodio::source::gaussian_noise_properties" {
  let generator = WhiteGaussian::new(44_100)
  assert_eq(generator.mean(), 0.0)
  assert_true((generator.std_dev() - 0.6).abs() < 1.0e-12)

  let samples = collect_n(generator, 1_000)
  let mut within_bounds = 0
  for sample in samples {
    if sample.abs() <= 1.0 {
      within_bounds += 1
    }
  }

  let percent = Double::from_int(within_bounds) / 1_000.0 * 100.0
  assert_true(percent > 85.0)
}

///|
test "rodio::source::integrated_noise_properties_brownian_and_red" {
  let brown_samples = collect_n(Brownian::new(44_100), 44_100)
  let red_samples = collect_n(Red::new(44_100), 44_100)

  assert_true(mean_of(brown_samples).abs() < 0.5)
  assert_true(mean_of(red_samples).abs() < 0.5)

  assert_true(consecutive_correlation(brown_samples) > 0.1)
  assert_true(consecutive_correlation(red_samples) > 0.1)
}

///|
test "rodio::source::noise_bounded_generators_range" {
  let bounded : Array[DynSource] = [
    to_dyn(WhiteUniform::new(44_100)),
    to_dyn(WhiteTriangular::new(44_100)),
    to_dyn(Pink::new(44_100)),
    to_dyn(Velvet::new(44_100)),
  ]

  for generator in bounded {
    let samples = collect_n(generator, 1_000)
    for sample in samples {
      assert_true(sample >= -1.0 && sample <= 1.0)
    }
  }
}

///|
test "rodio::source::noise_unbounded_generators_finite" {
  let unbounded : Array[DynSource] = [
    to_dyn(WhiteGaussian::new(44_100)),
    to_dyn(Blue::new(44_100)),
    to_dyn(Violet::new(44_100)),
    to_dyn(Brownian::new(44_100)),
    to_dyn(Red::new(44_100)),
  ]

  for generator in unbounded {
    let samples = collect_n(generator, 1_000)
    for sample in samples {
      assert_true(sample == sample)
      assert_true(sample.abs() < 1.0e308)
    }
  }
}

///|
test "rodio::source::white_uniform_distribution" {
  let generator = WhiteUniform::new(44_100)
  assert_true((generator.std_dev() - @math.pow(1.0 / 3.0, 0.5)).abs() < 1.0e-12)

  let samples = collect_n(generator, 1_000)
  let mut minimum = 1.0e9
  let mut maximum = -1.0e9
  for sample in samples {
    if sample < minimum {
      minimum = sample
    }
    if sample > maximum {
      maximum = sample
    }
  }

  assert_true(minimum < -0.9)
  assert_true(maximum > 0.9)
}

///|
test "rodio::source::triangular_distribution" {
  let generator = WhiteTriangular::new(44_100)
  assert_true((generator.std_dev() - 2.0 / @math.pow(6.0, 0.5)).abs() < 1.0e-12)

  let samples = collect_n(generator, 1_000)
  let mut near_zero = 0
  for sample in samples {
    if sample.abs() < 0.5 {
      near_zero += 1
    }
  }

  assert_true(near_zero > 500)
}

///|
test "rodio::source::pink_noise_properties" {
  let samples = collect_n(Pink::new(44_100), 1_000)
  assert_true(consecutive_correlation(samples) > -0.1)
}

///|
test "rodio::source::blue_noise_properties" {
  let samples = collect_n(Blue::new(44_100), 1_000)
  assert_true(consecutive_correlation(samples) < 0.1)
}

///|
test "rodio::source::violet_noise_properties" {
  let samples = collect_n(Violet::new(44_100), 1_000)
  let mean = mean_of(samples)

  let mut diff_variance = 0.0
  let mut signal_variance = 0.0
  for i in 0..<(samples.length() - 1) {
    let diff = samples[i + 1] - samples[i]
    diff_variance += diff * diff
    let centered = samples[i] - mean
    signal_variance += centered * centered
  }
  diff_variance /= Double::from_int(samples.length() - 1)
  signal_variance /= Double::from_int(samples.length())

  assert_true(diff_variance > signal_variance * 0.1)
}

///|
test "rodio::source::velvet_noise_properties" {
  let samples = collect_n(Velvet::new(44_100), 44_100)
  let mut impulse_count = 0
  for sample in samples {
    if sample != 0.0 {
      impulse_count += 1
      assert_true(sample == 1.0 || sample == -1.0)
    }
  }

  assert_true(impulse_count > 1_500)
  assert_true(impulse_count < 2_500)
}

///|
test "rodio::source::velvet_custom_density" {
  let samples = collect_n(Velvet::new_with_density(44_100, 1_000.0), 44_100)
  let mut impulse_count = 0
  for sample in samples {
    if sample != 0.0 {
      impulse_count += 1
    }
  }

  let delta = if impulse_count > 1_000 {
    impulse_count - 1_000
  } else {
    1_000 - impulse_count
  }
  assert_true(delta < 200)
}

///|
test "rodio::source::noise_seeded_generators_repeatability" {
  let seed = (0x1234_5678_9ABC_DEF0 : UInt64)

  assert_eq(
    collect_n(WhiteUniform::new_with_seed(44_100, seed), 64),
    collect_n(WhiteUniform::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(WhiteTriangular::new_with_seed(44_100, seed), 64),
    collect_n(WhiteTriangular::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(WhiteGaussian::new_with_seed(44_100, seed), 64),
    collect_n(WhiteGaussian::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Pink::new_with_seed(44_100, seed), 64),
    collect_n(Pink::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Blue::new_with_seed(44_100, seed), 64),
    collect_n(Blue::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Violet::new_with_seed(44_100, seed), 64),
    collect_n(Violet::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Brownian::new_with_seed(44_100, seed), 64),
    collect_n(Brownian::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Red::new_with_seed(44_100, seed), 64),
    collect_n(Red::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Velvet::new_with_seed(44_100, seed), 64),
    collect_n(Velvet::new_with_seed(44_100, seed), 64),
  )
  assert_eq(
    collect_n(Velvet::new_with_density_and_seed(44_100, 1_000.0, seed), 64),
    collect_n(Velvet::new_with_density_and_seed(44_100, 1_000.0, seed), 64),
  )
}

///|
test "rodio::source::noise_rng_generators_repeatability" {
  let seed = (0xCAFE_BABE_1234_5678 : UInt64)
  assert_eq(
    collect_n(WhiteUniform::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(WhiteUniform::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(
      WhiteTriangular::new_with_rng(44_100, TestNoiseRng::new(seed)),
      64,
    ),
    collect_n(
      WhiteTriangular::new_with_rng(44_100, TestNoiseRng::new(seed)),
      64,
    ),
  )
  assert_eq(
    collect_n(WhiteGaussian::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(WhiteGaussian::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(Pink::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Pink::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(Velvet::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Velvet::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(
      Velvet::new_with_density_and_rng(44_100, 1_000.0, TestNoiseRng::new(seed)),
      64,
    ),
    collect_n(
      Velvet::new_with_density_and_rng(44_100, 1_000.0, TestNoiseRng::new(seed)),
      64,
    ),
  )
  assert_eq(
    collect_n(Blue::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Blue::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(Violet::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Violet::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(Brownian::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Brownian::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
  assert_eq(
    collect_n(Red::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
    collect_n(Red::new_with_rng(44_100, TestNoiseRng::new(seed)), 64),
  )
}

///|
test "rodio::source::noise_different_seeds_diverge" {
  let a = collect_n(WhiteUniform::new_with_seed(44_100, (1 : UInt64)), 32)
  let b = collect_n(WhiteUniform::new_with_seed(44_100, (2 : UInt64)), 32)
  assert_true(a != b)

  let va = collect_n(
    Velvet::new_with_density_and_seed(44_100, 1_000.0, (1 : UInt64)),
    64,
  )
  let vb = collect_n(
    Velvet::new_with_density_and_seed(44_100, 1_000.0, (2 : UInt64)),
    64,
  )
  assert_true(va != vb)
}
