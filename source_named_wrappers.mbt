///|
pub struct Amplify {
  input : DynSource
  factor : Ref[Sample]
}

///|
pub fn[S : Source] Amplify::new(source : S, factor : Sample) -> Amplify {
  { input: to_dyn(source), factor: @ref.new(factor) }
}

///|
pub fn Amplify::set_factor(self : Amplify, factor : Sample) -> Unit {
  self.factor.val = factor
}

///|
pub fn Amplify::set_log_factor(self : Amplify, factor : Sample) -> Unit {
  self.factor.val = @math.pow(10.0, factor / 20.0)
}

///|
pub fn Amplify::inner(self : Amplify) -> DynSource {
  self.input
}

///|
pub fn Amplify::inner_mut(self : Amplify) -> DynSource {
  self.input
}

///|
pub fn Amplify::into_inner(self : Amplify) -> DynSource {
  self.input
}

///|
pub struct Buffered {
  inner : SamplesBuffer
}

///|
pub fn[S : Source] Buffered::new(source : S) -> Buffered {
  { inner: buffered(source) }
}

///|
pub fn Buffered::inner(self : Buffered) -> SamplesBuffer {
  self.inner
}

///|
pub fn Buffered::inner_mut(self : Buffered) -> SamplesBuffer {
  self.inner
}

///|
pub fn Buffered::into_inner(self : Buffered) -> SamplesBuffer {
  self.inner
}

///|
pub struct ChannelVolume {
  input : DynSource
  channel_factors : Ref[Array[Sample]]
  current_channel : Ref[Int]
  current_sample : Ref[Sample?]
}

///|
pub fn[S : Source] ChannelVolume::new(
  source : S,
  channel_factors : Array[Sample],
) -> ChannelVolume {
  guard !channel_factors.is_empty() else { panic() }
  let out_channels = channel_factors.length()
  {
    input: to_dyn(source),
    channel_factors: @ref.new(channel_factors),
    current_channel: @ref.new(out_channels),
    current_sample: @ref.new(None),
  }
}

///|
pub fn ChannelVolume::set_volume(
  self : ChannelVolume,
  channel : Int,
  volume : Sample,
) -> Unit {
  guard channel >= 0 && channel < self.channel_factors.val.length() else {
    panic()
  }
  self.channel_factors.val[channel] = volume
}

///|
pub fn ChannelVolume::inner(self : ChannelVolume) -> DynSource {
  self.input
}

///|
pub fn ChannelVolume::inner_mut(self : ChannelVolume) -> DynSource {
  self.input
}

///|
pub fn ChannelVolume::into_inner(self : ChannelVolume) -> DynSource {
  self.input
}

///|
pub struct Crossfade {
  inner : DynSource
}

///|
pub fn[A : Source, B : Source] Crossfade::new(
  left : A,
  right : B,
  duration : @moon_cpal.Duration,
) -> Crossfade {
  { inner: crossfade(left, right, duration) }
}

///|
pub fn Crossfade::inner(self : Crossfade) -> DynSource {
  self.inner
}

///|
pub fn Crossfade::inner_mut(self : Crossfade) -> DynSource {
  self.inner
}

///|
pub fn Crossfade::into_inner(self : Crossfade) -> DynSource {
  self.inner
}

///|
pub struct Delay {
  inner : DynSource
}

///|
pub fn[S : Source] Delay::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> Delay {
  { inner: delay(source, duration) }
}

///|
pub fn Delay::inner(self : Delay) -> DynSource {
  self.inner
}

///|
pub fn Delay::inner_mut(self : Delay) -> DynSource {
  self.inner
}

///|
pub fn Delay::into_inner(self : Delay) -> DynSource {
  self.inner
}

///|
pub struct Distortion {
  input : DynSource
  gain : Ref[Sample]
  threshold : Ref[Sample]
}

///|
pub fn[S : Source] Distortion::new(
  source : S,
  threshold : Sample,
) -> Distortion {
  { input: to_dyn(source), gain: @ref.new(1.0), threshold: @ref.new(threshold) }
}

///|
pub fn[S : Source] Distortion::with_gain(
  source : S,
  gain : Sample,
  threshold : Sample,
) -> Distortion {
  {
    input: to_dyn(source),
    gain: @ref.new(gain),
    threshold: @ref.new(threshold),
  }
}

///|
pub fn Distortion::set_gain(self : Distortion, gain : Sample) -> Unit {
  self.gain.val = gain
}

///|
pub fn Distortion::set_threshold(self : Distortion, threshold : Sample) -> Unit {
  self.threshold.val = threshold
}

///|
pub fn Distortion::inner(self : Distortion) -> DynSource {
  self.input
}

///|
pub fn Distortion::inner_mut(self : Distortion) -> DynSource {
  self.input
}

///|
pub fn Distortion::into_inner(self : Distortion) -> DynSource {
  self.input
}

///|
pub struct Empty {
  inner : DynSource
}

///|
pub fn Empty::new(channels : ChannelCount, sample_rate : SampleRate) -> Empty {
  { inner: empty(channels, sample_rate) }
}

///|
pub fn Empty::inner(self : Empty) -> DynSource {
  self.inner
}

///|
pub fn Empty::inner_mut(self : Empty) -> DynSource {
  self.inner
}

///|
pub fn Empty::into_inner(self : Empty) -> DynSource {
  self.inner
}

///|
pub struct FadeIn {
  inner : DynSource
}

///|
pub fn[S : Source] FadeIn::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> FadeIn {
  { inner: fade_in(source, duration) }
}

///|
pub fn FadeIn::inner(self : FadeIn) -> DynSource {
  self.inner
}

///|
pub fn FadeIn::inner_mut(self : FadeIn) -> DynSource {
  self.inner
}

///|
pub fn FadeIn::into_inner(self : FadeIn) -> DynSource {
  self.inner
}

///|
pub struct FadeOut {
  inner : DynSource
}

///|
pub fn[S : Source] FadeOut::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> FadeOut {
  { inner: fade_out(source, duration) }
}

///|
pub fn FadeOut::inner(self : FadeOut) -> DynSource {
  self.inner
}

///|
pub fn FadeOut::inner_mut(self : FadeOut) -> DynSource {
  self.inner
}

///|
pub fn FadeOut::into_inner(self : FadeOut) -> DynSource {
  self.inner
}

///|
fn duration_from_millis(ms : Int) -> @moon_cpal.Duration {
  let secs = ms / 1000
  let nanos = ms % 1000 * 1_000_000
  @moon_cpal.Duration::new(secs.to_uint64(), nanos)
}

///|
fn duration_from_micros(us : Int) -> @moon_cpal.Duration {
  let secs = us / 1_000_000
  let nanos = us % 1_000_000 * 1_000
  @moon_cpal.Duration::new(secs.to_uint64(), nanos)
}

///|
fn limit_duration_to_secs(duration : @moon_cpal.Duration) -> Double {
  Double::from_int(duration.secs.to_int()) +
  Double::from_int(duration.nanos) / 1_000_000_000.0
}

///|
fn limit_duration_to_coefficient(
  duration : @moon_cpal.Duration,
  sample_rate : SampleRate,
) -> Sample {
  let secs = limit_duration_to_secs(duration)
  if secs <= 0.0 || sample_rate <= 0 {
    0.0
  } else {
    @math.exp(-1.0 / (secs * Double::from_int(sample_rate)))
  }
}

///|
fn limit_peak_from_threshold(threshold : Sample) -> Sample {
  db_to_linear(threshold)
}

///|
fn limit_threshold_from_peak(peak : Sample) -> Sample {
  if peak <= 0.0 {
    -120.0
  } else {
    linear_to_db(peak)
  }
}

///|
fn limit_peak_from_range(min_value : Sample, max_value : Sample) -> Sample {
  let min_peak = min_value.abs()
  let max_peak = max_value.abs()
  if min_peak > max_peak {
    min_peak
  } else {
    max_peak
  }
}

///|
fn limit_reduction_db(
  sample : Sample,
  threshold : Sample,
  knee_width : Sample,
) -> Sample {
  let bias_db = linear_to_db(sample.abs() + 1.0e-12) - threshold
  if knee_width <= 0.0 {
    if bias_db <= 0.0 {
      0.0
    } else {
      bias_db
    }
  } else {
    let knee_boundary_db = bias_db * 2.0
    if knee_boundary_db < -knee_width {
      0.0
    } else if knee_boundary_db.abs() <= knee_width {
      let x = knee_boundary_db + knee_width
      x * x / (8.0 * knee_width)
    } else {
      bias_db
    }
  }
}

///|
fn limit_max_peak(peaks : Array[Sample]) -> Sample {
  let max_peak = @ref.new(0.0)
  for peak in peaks {
    if peak > max_peak.val {
      max_peak.val = peak
    }
  }
  max_peak.val
}

///|
pub struct LimitSettings {
  min_value : Sample
  max_value : Sample
  threshold : Sample
  knee_width : Sample
  attack : @moon_cpal.Duration
  release : @moon_cpal.Duration
} derive(Show, Eq)

///|
pub fn LimitSettings::default() -> LimitSettings {
  {
    min_value: -1.0,
    max_value: 1.0,
    threshold: -1.0,
    knee_width: 4.0,
    attack: duration_from_millis(5),
    release: duration_from_millis(100),
  }
}

///|
pub fn LimitSettings::new() -> LimitSettings {
  LimitSettings::default()
}

///|
pub fn LimitSettings::with_min(
  self : LimitSettings,
  min_value : Sample,
) -> LimitSettings {
  let peak = limit_peak_from_range(min_value, self.max_value)
  { ..self, min_value, threshold: limit_threshold_from_peak(peak) }
}

///|
pub fn LimitSettings::with_max(
  self : LimitSettings,
  max_value : Sample,
) -> LimitSettings {
  let peak = limit_peak_from_range(self.min_value, max_value)
  { ..self, max_value, threshold: limit_threshold_from_peak(peak) }
}

///|
pub fn LimitSettings::with_threshold(
  self : LimitSettings,
  threshold : Sample,
) -> LimitSettings {
  let peak = limit_peak_from_threshold(threshold)
  { ..self, min_value: -peak, max_value: peak, threshold }
}

///|
pub fn LimitSettings::with_knee_width(
  self : LimitSettings,
  knee_width : Sample,
) -> LimitSettings {
  { ..self, knee_width, }
}

///|
pub fn LimitSettings::with_attack(
  self : LimitSettings,
  attack : @moon_cpal.Duration,
) -> LimitSettings {
  { ..self, attack, }
}

///|
pub fn LimitSettings::with_release(
  self : LimitSettings,
  release : @moon_cpal.Duration,
) -> LimitSettings {
  { ..self, release, }
}

///|
pub fn LimitSettings::dynamic_content() -> LimitSettings {
  LimitSettings::default().with_threshold(-3.0).with_knee_width(6.0)
}

///|
pub fn LimitSettings::broadcast() -> LimitSettings {
  LimitSettings::default()
  .with_knee_width(2.0)
  .with_attack(duration_from_millis(3))
  .with_release(duration_from_millis(50))
}

///|
pub fn LimitSettings::mastering() -> LimitSettings {
  LimitSettings::new()
  .with_threshold(-0.5)
  .with_knee_width(1.0)
  .with_attack(duration_from_millis(1))
  .with_release(duration_from_millis(200))
}

///|
pub fn LimitSettings::gaming() -> LimitSettings {
  LimitSettings::new()
  .with_threshold(-3.0)
  .with_knee_width(3.0)
  .with_attack(duration_from_millis(2))
  .with_release(duration_from_millis(75))
}

///|
pub fn LimitSettings::live_performance() -> LimitSettings {
  LimitSettings::new()
  .with_threshold(-2.0)
  .with_knee_width(3.0)
  .with_attack(duration_from_micros(500))
  .with_release(duration_from_millis(30))
}

///|
pub struct Limit {
  input : DynSource
  settings : LimitSettings
  attack_coeff : Sample
  release_coeff : Sample
  integrators : Ref[Array[Sample]]
  peaks : Ref[Array[Sample]]
  position : Ref[Int]
}

///|
pub fn[S : Source] Limit::new(source : S, settings : LimitSettings) -> Limit {
  let input = to_dyn(source)
  let channels = input.channels()
  let integrators : Array[Sample] = []
  let peaks : Array[Sample] = []
  for _ in 0..<channels {
    integrators.push(0.0)
    peaks.push(0.0)
  }
  {
    input,
    settings,
    attack_coeff: limit_duration_to_coefficient(
      settings.attack,
      input.sample_rate(),
    ),
    release_coeff: limit_duration_to_coefficient(
      settings.release,
      input.sample_rate(),
    ),
    integrators: @ref.new(integrators),
    peaks: @ref.new(peaks),
    position: @ref.new(0),
  }
}

///|
pub fn Limit::inner(self : Limit) -> DynSource {
  self.input
}

///|
pub fn Limit::inner_mut(self : Limit) -> DynSource {
  self.input
}

///|
pub fn Limit::into_inner(self : Limit) -> DynSource {
  self.input
}

///|
fn Limit::reset_state(self : Limit) -> Unit {
  self.position.val = 0
  for i in 0..<self.integrators.val.length() {
    self.integrators.val[i] = 0.0
    self.peaks.val[i] = 0.0
  }
}

///|
pub struct Mix {
  inner : DynSource
}

///|
pub fn[A : Source, B : Source] Mix::new(left : A, right : B) -> Mix {
  { inner: mix(left, right) }
}

///|
pub fn Mix::inner(self : Mix) -> DynSource {
  self.inner
}

///|
pub fn Mix::inner_mut(self : Mix) -> DynSource {
  self.inner
}

///|
pub fn Mix::into_inner(self : Mix) -> DynSource {
  self.inner
}

///|
pub struct Repeat {
  inner : DynSource
}

///|
pub fn[S : Source] Repeat::new(source : S) -> Repeat {
  { inner: repeat_infinite(source) }
}

///|
pub fn Repeat::inner(self : Repeat) -> DynSource {
  self.inner
}

///|
pub fn Repeat::inner_mut(self : Repeat) -> DynSource {
  self.inner
}

///|
pub fn Repeat::into_inner(self : Repeat) -> DynSource {
  self.inner
}

///|
pub struct SkipDuration {
  inner : DynSource
}

///|
pub fn[S : Source] SkipDuration::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> SkipDuration {
  { inner: skip_duration(source, duration) }
}

///|
pub fn SkipDuration::inner(self : SkipDuration) -> DynSource {
  self.inner
}

///|
pub fn SkipDuration::inner_mut(self : SkipDuration) -> DynSource {
  self.inner
}

///|
pub fn SkipDuration::into_inner(self : SkipDuration) -> DynSource {
  self.inner
}

///|
pub struct Speed {
  input : DynSource
  factor : Ref[Double]
}

///|
pub fn[S : Source] Speed::new(source : S, ratio : Double) -> Speed {
  guard ratio > 0.0 else { panic() }
  { input: to_dyn(source), factor: @ref.new(ratio) }
}

///|
pub fn Speed::set_factor(self : Speed, factor : Double) -> Unit {
  guard factor > 0.0 else { panic() }
  self.factor.val = factor
}

///|
pub fn Speed::inner(self : Speed) -> DynSource {
  self.input
}

///|
pub fn Speed::inner_mut(self : Speed) -> DynSource {
  self.input
}

///|
pub fn Speed::into_inner(self : Speed) -> DynSource {
  self.input
}

///|
pub struct TakeDuration {
  inner : DynSource
  requested_duration : @moon_cpal.Duration
  requested_samples : Int
  remaining_samples : Ref[Int]
  filter_fadeout : Ref[Bool]
}

///|
pub fn[S : Source] TakeDuration::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> TakeDuration {
  let inner = to_dyn(source)
  let requested_samples = duration_to_sample_count(
    duration,
    inner.channels(),
    inner.sample_rate(),
  )
  {
    inner,
    requested_duration: duration,
    requested_samples,
    remaining_samples: @ref.new(requested_samples),
    filter_fadeout: @ref.new(false),
  }
}

///|
pub fn TakeDuration::inner(self : TakeDuration) -> DynSource {
  self.inner
}

///|
pub fn TakeDuration::inner_mut(self : TakeDuration) -> DynSource {
  self.inner
}

///|
pub fn TakeDuration::into_inner(self : TakeDuration) -> DynSource {
  self.inner
}

///|
pub fn TakeDuration::set_filter_fadeout(self : TakeDuration) -> Unit {
  self.filter_fadeout.val = true
}

///|
pub fn TakeDuration::clear_filter(self : TakeDuration) -> Unit {
  self.filter_fadeout.val = false
}

///|
pub struct Zero {
  inner : DynSource
}

///|
pub fn Zero::new(channels : ChannelCount, sample_rate : SampleRate) -> Zero {
  { inner: zero(channels, sample_rate) }
}

///|
pub fn Zero::new_samples(
  channels : ChannelCount,
  sample_rate : SampleRate,
  num_samples : Int,
) -> Zero {
  { inner: zero_samples(channels, sample_rate, num_samples) }
}

///|
pub fn Zero::inner(self : Zero) -> DynSource {
  self.inner
}

///|
pub fn Zero::inner_mut(self : Zero) -> DynSource {
  self.inner
}

///|
pub fn Zero::into_inner(self : Zero) -> DynSource {
  self.inner
}

///|
pub struct LinearGainRamp {
  inner : DynSource
}

///|
pub fn[S : Source] LinearGainRamp::new(
  source : S,
  start_gain : Sample,
  end_gain : Sample,
  duration : @moon_cpal.Duration,
) -> LinearGainRamp {
  LinearGainRamp::new_with_clamp(source, start_gain, end_gain, duration, true)
}

///|
pub fn[S : Source] LinearGainRamp::new_with_clamp(
  source : S,
  start_gain : Sample,
  end_gain : Sample,
  duration : @moon_cpal.Duration,
  clamp_end : Bool,
) -> LinearGainRamp {
  {
    inner: linear_gain_ramp_with_clamp(
      source, start_gain, end_gain, duration, clamp_end,
    ),
  }
}

///|
pub fn LinearGainRamp::inner(self : LinearGainRamp) -> DynSource {
  self.inner
}

///|
pub fn LinearGainRamp::inner_mut(self : LinearGainRamp) -> DynSource {
  self.inner
}

///|
pub fn LinearGainRamp::into_inner(self : LinearGainRamp) -> DynSource {
  self.inner
}

///|
pub struct Spatial {
  inner : SpatialSource
}

///|
pub fn[S : Source] Spatial::new(
  input : S,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> Spatial {
  { inner: SpatialSource::new(input, emitter_position, left_ear, right_ear) }
}

///|
pub fn Spatial::set_positions(
  self : Spatial,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> Unit {
  self.inner.set_positions(emitter_position, left_ear, right_ear)
}

///|
pub fn Spatial::inner(self : Spatial) -> SpatialSource {
  self.inner
}

///|
pub fn Spatial::inner_mut(self : Spatial) -> SpatialSource {
  self.inner
}

///|
pub fn Spatial::into_inner(self : Spatial) -> SpatialSource {
  self.inner
}

///|
pub enum Function {
  Sine
  Triangle
  Square
  Sawtooth
} derive(Show, Eq)

///|
pub fn Function::sine() -> Function {
  Function::Sine
}

///|
pub fn Function::triangle() -> Function {
  Function::Triangle
}

///|
pub fn Function::square() -> Function {
  Function::Square
}

///|
pub fn Function::sawtooth() -> Function {
  Function::Sawtooth
}

///|
pub struct GeneratorFunction {
  generator : (Double) -> Sample
}

///|
pub fn GeneratorFunction::new(
  generator : (Double) -> Sample,
) -> GeneratorFunction {
  { generator, }
}

///|
pub fn SignalGenerator::from_function(
  sample_rate : SampleRate,
  frequency : Double,
  function : Function,
) -> SignalGenerator {
  let sf = match function {
    Function::Sine => SignalFunction::Sine
    Function::Triangle => SignalFunction::Triangle
    Function::Square => SignalFunction::Square
    Function::Sawtooth => SignalFunction::Sawtooth
  }
  SignalGenerator::new(sample_rate, frequency, sf)
}

///|
pub fn SignalGenerator::with_function(
  sample_rate : SampleRate,
  frequency : Double,
  function : Function,
) -> SignalGenerator {
  SignalGenerator::from_function(sample_rate, frequency, function)
}

///|
pub fn SignalGenerator::with_generator(
  sample_rate : SampleRate,
  frequency : Double,
  function : GeneratorFunction,
) -> DynSource {
  guard sample_rate > 0 else { panic() }
  guard frequency >= 0.0 else { panic() }

  let phase = @ref.new(0.0)
  DynSource::new(
    fn() {
      let current = phase.val
      let step = frequency / Double::from_int(sample_rate)
      phase.val = wrap_phase(current + step)
      Some((function.generator)(current))
    },
    1,
    sample_rate,
  )
}

///|
fn dyn_next(inner : DynSource) -> Sample? {
  inner.next()
}

///|
fn dyn_channels(inner : DynSource) -> ChannelCount {
  inner.channels()
}

///|
fn dyn_sample_rate(inner : DynSource) -> SampleRate {
  inner.sample_rate()
}

///|
pub impl Source for Amplify with next(self : Amplify) {
  match self.input.next() {
    None => None
    Some(v) => Some(v * self.factor.val)
  }
}

///|
pub impl Source for Amplify with channels(self : Amplify) {
  self.input.channels()
}

///|
pub impl Source for Amplify with sample_rate(self : Amplify) {
  self.input.sample_rate()
}

///|
pub impl Source for ChannelVolume with next(self : ChannelVolume) {
  let out_channels = self.channel_factors.val.length()
  if self.current_channel.val >= out_channels {
    self.current_channel.val = 0
    self.current_sample.val = None
    let in_channels = self.input.channels()
    for _ in 0..<in_channels {
      match self.input.next() {
        None => ()
        Some(s) =>
          self.current_sample.val = Some(
            self.current_sample.val.unwrap_or(0.0) + s,
          )
      }
    }
    self.current_sample.val = self.current_sample.val.map(fn(v) {
      v / Double::from_int(in_channels)
    })
  }
  let result = self.current_sample.val.map(fn(v) {
    v * self.channel_factors.val[self.current_channel.val]
  })
  self.current_channel.val += 1
  result
}

///|
pub impl Source for ChannelVolume with channels(self : ChannelVolume) {
  self.channel_factors.val.length()
}

///|
pub impl Source for ChannelVolume with sample_rate(self : ChannelVolume) {
  self.input.sample_rate()
}

///|
pub impl Source for Crossfade with next(self : Crossfade) {
  dyn_next(self.inner)
}

///|
pub impl Source for Crossfade with channels(self : Crossfade) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Crossfade with sample_rate(self : Crossfade) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for Delay with next(self : Delay) {
  dyn_next(self.inner)
}

///|
pub impl Source for Delay with channels(self : Delay) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Delay with sample_rate(self : Delay) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for Distortion with next(self : Distortion) {
  match self.input.next() {
    None => None
    Some(v) => {
      let value = v * self.gain.val
      let t = self.threshold.val
      if value < -t {
        Some(-t)
      } else if value > t {
        Some(t)
      } else {
        Some(value)
      }
    }
  }
}

///|
pub impl Source for Distortion with channels(self : Distortion) {
  self.input.channels()
}

///|
pub impl Source for Distortion with sample_rate(self : Distortion) {
  self.input.sample_rate()
}

///|
pub impl Source for Empty with next(self : Empty) {
  dyn_next(self.inner)
}

///|
pub impl Source for Empty with channels(self : Empty) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Empty with sample_rate(self : Empty) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for FadeIn with next(self : FadeIn) {
  dyn_next(self.inner)
}

///|
pub impl Source for FadeIn with channels(self : FadeIn) {
  dyn_channels(self.inner)
}

///|
pub impl Source for FadeIn with sample_rate(self : FadeIn) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for FadeOut with next(self : FadeOut) {
  dyn_next(self.inner)
}

///|
pub impl Source for FadeOut with channels(self : FadeOut) {
  dyn_channels(self.inner)
}

///|
pub impl Source for FadeOut with sample_rate(self : FadeOut) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for Limit with next(self : Limit) {
  match self.input.next() {
    None => None
    Some(sample) => {
      let channels = self.integrators.val.length()
      if channels <= 0 {
        return Some(sample)
      }

      let channel = self.position.val % channels
      self.position.val = (channel + 1) % channels

      let limiter_db = limit_reduction_db(
        sample,
        self.settings.threshold,
        self.settings.knee_width,
      )
      let release_smoothed = self.release_coeff * self.integrators.val[channel] +
        (1.0 - self.release_coeff) * limiter_db
      let integrator = if limiter_db > release_smoothed {
        limiter_db
      } else {
        release_smoothed
      }
      self.integrators.val[channel] = integrator
      let peak = self.attack_coeff * self.peaks.val[channel] +
        (1.0 - self.attack_coeff) * integrator
      self.peaks.val[channel] = peak

      Some(sample * db_to_linear(-limit_max_peak(self.peaks.val)))
    }
  }
}

///|
pub impl Source for Limit with channels(self : Limit) {
  self.input.channels()
}

///|
pub impl Source for Limit with sample_rate(self : Limit) {
  self.input.sample_rate()
}

///|
pub impl Source for Mix with next(self : Mix) {
  dyn_next(self.inner)
}

///|
pub impl Source for Mix with channels(self : Mix) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Mix with sample_rate(self : Mix) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for Repeat with next(self : Repeat) {
  dyn_next(self.inner)
}

///|
pub impl Source for Repeat with channels(self : Repeat) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Repeat with sample_rate(self : Repeat) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for SkipDuration with next(self : SkipDuration) {
  dyn_next(self.inner)
}

///|
pub impl Source for SkipDuration with channels(self : SkipDuration) {
  dyn_channels(self.inner)
}

///|
pub impl Source for SkipDuration with sample_rate(self : SkipDuration) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for Speed with next(self : Speed) {
  self.input.next()
}

///|
pub impl Source for Speed with channels(self : Speed) {
  self.input.channels()
}

///|
pub impl Source for Speed with sample_rate(self : Speed) {
  let rate = (Double::from_int(self.input.sample_rate()) * self.factor.val).to_int()
  if rate <= 0 {
    1
  } else {
    rate
  }
}

///|
pub impl Source for TakeDuration with next(self : TakeDuration) {
  if self.remaining_samples.val <= 0 {
    return None
  }

  match self.inner.next() {
    None => {
      self.remaining_samples.val = 0
      None
    }
    Some(v) => {
      let out = if self.filter_fadeout.val && self.requested_samples > 0 {
        v *
        Double::from_int(self.remaining_samples.val) /
        Double::from_int(self.requested_samples)
      } else {
        v
      }
      self.remaining_samples.val -= 1
      Some(out)
    }
  }
}

///|
pub impl Source for TakeDuration with channels(self : TakeDuration) {
  self.inner.channels()
}

///|
pub impl Source for TakeDuration with sample_rate(self : TakeDuration) {
  self.inner.sample_rate()
}

///|
pub impl Source for Zero with next(self : Zero) {
  dyn_next(self.inner)
}

///|
pub impl Source for Zero with channels(self : Zero) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Zero with sample_rate(self : Zero) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for LinearGainRamp with next(self : LinearGainRamp) {
  dyn_next(self.inner)
}

///|
pub impl Source for LinearGainRamp with channels(self : LinearGainRamp) {
  dyn_channels(self.inner)
}

///|
pub impl Source for LinearGainRamp with sample_rate(self : LinearGainRamp) {
  dyn_sample_rate(self.inner)
}

///|
pub fn Buffered::next(self : Buffered) -> Sample? {
  self.inner.next()
}

///|
pub fn Buffered::channels(self : Buffered) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn Buffered::sample_rate(self : Buffered) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for Buffered with next(self : Buffered) {
  self.next()
}

///|
pub impl Source for Buffered with channels(self : Buffered) {
  self.channels()
}

///|
pub impl Source for Buffered with sample_rate(self : Buffered) {
  self.sample_rate()
}

///|
pub fn Spatial::next(self : Spatial) -> Sample? {
  self.inner.next()
}

///|
pub fn Spatial::channels(self : Spatial) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn Spatial::sample_rate(self : Spatial) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for Spatial with next(self : Spatial) {
  self.next()
}

///|
pub impl Source for Spatial with channels(self : Spatial) {
  self.channels()
}

///|
pub impl Source for Spatial with sample_rate(self : Spatial) {
  self.sample_rate()
}

///|
pub impl Source for Amplify with current_span_len(_self : Amplify) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Amplify with total_duration(_self : Amplify) {
  _self.inner().total_duration()
}

///|
pub impl Source for Amplify with try_seek(
  _self : Amplify,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for ChannelVolume with current_span_len(_self : ChannelVolume) {
  _self.inner().current_span_len()
}

///|
pub impl Source for ChannelVolume with total_duration(_self : ChannelVolume) {
  _self.inner().total_duration()
}

///|
pub impl Source for ChannelVolume with try_seek(
  _self : ChannelVolume,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Crossfade with current_span_len(_self : Crossfade) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Crossfade with total_duration(_self : Crossfade) {
  _self.inner().total_duration()
}

///|
pub impl Source for Crossfade with try_seek(
  _self : Crossfade,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Delay with current_span_len(_self : Delay) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Delay with total_duration(_self : Delay) {
  _self.inner().total_duration()
}

///|
pub impl Source for Delay with try_seek(
  _self : Delay,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Distortion with current_span_len(_self : Distortion) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Distortion with total_duration(_self : Distortion) {
  _self.inner().total_duration()
}

///|
pub impl Source for Distortion with try_seek(
  _self : Distortion,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Empty with current_span_len(_self : Empty) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Empty with total_duration(_self : Empty) {
  _self.inner().total_duration()
}

///|
pub impl Source for Empty with try_seek(
  _self : Empty,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for FadeIn with current_span_len(_self : FadeIn) {
  _self.inner().current_span_len()
}

///|
pub impl Source for FadeIn with total_duration(_self : FadeIn) {
  _self.inner().total_duration()
}

///|
pub impl Source for FadeIn with try_seek(
  _self : FadeIn,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for FadeOut with current_span_len(_self : FadeOut) {
  _self.inner().current_span_len()
}

///|
pub impl Source for FadeOut with total_duration(_self : FadeOut) {
  _self.inner().total_duration()
}

///|
pub impl Source for FadeOut with try_seek(
  _self : FadeOut,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Limit with current_span_len(_self : Limit) {
  _self.input.current_span_len()
}

///|
pub impl Source for Limit with total_duration(_self : Limit) {
  _self.input.total_duration()
}

///|
pub impl Source for Limit with try_seek(
  _self : Limit,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
  _self.reset_state()
}

///|
pub impl Source for Mix with current_span_len(_self : Mix) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Mix with total_duration(_self : Mix) {
  _self.inner().total_duration()
}

///|
pub impl Source for Mix with try_seek(_self : Mix, pos : @moon_cpal.Duration) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Repeat with current_span_len(_self : Repeat) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Repeat with total_duration(_self : Repeat) {
  _self.inner().total_duration()
}

///|
pub impl Source for Repeat with try_seek(
  _self : Repeat,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for SkipDuration with current_span_len(_self : SkipDuration) {
  _self.inner().current_span_len()
}

///|
pub impl Source for SkipDuration with total_duration(_self : SkipDuration) {
  _self.inner().total_duration()
}

///|
pub impl Source for SkipDuration with try_seek(
  _self : SkipDuration,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Speed with current_span_len(_self : Speed) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Speed with total_duration(_self : Speed) {
  _self
  .inner()
  .total_duration()
  .map(fn(d) { duration_div_ratio_floor(d, _self.factor.val) })
}

///|
pub impl Source for Speed with try_seek(
  _self : Speed,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(duration_mul_ratio_floor(pos, _self.factor.val))
}

///|
pub impl Source for TakeDuration with current_span_len(_self : TakeDuration) {
  let rem = if _self.remaining_samples.val <= 0 {
    0
  } else {
    _self.remaining_samples.val
  }
  match _self.inner().current_span_len() {
    None => Some(rem)
    Some(v) => Some(if v < rem { v } else { rem })
  }
}

///|
pub impl Source for TakeDuration with total_duration(_self : TakeDuration) {
  _self
  .inner()
  .total_duration()
  .map(fn(v) { duration_min(v, _self.requested_duration) })
}

///|
pub impl Source for TakeDuration with try_seek(
  _self : TakeDuration,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
  let target = sample_index_from_duration(
    pos,
    _self.inner().channels(),
    _self.inner().sample_rate(),
  )
  _self.remaining_samples.val = if target >= _self.requested_samples {
    0
  } else {
    _self.requested_samples - target
  }
}

///|
pub impl Source for Zero with current_span_len(_self : Zero) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Zero with total_duration(_self : Zero) {
  _self.inner().total_duration()
}

///|
pub impl Source for Zero with try_seek(_self : Zero, pos : @moon_cpal.Duration) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for LinearGainRamp with current_span_len(_self : LinearGainRamp) {
  _self.inner().current_span_len()
}

///|
pub impl Source for LinearGainRamp with total_duration(_self : LinearGainRamp) {
  _self.inner().total_duration()
}

///|
pub impl Source for LinearGainRamp with try_seek(
  _self : LinearGainRamp,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Buffered with current_span_len(_self : Buffered) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Buffered with total_duration(_self : Buffered) {
  _self.inner().total_duration()
}

///|
pub impl Source for Buffered with try_seek(
  _self : Buffered,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}

///|
pub impl Source for Spatial with current_span_len(_self : Spatial) {
  _self.inner().current_span_len()
}

///|
pub impl Source for Spatial with total_duration(_self : Spatial) {
  _self.inner().total_duration()
}

///|
pub impl Source for Spatial with try_seek(
  _self : Spatial,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner().try_seek(pos)
}
