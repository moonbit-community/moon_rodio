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
pub type LinearGainRamp = @Milky2018/moon_rodio.LinearGainRamp

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] linear_gain_ramp(
  source : S,
  start_gain : Double,
  end_gain : Double,
  duration : @moon_cpal.Duration,
) -> DynSource {
  @Milky2018/moon_rodio.linear_gain_ramp(source, start_gain, end_gain, duration)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] linear_gain_ramp_with_clamp(
  source : S,
  start_gain : Double,
  end_gain : Double,
  duration : @moon_cpal.Duration,
  clamp_negative : Bool,
) -> DynSource {
  @Milky2018/moon_rodio.linear_gain_ramp_with_clamp(
    source, start_gain, end_gain, duration, clamp_negative,
  )
}
