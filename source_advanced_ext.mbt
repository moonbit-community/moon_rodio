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
  agc_control : Ref[Bool]
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
    agc_control: @ref.new(true),
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
pub fn AutomaticGainControl::inner(self : AutomaticGainControl) -> DynSource {
  self.input
}

///|
pub fn AutomaticGainControl::inner_mut(
  self : AutomaticGainControl,
) -> DynSource {
  self.input
}

///|
pub fn AutomaticGainControl::next(self : AutomaticGainControl) -> Sample? {
  match self.input.next() {
    None => None
    Some(v) => {
      if !self.agc_control.val {
        return Some(v)
      }
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
pub fn AutomaticGainControl::get_target_level(
  self : AutomaticGainControl,
) -> Ref[Sample] {
  self.target_level
}

///|
pub fn AutomaticGainControl::get_absolute_max_gain(
  self : AutomaticGainControl,
) -> Ref[Sample] {
  self.absolute_max_gain
}

///|
pub fn AutomaticGainControl::get_attack_coeff(
  self : AutomaticGainControl,
) -> Ref[Sample] {
  self.attack_coeff
}

///|
pub fn AutomaticGainControl::get_release_coeff(
  self : AutomaticGainControl,
) -> Ref[Sample] {
  self.release_coeff
}

///|
pub fn AutomaticGainControl::get_agc_control(
  self : AutomaticGainControl,
) -> Ref[Bool] {
  self.agc_control
}

///|
pub fn AutomaticGainControl::set_enabled(
  self : AutomaticGainControl,
  enabled : Bool,
) -> Unit {
  self.agc_control.val = enabled
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
pub fn BltFilter::inner(self : BltFilter) -> DynSource {
  self.input
}

///|
pub fn BltFilter::inner_mut(self : BltFilter) -> DynSource {
  self.input
}

///|
pub fn BltFilter::into_inner(self : BltFilter) -> DynSource {
  self.input
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
fn rand_signed(state : Ref[UInt64]) -> Sample {
  rand_unit(state) * 2.0 - 1.0
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
  Some(rand_signed(self.state))
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
pub fn white(sample_rate : SampleRate) -> WhiteUniform {
  WhiteUniform::new(sample_rate)
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
  let white = rand_signed(self.state)
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

///|
pub fn pink(sample_rate : SampleRate) -> Pink {
  Pink::new(sample_rate)
}

///|
pub struct WhiteTriangular {
  sample_rate : SampleRate
  state : Ref[UInt64]
}

///|
pub fn WhiteTriangular::new(sample_rate : SampleRate) -> WhiteTriangular {
  guard sample_rate > 0 else { panic() }
  { sample_rate, state: @ref.new((0x94D049BB133111EB : UInt64)) }
}

///|
pub fn WhiteTriangular::next(self : WhiteTriangular) -> Sample? {
  Some((rand_signed(self.state) + rand_signed(self.state)) / 2.0)
}

///|
pub fn WhiteTriangular::channels(_self : WhiteTriangular) -> ChannelCount {
  1
}

///|
pub fn WhiteTriangular::sample_rate(self : WhiteTriangular) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for WhiteTriangular with next(self : WhiteTriangular) {
  self.next()
}

///|
pub impl Source for WhiteTriangular with channels(self : WhiteTriangular) {
  self.channels()
}

///|
pub impl Source for WhiteTriangular with sample_rate(self : WhiteTriangular) {
  self.sample_rate()
}

///|
pub struct WhiteGaussian {
  sample_rate : SampleRate
  state : Ref[UInt64]
}

///|
pub fn WhiteGaussian::new(sample_rate : SampleRate) -> WhiteGaussian {
  guard sample_rate > 0 else { panic() }
  { sample_rate, state: @ref.new((0x369DEA0F31A53F85 : UInt64)) }
}

///|
pub fn WhiteGaussian::mean(_self : WhiteGaussian) -> Sample {
  0.0
}

///|
pub fn WhiteGaussian::std_dev(_self : WhiteGaussian) -> Sample {
  0.6
}

///|
pub fn WhiteGaussian::next(self : WhiteGaussian) -> Sample? {
  // Irwin-Hall approximation of a normal distribution.
  let mut sum = 0.0
  for _ in 0..<12 {
    sum += rand_unit(self.state)
  }
  Some((sum - 6.0) / 3.0)
}

///|
pub fn WhiteGaussian::channels(_self : WhiteGaussian) -> ChannelCount {
  1
}

///|
pub fn WhiteGaussian::sample_rate(self : WhiteGaussian) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for WhiteGaussian with next(self : WhiteGaussian) {
  self.next()
}

///|
pub impl Source for WhiteGaussian with channels(self : WhiteGaussian) {
  self.channels()
}

///|
pub impl Source for WhiteGaussian with sample_rate(self : WhiteGaussian) {
  self.sample_rate()
}

///|
let velvet_default_density : Sample = 2_000.0

///|
pub struct Velvet {
  sample_rate : SampleRate
  state : Ref[UInt64]
  grid_size : Ref[Sample]
  grid_pos : Ref[Sample]
  impulse_pos : Ref[Sample]
}

///|
pub fn Velvet::new(sample_rate : SampleRate) -> Velvet {
  Velvet::new_with_density(sample_rate, velvet_default_density)
}

///|
pub fn Velvet::new_with_density(
  sample_rate : SampleRate,
  density : Sample,
) -> Velvet {
  guard sample_rate > 0 else { panic() }
  let density = if density <= 1.0e-9 { velvet_default_density } else { density }
  let grid_size = Double::from_int(sample_rate) / density
  let state = @ref.new((0x2545F4914F6CDD1D : UInt64))
  let impulse_pos = rand_unit(state) * grid_size
  {
    sample_rate,
    state,
    grid_size: @ref.new(grid_size),
    grid_pos: @ref.new(0.0),
    impulse_pos: @ref.new(impulse_pos),
  }
}

///|
pub fn Velvet::next(self : Velvet) -> Sample? {
  let out = if self.grid_pos.val.to_int() == self.impulse_pos.val.to_int() {
    if rand_unit(self.state) > 0.5 {
      1.0
    } else {
      -1.0
    }
  } else {
    0.0
  }

  self.grid_pos.val += 1.0
  if self.grid_pos.val >= self.grid_size.val {
    self.grid_pos.val = 0.0
    self.impulse_pos.val = rand_unit(self.state) * self.grid_size.val
  }

  Some(out)
}

///|
pub fn Velvet::channels(_self : Velvet) -> ChannelCount {
  1
}

///|
pub fn Velvet::sample_rate(self : Velvet) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Velvet with next(self : Velvet) {
  self.next()
}

///|
pub impl Source for Velvet with channels(self : Velvet) {
  self.channels()
}

///|
pub impl Source for Velvet with sample_rate(self : Velvet) {
  self.sample_rate()
}

///|
pub struct Blue {
  sample_rate : SampleRate
  white_noise : WhiteUniform
  prev_white : Ref[Sample]
}

///|
pub fn Blue::new(sample_rate : SampleRate) -> Blue {
  guard sample_rate > 0 else { panic() }
  {
    sample_rate,
    white_noise: WhiteUniform::new(sample_rate),
    prev_white: @ref.new(0.0),
  }
}

///|
pub fn Blue::next(self : Blue) -> Sample? {
  let white = self.white_noise.next().unwrap()
  let blue = white - self.prev_white.val
  self.prev_white.val = white
  Some(blue)
}

///|
pub fn Blue::channels(_self : Blue) -> ChannelCount {
  1
}

///|
pub fn Blue::sample_rate(self : Blue) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Blue with next(self : Blue) {
  self.next()
}

///|
pub impl Source for Blue with channels(self : Blue) {
  self.channels()
}

///|
pub impl Source for Blue with sample_rate(self : Blue) {
  self.sample_rate()
}

///|
pub struct Violet {
  sample_rate : SampleRate
  blue_noise : Blue
  prev : Ref[Sample]
}

///|
pub fn Violet::new(sample_rate : SampleRate) -> Violet {
  guard sample_rate > 0 else { panic() }
  { sample_rate, blue_noise: Blue::new(sample_rate), prev: @ref.new(0.0) }
}

///|
pub fn Violet::next(self : Violet) -> Sample? {
  let blue = self.blue_noise.next().unwrap()
  let violet = blue - self.prev.val
  self.prev.val = blue
  Some(violet)
}

///|
pub fn Violet::channels(_self : Violet) -> ChannelCount {
  1
}

///|
pub fn Violet::sample_rate(self : Violet) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Violet with next(self : Violet) {
  self.next()
}

///|
pub impl Source for Violet with channels(self : Violet) {
  self.channels()
}

///|
pub impl Source for Violet with sample_rate(self : Violet) {
  self.sample_rate()
}

///|
pub struct Brownian {
  sample_rate : SampleRate
  white_noise : WhiteGaussian
  accumulator : Ref[Sample]
  leak_factor : Ref[Sample]
  scale : Ref[Sample]
}

///|
pub fn Brownian::new(sample_rate : SampleRate) -> Brownian {
  guard sample_rate > 0 else { panic() }
  let white_noise = WhiteGaussian::new(sample_rate)
  let center_freq_hz = 5.0
  let mut leak = 1.0 -
    2.0 * @math.PI * center_freq_hz / Double::from_int(sample_rate)
  if leak < 0.0 {
    leak = 0.0
  }
  let stddev = white_noise.std_dev()
  let variance = stddev * stddev / (1.0 - leak * leak + 1.0e-12)
  let scale = 1.0 / @math.pow(variance, 0.5)
  {
    sample_rate,
    white_noise,
    accumulator: @ref.new(0.0),
    leak_factor: @ref.new(leak),
    scale: @ref.new(scale),
  }
}

///|
pub fn Brownian::next(self : Brownian) -> Sample? {
  let white = self.white_noise.next().unwrap()
  self.accumulator.val = self.accumulator.val * self.leak_factor.val + white
  Some(self.accumulator.val * self.scale.val)
}

///|
pub fn Brownian::channels(_self : Brownian) -> ChannelCount {
  1
}

///|
pub fn Brownian::sample_rate(self : Brownian) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Brownian with next(self : Brownian) {
  self.next()
}

///|
pub impl Source for Brownian with channels(self : Brownian) {
  self.channels()
}

///|
pub impl Source for Brownian with sample_rate(self : Brownian) {
  self.sample_rate()
}

///|
pub struct Red {
  sample_rate : SampleRate
  white_noise : WhiteUniform
  accumulator : Ref[Sample]
  leak_factor : Ref[Sample]
  scale : Ref[Sample]
}

///|
pub fn Red::new(sample_rate : SampleRate) -> Red {
  guard sample_rate > 0 else { panic() }
  let white_noise = WhiteUniform::new(sample_rate)
  let center_freq_hz = 5.0
  let mut leak = 1.0 -
    2.0 * @math.PI * center_freq_hz / Double::from_int(sample_rate)
  if leak < 0.0 {
    leak = 0.0
  }
  let stddev = @math.pow(1.0 / 3.0, 0.5)
  let variance = stddev * stddev / (1.0 - leak * leak + 1.0e-12)
  let scale = 1.0 / @math.pow(variance, 0.5)
  {
    sample_rate,
    white_noise,
    accumulator: @ref.new(0.0),
    leak_factor: @ref.new(leak),
    scale: @ref.new(scale),
  }
}

///|
pub fn Red::next(self : Red) -> Sample? {
  let white = self.white_noise.next().unwrap()
  self.accumulator.val = self.accumulator.val * self.leak_factor.val + white
  Some(self.accumulator.val * self.scale.val)
}

///|
pub fn Red::channels(_self : Red) -> ChannelCount {
  1
}

///|
pub fn Red::sample_rate(self : Red) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Red with next(self : Red) {
  self.next()
}

///|
pub impl Source for Red with channels(self : Red) {
  self.channels()
}

///|
pub impl Source for Red with sample_rate(self : Red) {
  self.sample_rate()
}

///|
pub impl Source for AutomaticGainControl with current_span_len(
  _self : AutomaticGainControl,
) {
  _self.input.current_span_len()
}

///|
pub impl Source for AutomaticGainControl with total_duration(
  _self : AutomaticGainControl,
) {
  _self.input.total_duration()
}

///|
pub impl Source for AutomaticGainControl with try_seek(
  _self : AutomaticGainControl,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
}

///|
pub impl Source for BltFilter with current_span_len(_self : BltFilter) {
  _self.input.current_span_len()
}

///|
pub impl Source for BltFilter with total_duration(_self : BltFilter) {
  _self.input.total_duration()
}

///|
pub impl Source for BltFilter with try_seek(
  _self : BltFilter,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
}

///|
pub impl Source for WhiteUniform with current_span_len(_self : WhiteUniform) {
  source_default_current_span_len()
}

///|
pub impl Source for WhiteUniform with total_duration(_self : WhiteUniform) {
  source_default_total_duration()
}

///|
pub impl Source for WhiteUniform with try_seek(
  _self : WhiteUniform,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for Pink with current_span_len(_self : Pink) {
  source_default_current_span_len()
}

///|
pub impl Source for Pink with total_duration(_self : Pink) {
  source_default_total_duration()
}

///|
pub impl Source for Pink with try_seek(_self : Pink, pos : @moon_cpal.Duration) -> Unit raise SeekError {
  ignore(pos)
}

///|
pub impl Source for WhiteTriangular with current_span_len(
  _self : WhiteTriangular,
) {
  source_default_current_span_len()
}

///|
pub impl Source for WhiteTriangular with total_duration(_self : WhiteTriangular) {
  source_default_total_duration()
}

///|
pub impl Source for WhiteTriangular with try_seek(
  _self : WhiteTriangular,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for WhiteGaussian with current_span_len(_self : WhiteGaussian) {
  source_default_current_span_len()
}

///|
pub impl Source for WhiteGaussian with total_duration(_self : WhiteGaussian) {
  source_default_total_duration()
}

///|
pub impl Source for WhiteGaussian with try_seek(
  _self : WhiteGaussian,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for Velvet with current_span_len(_self : Velvet) {
  source_default_current_span_len()
}

///|
pub impl Source for Velvet with total_duration(_self : Velvet) {
  source_default_total_duration()
}

///|
pub impl Source for Velvet with try_seek(
  _self : Velvet,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for Blue with current_span_len(_self : Blue) {
  source_default_current_span_len()
}

///|
pub impl Source for Blue with total_duration(_self : Blue) {
  source_default_total_duration()
}

///|
pub impl Source for Blue with try_seek(_self : Blue, pos : @moon_cpal.Duration) -> Unit raise SeekError {
  ignore(pos)
}

///|
pub impl Source for Violet with current_span_len(_self : Violet) {
  source_default_current_span_len()
}

///|
pub impl Source for Violet with total_duration(_self : Violet) {
  source_default_total_duration()
}

///|
pub impl Source for Violet with try_seek(
  _self : Violet,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for Brownian with current_span_len(_self : Brownian) {
  source_default_current_span_len()
}

///|
pub impl Source for Brownian with total_duration(_self : Brownian) {
  source_default_total_duration()
}

///|
pub impl Source for Brownian with try_seek(
  _self : Brownian,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  ()
}

///|
pub impl Source for Red with current_span_len(_self : Red) {
  source_default_current_span_len()
}

///|
pub impl Source for Red with total_duration(_self : Red) {
  source_default_total_duration()
}

///|
pub impl Source for Red with try_seek(_self : Red, _pos : @moon_cpal.Duration) -> Unit raise SeekError {
  ()
}
