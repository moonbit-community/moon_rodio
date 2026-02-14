///|
pub enum SignalFunction {
  Sine
  Square
  Sawtooth
  Triangle
} derive(Show, Eq)

///|
pub struct SignalGenerator {
  channels : ChannelCount
  sample_rate : SampleRate
  frequency : Double
  function : SignalFunction
  phase : Ref[Double]
}

///|
fn wrap_phase(phase : Double) -> Double {
  let p = phase - @math.floor(phase)
  if p < 0.0 {
    p + 1.0
  } else {
    p
  }
}

///|
fn signal_value(function : SignalFunction, phase : Double) -> Sample {
  match function {
    SignalFunction::Sine => @math.sin(2.0 * @math.PI * phase)
    SignalFunction::Square => if phase < 0.5 { 1.0 } else { -1.0 }
    SignalFunction::Sawtooth => 2.0 * (phase - @math.floor(phase + 0.5))
    SignalFunction::Triangle =>
      if phase < 0.5 {
        phase * 4.0 - 1.0
      } else {
        3.0 - phase * 4.0
      }
  }
}

///|
pub fn SignalGenerator::new(
  sample_rate : SampleRate,
  frequency : Double,
  function : SignalFunction,
) -> SignalGenerator {
  guard sample_rate > 0 else { panic() }
  guard frequency != 0.0 else { panic() }
  { channels: 1, sample_rate, frequency, function, phase: @ref.new(0.0) }
}

///|
fn signal_phase_from_seek(
  pos : @moon_cpal.Duration,
  frequency : Double,
) -> Double {
  wrap_phase(duration_secs_f64(pos) * frequency)
}

///|
pub fn SignalGenerator::next(self : SignalGenerator) -> Sample? {
  let current = self.phase.val
  let step = self.frequency / Double::from_int(self.sample_rate)
  self.phase.val = wrap_phase(current + step)
  Some(signal_value(self.function, current))
}

///|
pub fn SignalGenerator::channels(self : SignalGenerator) -> ChannelCount {
  self.channels
}

///|
pub fn SignalGenerator::sample_rate(self : SignalGenerator) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for SignalGenerator with next(self : SignalGenerator) {
  self.next()
}

///|
pub impl Source for SignalGenerator with channels(self : SignalGenerator) {
  self.channels()
}

///|
pub impl Source for SignalGenerator with sample_rate(self : SignalGenerator) {
  self.sample_rate()
}

///|
pub impl Source for SignalGenerator with current_span_len(
  _self : SignalGenerator,
) {
  source_default_current_span_len()
}

///|
pub impl Source for SignalGenerator with total_duration(_self : SignalGenerator) {
  source_default_total_duration()
}

///|
pub impl Source for SignalGenerator with try_seek(
  self : SignalGenerator,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.phase.val = signal_phase_from_seek(pos, self.frequency)
}

///|
pub struct SineWave {
  inner : SignalGenerator
}

///|
pub fn SineWave::new(freq : Double) -> SineWave {
  { inner: SignalGenerator::new(48_000, freq, SignalFunction::Sine) }
}

///|
pub fn SineWave::next(self : SineWave) -> Sample? {
  self.inner.next()
}

///|
pub fn SineWave::channels(self : SineWave) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn SineWave::sample_rate(self : SineWave) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for SineWave with next(self : SineWave) {
  self.next()
}

///|
pub impl Source for SineWave with channels(self : SineWave) {
  self.channels()
}

///|
pub impl Source for SineWave with sample_rate(self : SineWave) {
  self.sample_rate()
}

///|
pub impl Source for SineWave with current_span_len(_self : SineWave) {
  source_default_current_span_len()
}

///|
pub impl Source for SineWave with total_duration(_self : SineWave) {
  source_default_total_duration()
}

///|
pub impl Source for SineWave with try_seek(
  self : SineWave,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub struct SquareWave {
  inner : SignalGenerator
}

///|
pub fn SquareWave::new(freq : Double) -> SquareWave {
  { inner: SignalGenerator::new(48_000, freq, SignalFunction::Square) }
}

///|
pub fn SquareWave::next(self : SquareWave) -> Sample? {
  self.inner.next()
}

///|
pub fn SquareWave::channels(self : SquareWave) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn SquareWave::sample_rate(self : SquareWave) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for SquareWave with next(self : SquareWave) {
  self.next()
}

///|
pub impl Source for SquareWave with channels(self : SquareWave) {
  self.channels()
}

///|
pub impl Source for SquareWave with sample_rate(self : SquareWave) {
  self.sample_rate()
}

///|
pub impl Source for SquareWave with current_span_len(_self : SquareWave) {
  source_default_current_span_len()
}

///|
pub impl Source for SquareWave with total_duration(_self : SquareWave) {
  source_default_total_duration()
}

///|
pub impl Source for SquareWave with try_seek(
  self : SquareWave,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub struct SawtoothWave {
  inner : SignalGenerator
}

///|
pub fn SawtoothWave::new(freq : Double) -> SawtoothWave {
  { inner: SignalGenerator::new(48_000, freq, SignalFunction::Sawtooth) }
}

///|
pub fn SawtoothWave::next(self : SawtoothWave) -> Sample? {
  self.inner.next()
}

///|
pub fn SawtoothWave::channels(self : SawtoothWave) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn SawtoothWave::sample_rate(self : SawtoothWave) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for SawtoothWave with next(self : SawtoothWave) {
  self.next()
}

///|
pub impl Source for SawtoothWave with channels(self : SawtoothWave) {
  self.channels()
}

///|
pub impl Source for SawtoothWave with sample_rate(self : SawtoothWave) {
  self.sample_rate()
}

///|
pub impl Source for SawtoothWave with current_span_len(_self : SawtoothWave) {
  source_default_current_span_len()
}

///|
pub impl Source for SawtoothWave with total_duration(_self : SawtoothWave) {
  source_default_total_duration()
}

///|
pub impl Source for SawtoothWave with try_seek(
  self : SawtoothWave,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub struct TriangleWave {
  inner : SignalGenerator
}

///|
pub fn TriangleWave::new(freq : Double) -> TriangleWave {
  { inner: SignalGenerator::new(48_000, freq, SignalFunction::Triangle) }
}

///|
pub fn TriangleWave::next(self : TriangleWave) -> Sample? {
  self.inner.next()
}

///|
pub fn TriangleWave::channels(self : TriangleWave) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn TriangleWave::sample_rate(self : TriangleWave) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for TriangleWave with next(self : TriangleWave) {
  self.next()
}

///|
pub impl Source for TriangleWave with channels(self : TriangleWave) {
  self.channels()
}

///|
pub impl Source for TriangleWave with sample_rate(self : TriangleWave) {
  self.sample_rate()
}

///|
pub impl Source for TriangleWave with current_span_len(_self : TriangleWave) {
  source_default_current_span_len()
}

///|
pub impl Source for TriangleWave with total_duration(_self : TriangleWave) {
  source_default_total_duration()
}

///|
pub impl Source for TriangleWave with try_seek(
  self : TriangleWave,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub fn empty(channels : ChannelCount, sample_rate : SampleRate) -> DynSource {
  make_empty_dyn_source(channels, sample_rate)
}

///|
pub fn zero(channels : ChannelCount, sample_rate : SampleRate) -> DynSource {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  DynSource::new(fn() { Some(0.0) }, channels, sample_rate, try_seek=fn(
    _pos : @moon_cpal.Duration,
  ) {
    Ok(())
  })
}

///|
pub fn zero_samples(
  channels : ChannelCount,
  sample_rate : SampleRate,
  sample_count : Int,
) -> DynSource {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  let remaining = @ref.new(if sample_count < 0 { 0 } else { sample_count })
  DynSource::new(
    fn() {
      if remaining.val <= 0 {
        None
      } else {
        remaining.val -= 1
        Some(0.0)
      }
    },
    channels,
    sample_rate,
    current_span_len=fn() {
      Some(if remaining.val <= 0 { 0 } else { remaining.val })
    },
    try_seek=fn(_pos : @moon_cpal.Duration) { Ok(()) },
  )
}

///|
pub fn[S : Source] amplify(source : S, factor : Sample) -> DynSource {
  let src = to_dyn(source)
  DynSource::new_dynamic(
    fn() {
      match src.next() {
        None => None
        Some(v) => Some(v * factor)
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
  )
}

///|
pub fn[S : Source] take(source : S, sample_count : Int) -> DynSource {
  let src = to_dyn(source)
  let remaining = @ref.new(if sample_count < 0 { 0 } else { sample_count })
  DynSource::new_dynamic(
    fn() {
      if remaining.val <= 0 {
        None
      } else {
        remaining.val -= 1
        src.next()
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
  )
}

///|
pub fn[A : Source, B : Source] mix(left : A, right : B) -> DynSource {
  let lhs_source = to_dyn(left)
  let channels = lhs_source.channels()
  let sample_rate = lhs_source.sample_rate()
  let lhs = UniformSourceIterator::new(lhs_source, channels, sample_rate)
  let rhs = UniformSourceIterator::new(right, channels, sample_rate)
  DynSource::new_dynamic(
    fn() {
      match (lhs.next(), rhs.next()) {
        (None, None) => None
        (Some(a), None) => Some(a)
        (None, Some(b)) => Some(b)
        (Some(a), Some(b)) => Some(a + b)
      }
    },
    fn() { channels },
    fn() { sample_rate },
    current_span_len=fn() {
      match (lhs.current_span_len(), rhs.current_span_len()) {
        (Some(a), Some(b)) => Some(if a < b { a } else { b })
        _ => None
      }
    },
    total_duration=fn() {
      match (lhs.total_duration(), rhs.total_duration()) {
        (Some(a), Some(b)) =>
          Some(if duration_compare(a, b) >= 0 { a } else { b })
        _ => None
      }
    },
  )
}

///|
pub fn[S : Source] speed(source : S, ratio : Double) -> DynSource {
  guard ratio > 0.0 else { panic() }
  let src = to_dyn(source)
  let init_rate = (Double::from_int(src.sample_rate()) * ratio).to_int()
  guard init_rate > 0 else { panic() }
  DynSource::new_dynamic(
    fn() { src.next() },
    fn() { src.channels() },
    fn() {
      let rate = (Double::from_int(src.sample_rate()) * ratio).to_int()
      if rate <= 0 {
        1
      } else {
        rate
      }
    },
    current_span_len=fn() { src.current_span_len() },
    total_duration=fn() {
      src.total_duration().map(fn(d) { duration_div_ratio_floor(d, ratio) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
      let mapped = duration_mul_ratio_floor(pos, ratio)
      try {
        src.try_seek(mapped)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
pub fn SamplesBuffer::repeat_infinite(self : SamplesBuffer) -> DynSource {
  if self.samples.is_empty() {
    return make_empty_dyn_source(self.channels, self.sample_rate)
  }

  let len = self.samples.length()
  let idx = @ref.new(0)
  let data = self.samples
  DynSource::new(
    fn() {
      let v = data[idx.val]
      idx.val = (idx.val + 1) % len
      Some(v)
    },
    self.channels,
    self.sample_rate,
    current_span_len=fn() { Some(len - idx.val) },
    try_seek=fn(pos : @moon_cpal.Duration) {
      let target = sample_index_from_duration(
        pos,
        self.channels,
        self.sample_rate,
      )
      if target <= 0 {
        idx.val = 0
      } else {
        idx.val = target % len
      }
      Ok(())
    },
  )
}
