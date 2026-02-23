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
pub suberror BitDepthError {
  OutOfRange(Int)
} derive(Show, Eq)

///|
pub struct BitDepth {
  bits : Int
} derive(Show, Eq)

///|
pub fn BitDepth::new(bits : Int) -> BitDepth raise BitDepthError {
  if bits <= 0 || bits > 64 {
    raise BitDepthError::OutOfRange(bits)
  }
  { bits, }
}

///|
pub fn BitDepth::get(self : BitDepth) -> Int {
  self.bits
}

///|
pub enum DitherAlgorithm {
  GPDF
  HighPass
  RPDF
  TPDF
} derive(Show, Eq)

///|
pub fn DitherAlgorithm::gpdf() -> DitherAlgorithm {
  DitherAlgorithm::GPDF
}

///|
pub fn DitherAlgorithm::high_pass() -> DitherAlgorithm {
  DitherAlgorithm::HighPass
}

///|
pub fn DitherAlgorithm::rpdf() -> DitherAlgorithm {
  DitherAlgorithm::RPDF
}

///|
pub fn DitherAlgorithm::tpdf() -> DitherAlgorithm {
  DitherAlgorithm::TPDF
}

///|
pub struct Dither {
  input : DynSource
  noise : Ref[DitherAlgorithm]
  current_channel : Ref[Int]
  lsb_amplitude : Ref[Sample]
  rng_state : Ref[UInt64]
  highpass_prev : Ref[Array[Sample]]
}

///|
fn dither_rand_next(state : Ref[UInt64]) -> UInt64 {
  let mut x = state.val
  x = x ^ (x >> 12)
  x = x ^ (x << 25)
  x = x ^ (x >> 27)
  state.val = x
  x * (2685821657736338717 : UInt64)
}

///|
fn dither_rand_unit(state : Ref[UInt64]) -> Sample {
  let x = dither_rand_next(state)
  Double::from_int((x & (0x7fff_ffff : UInt64)).to_int()) / 2147483647.0
}

///|
fn ensure_highpass_state(d : Dither, channels : Int) -> Unit {
  if channels <= 0 {
    return
  }
  if d.highpass_prev.val.length() == channels {
    return
  }
  d.highpass_prev.val = Array::make(channels, 0.0)
  d.current_channel.val = 0
}

///|
fn dither_noise_sample(d : Dither, channels : Int) -> Sample {
  let channel = if channels <= 0 { 0 } else { d.current_channel.val % channels }
  let noise = match d.noise.val {
    DitherAlgorithm::RPDF => dither_rand_unit(d.rng_state) * 2.0 - 1.0
    DitherAlgorithm::TPDF =>
      dither_rand_unit(d.rng_state) - dither_rand_unit(d.rng_state)
    DitherAlgorithm::GPDF => {
      let mut sum = 0.0
      for _ in 0..<6 {
        sum += dither_rand_unit(d.rng_state)
      }
      (sum - 3.0) / 3.0
    }
    DitherAlgorithm::HighPass => {
      ensure_highpass_state(d, channels)
      let white = dither_rand_unit(d.rng_state) * 2.0 - 1.0
      let out = white - d.highpass_prev.val[channel]
      d.highpass_prev.val[channel] = white
      out
    }
  }
  if channels > 0 {
    d.current_channel.val = (channel + 1) % channels
  }
  noise
}

///|
fn bit_depth_lsb_amplitude(bits : BitDepth) -> Sample {
  1.0 / @math.pow(2.0, Double::from_int(bits.get() - 1))
}

///|
pub fn[S : Source] dither(
  source : S,
  target_bits : BitDepth,
  algorithm : DitherAlgorithm,
) -> Dither {
  let dyn_src = to_dyn(source)
  {
    input: dyn_src,
    noise: @ref.new(algorithm),
    current_channel: @ref.new(0),
    lsb_amplitude: @ref.new(bit_depth_lsb_amplitude(target_bits)),
    rng_state: @ref.new((0x9E3779B97F4A7C15 : UInt64)),
    highpass_prev: @ref.new(
      Array::make(
        if dyn_src.channels() > 0 {
          dyn_src.channels()
        } else {
          1
        },
        0.0,
      ),
    ),
  }
}

///|
pub fn Dither::set_algorithm(
  self : Dither,
  algorithm : DitherAlgorithm,
) -> Unit {
  self.noise.val = algorithm
  if algorithm == DitherAlgorithm::HighPass {
    ensure_highpass_state(self, self.input.channels())
  }
}

///|
pub fn Dither::algorithm(self : Dither) -> DitherAlgorithm {
  self.noise.val
}

///|
pub fn Dither::next(self : Dither) -> Sample? {
  match self.input.next() {
    None => None
    Some(v) => {
      let channels = self.input.channels()
      let noise = dither_noise_sample(self, channels)
      Some(v - noise * self.lsb_amplitude.val)
    }
  }
}

///|
pub fn Dither::channels(self : Dither) -> ChannelCount {
  self.input.channels()
}

///|
pub fn Dither::sample_rate(self : Dither) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for Dither with next(self : Dither) {
  self.next()
}

///|
pub impl Source for Dither with channels(self : Dither) {
  self.channels()
}

///|
pub impl Source for Dither with sample_rate(self : Dither) {
  self.sample_rate()
}

///|
pub impl Source for Dither with current_span_len(self : Dither) {
  self.input.current_span_len()
}

///|
pub impl Source for Dither with total_duration(self : Dither) {
  self.input.total_duration()
}

///|
pub impl Source for Dither with try_seek(
  self : Dither,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.current_channel.val = 0
  if self.noise.val == DitherAlgorithm::HighPass {
    ensure_highpass_state(self, self.input.channels())
    for i in 0..<self.highpass_prev.val.length() {
      self.highpass_prev.val[i] = 0.0
    }
  }
  self.input.try_seek(pos)
}
