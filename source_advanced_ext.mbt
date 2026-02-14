///|
fn duration_to_secs(duration : @moon_cpal.Duration) -> Double {
  Double::from_int(duration.secs.to_int()) +
  Double::from_int(duration.nanos) / 1_000_000_000.0
}

///|
fn agc_coeff(
  duration : @moon_cpal.Duration,
  sample_rate : SampleRate,
) -> Double {
  let secs = duration_to_secs(duration)
  if secs <= 0.0 || sample_rate <= 0 {
    0.0
  } else {
    @math.exp(-1.0 / (secs * Double::from_int(sample_rate)))
  }
}

///|
pub struct AutomaticGainControl {
  input : DynSource
  target_level : Ref[Sample]
  absolute_max_gain : Ref[Sample]
  current_gain : Ref[Sample]
  attack_coeff : Ref[Sample]
  release_coeff : Ref[Sample]
}

///|
pub fn[S : Source] automatic_gain_control(
  source : S,
  target_level : Sample,
  attack_time : @moon_cpal.Duration,
  release_time : @moon_cpal.Duration,
  absolute_max_gain : Sample,
) -> AutomaticGainControl {
  let src = to_dyn(source)
  {
    input: src,
    target_level: @ref.new(target_level),
    absolute_max_gain: @ref.new(absolute_max_gain),
    current_gain: @ref.new(1.0),
    attack_coeff: @ref.new(agc_coeff(attack_time, src.sample_rate())),
    release_coeff: @ref.new(agc_coeff(release_time, src.sample_rate())),
  }
}

///|
pub fn[S : Source] AutomaticGainControl::new(
  source : S,
  target_level : Sample,
  attack_time : @moon_cpal.Duration,
  release_time : @moon_cpal.Duration,
  absolute_max_gain : Sample,
) -> AutomaticGainControl {
  automatic_gain_control(
    source, target_level, attack_time, release_time, absolute_max_gain,
  )
}

///|
pub fn AutomaticGainControl::next(self : AutomaticGainControl) -> Sample? {
  match self.input.next() {
    None => None
    Some(v) => {
      let abs_v = v.abs()
      let raw_target_gain = if abs_v > 1.0e-12 {
        self.target_level.val / abs_v
      } else {
        self.absolute_max_gain.val
      }

      let target_gain = if raw_target_gain < 0.0 {
        0.0
      } else if raw_target_gain > self.absolute_max_gain.val {
        self.absolute_max_gain.val
      } else {
        raw_target_gain
      }

      let current = self.current_gain.val
      let coeff = if target_gain < current {
        self.attack_coeff.val
      } else {
        self.release_coeff.val
      }
      self.current_gain.val = coeff * current + (1.0 - coeff) * target_gain
      Some(v * self.current_gain.val)
    }
  }
}

///|
pub fn AutomaticGainControl::channels(
  self : AutomaticGainControl,
) -> ChannelCount {
  self.input.channels()
}

///|
pub fn AutomaticGainControl::sample_rate(
  self : AutomaticGainControl,
) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for AutomaticGainControl with next(self : AutomaticGainControl) {
  self.next()
}

///|
pub impl Source for AutomaticGainControl with channels(
  self : AutomaticGainControl,
) {
  self.channels()
}

///|
pub impl Source for AutomaticGainControl with sample_rate(
  self : AutomaticGainControl,
) {
  self.sample_rate()
}

///|
pub enum BltMode {
  LowPass
  HighPass
} derive(Show, Eq)

///|
pub struct BltFilter {
  input : DynSource
  mode : Ref[BltMode]
  freq : Ref[Int]
  q : Ref[Sample]
  b0 : Ref[Sample]
  b1 : Ref[Sample]
  b2 : Ref[Sample]
  a1 : Ref[Sample]
  a2 : Ref[Sample]
  x1 : Ref[Sample]
  x2 : Ref[Sample]
  y1 : Ref[Sample]
  y2 : Ref[Sample]
}

///|
fn compute_blt_coeffs(
  mode : BltMode,
  sample_rate : SampleRate,
  freq : Int,
  q : Sample,
) -> (Sample, Sample, Sample, Sample, Sample) {
  let sr = if sample_rate <= 0 { 1 } else { sample_rate }
  let qq = if q <= 1.0e-9 { 0.5 } else { q }
  let w0 = 2.0 * @math.PI * Double::from_int(freq) / Double::from_int(sr)
  let cos_w0 = @math.cos(w0)
  let sin_w0 = @math.sin(w0)
  let alpha = sin_w0 / (2.0 * qq)

  match mode {
    BltMode::LowPass => {
      let bb1 = 1.0 - cos_w0
      let bb0 = bb1 / 2.0
      let bb2 = bb0
      let aa0 = 1.0 + alpha
      let aa1 = -2.0 * cos_w0
      let aa2 = 1.0 - alpha
      (bb0 / aa0, bb1 / aa0, bb2 / aa0, aa1 / aa0, aa2 / aa0)
    }
    BltMode::HighPass => {
      let bb0 = (1.0 + cos_w0) / 2.0
      let bb1 = -1.0 - cos_w0
      let bb2 = bb0
      let aa0 = 1.0 + alpha
      let aa1 = -2.0 * cos_w0
      let aa2 = 1.0 - alpha
      (bb0 / aa0, bb1 / aa0, bb2 / aa0, aa1 / aa0, aa2 / aa0)
    }
  }
}

///|
fn[S : Source] blt_new(
  source : S,
  mode : BltMode,
  freq : Int,
  q : Sample,
) -> BltFilter {
  let src = to_dyn(source)
  let (b0, b1, b2, a1, a2) = compute_blt_coeffs(
    mode,
    src.sample_rate(),
    freq,
    q,
  )
  {
    input: src,
    mode: @ref.new(mode),
    freq: @ref.new(freq),
    q: @ref.new(q),
    b0: @ref.new(b0),
    b1: @ref.new(b1),
    b2: @ref.new(b2),
    a1: @ref.new(a1),
    a2: @ref.new(a2),
    x1: @ref.new(0.0),
    x2: @ref.new(0.0),
    y1: @ref.new(0.0),
    y2: @ref.new(0.0),
  }
}

///|
pub fn[S : Source] low_pass(source : S, freq : Int) -> BltFilter {
  blt_new(source, BltMode::LowPass, freq, 0.5)
}

///|
pub fn[S : Source] high_pass(source : S, freq : Int) -> BltFilter {
  blt_new(source, BltMode::HighPass, freq, 0.5)
}

///|
pub fn[S : Source] low_pass_with_q(
  source : S,
  freq : Int,
  q : Sample,
) -> BltFilter {
  blt_new(source, BltMode::LowPass, freq, q)
}

///|
pub fn[S : Source] high_pass_with_q(
  source : S,
  freq : Int,
  q : Sample,
) -> BltFilter {
  blt_new(source, BltMode::HighPass, freq, q)
}

///|
fn BltFilter::set_formula(
  self : BltFilter,
  mode : BltMode,
  freq : Int,
  q : Sample,
) -> Unit {
  self.mode.val = mode
  self.freq.val = freq
  self.q.val = q
  let (b0, b1, b2, a1, a2) = compute_blt_coeffs(
    mode,
    self.input.sample_rate(),
    freq,
    q,
  )
  self.b0.val = b0
  self.b1.val = b1
  self.b2.val = b2
  self.a1.val = a1
  self.a2.val = a2
}

///|
pub fn BltFilter::to_low_pass(self : BltFilter, freq : Int) -> Unit {
  self.set_formula(BltMode::LowPass, freq, 0.5)
}

///|
pub fn BltFilter::to_high_pass(self : BltFilter, freq : Int) -> Unit {
  self.set_formula(BltMode::HighPass, freq, 0.5)
}

///|
pub fn BltFilter::to_low_pass_with_q(
  self : BltFilter,
  freq : Int,
  q : Sample,
) -> Unit {
  self.set_formula(BltMode::LowPass, freq, q)
}

///|
pub fn BltFilter::to_high_pass_with_q(
  self : BltFilter,
  freq : Int,
  q : Sample,
) -> Unit {
  self.set_formula(BltMode::HighPass, freq, q)
}

///|
pub fn BltFilter::next(self : BltFilter) -> Sample? {
  match self.input.next() {
    None => None
    Some(x0) => {
      let y0 = self.b0.val * x0 +
        self.b1.val * self.x1.val +
        self.b2.val * self.x2.val -
        self.a1.val * self.y1.val -
        self.a2.val * self.y2.val
      self.x2.val = self.x1.val
      self.x1.val = x0
      self.y2.val = self.y1.val
      self.y1.val = y0
      Some(y0)
    }
  }
}

///|
pub fn BltFilter::channels(self : BltFilter) -> ChannelCount {
  self.input.channels()
}

///|
pub fn BltFilter::sample_rate(self : BltFilter) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for BltFilter with next(self : BltFilter) {
  self.next()
}

///|
pub impl Source for BltFilter with channels(self : BltFilter) {
  self.channels()
}

///|
pub impl Source for BltFilter with sample_rate(self : BltFilter) {
  self.sample_rate()
}

///|
fn lcg_next(state : Ref[UInt64]) -> UInt64 {
  state.val = state.val * (6364136223846793005 : UInt64) +
    (1442695040888963407 : UInt64)
  state.val
}

///|
fn rand_unit(state : Ref[UInt64]) -> Sample {
  let x = lcg_next(state)
  Double::from_int((x & (0x7fff_ffff : UInt64)).to_int()) / 2147483647.0
}

///|
pub struct WhiteUniform {
  sample_rate : SampleRate
  state : Ref[UInt64]
}

///|
pub fn WhiteUniform::new(sample_rate : SampleRate) -> WhiteUniform {
  guard sample_rate > 0 else { panic() }
  { sample_rate, state: @ref.new((0x9E3779B97F4A7C15 : UInt64)) }
}

///|
pub fn WhiteUniform::next(self : WhiteUniform) -> Sample? {
  Some(rand_unit(self.state) * 2.0 - 1.0)
}

///|
pub fn WhiteUniform::channels(_self : WhiteUniform) -> ChannelCount {
  1
}

///|
pub fn WhiteUniform::sample_rate(self : WhiteUniform) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for WhiteUniform with next(self : WhiteUniform) {
  self.next()
}

///|
pub impl Source for WhiteUniform with channels(self : WhiteUniform) {
  self.channels()
}

///|
pub impl Source for WhiteUniform with sample_rate(self : WhiteUniform) {
  self.sample_rate()
}

///|
pub struct Pink {
  sample_rate : SampleRate
  state : Ref[UInt64]
  prev : Ref[Sample]
}

///|
pub fn Pink::new(sample_rate : SampleRate) -> Pink {
  guard sample_rate > 0 else { panic() }
  {
    sample_rate,
    state: @ref.new((0xD1B54A32D192ED03 : UInt64)),
    prev: @ref.new(0.0),
  }
}

///|
pub fn Pink::next(self : Pink) -> Sample? {
  let white = rand_unit(self.state) * 2.0 - 1.0
  self.prev.val = 0.98 * self.prev.val + 0.02 * white
  Some(self.prev.val * 5.0)
}

///|
pub fn Pink::channels(_self : Pink) -> ChannelCount {
  1
}

///|
pub fn Pink::sample_rate(self : Pink) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Pink with next(self : Pink) {
  self.next()
}

///|
pub impl Source for Pink with channels(self : Pink) {
  self.channels()
}

///|
pub impl Source for Pink with sample_rate(self : Pink) {
  self.sample_rate()
}
