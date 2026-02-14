///|
pub struct Amplify {
  inner : DynSource
}

///|
pub fn[S : Source] Amplify::new(source : S, factor : Sample) -> Amplify {
  { inner: amplify(source, factor) }
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
pub struct ChannelVolume {
  inner : DynSource
}

///|
pub fn[S : Source] ChannelVolume::new(
  source : S,
  channel_factors : Array[Sample],
) -> ChannelVolume {
  { inner: channel_volume(source, channel_factors) }
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
pub struct Distortion {
  inner : DynSource
}

///|
pub fn[S : Source] Distortion::new(
  source : S,
  threshold : Sample,
) -> Distortion {
  { inner: distortion(source, threshold) }
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
pub struct LimitSettings {
  min_value : Sample
  max_value : Sample
} derive(Show, Eq)

///|
pub fn LimitSettings::default() -> LimitSettings {
  { min_value: -1.0, max_value: 1.0 }
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
  { ..self, min_value, }
}

///|
pub fn LimitSettings::with_max(
  self : LimitSettings,
  max_value : Sample,
) -> LimitSettings {
  { ..self, max_value, }
}

///|
pub struct Limit {
  inner : DynSource
}

///|
pub fn[S : Source] Limit::new(source : S, settings : LimitSettings) -> Limit {
  { inner: limit(source, settings.min_value, settings.max_value) }
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
pub struct Repeat {
  inner : DynSource
}

///|
pub fn[S : Source] Repeat::new(source : S) -> Repeat {
  { inner: repeat_infinite(source) }
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
pub struct Speed {
  inner : DynSource
}

///|
pub fn[S : Source] Speed::new(source : S, ratio : Double) -> Speed {
  { inner: speed(source, ratio) }
}

///|
pub struct TakeDuration {
  inner : DynSource
}

///|
pub fn[S : Source] TakeDuration::new(
  source : S,
  duration : @moon_cpal.Duration,
) -> TakeDuration {
  { inner: take_duration(source, duration) }
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
  { inner: linear_gain_ramp(source, start_gain, end_gain, duration) }
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
  dyn_next(self.inner)
}

///|
pub impl Source for Amplify with channels(self : Amplify) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Amplify with sample_rate(self : Amplify) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for ChannelVolume with next(self : ChannelVolume) {
  dyn_next(self.inner)
}

///|
pub impl Source for ChannelVolume with channels(self : ChannelVolume) {
  dyn_channels(self.inner)
}

///|
pub impl Source for ChannelVolume with sample_rate(self : ChannelVolume) {
  dyn_sample_rate(self.inner)
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
  dyn_next(self.inner)
}

///|
pub impl Source for Distortion with channels(self : Distortion) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Distortion with sample_rate(self : Distortion) {
  dyn_sample_rate(self.inner)
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
  dyn_next(self.inner)
}

///|
pub impl Source for Limit with channels(self : Limit) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Limit with sample_rate(self : Limit) {
  dyn_sample_rate(self.inner)
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
  dyn_next(self.inner)
}

///|
pub impl Source for Speed with channels(self : Speed) {
  dyn_channels(self.inner)
}

///|
pub impl Source for Speed with sample_rate(self : Speed) {
  dyn_sample_rate(self.inner)
}

///|
pub impl Source for TakeDuration with next(self : TakeDuration) {
  dyn_next(self.inner)
}

///|
pub impl Source for TakeDuration with channels(self : TakeDuration) {
  dyn_channels(self.inner)
}

///|
pub impl Source for TakeDuration with sample_rate(self : TakeDuration) {
  dyn_sample_rate(self.inner)
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
