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
pub type AutomaticGainControl = @Milky2018/moon_rodio.AutomaticGainControl

///|
pub type AutomaticGainControlSettings = @Milky2018/moon_rodio.AutomaticGainControlSettings

///|
pub fn[S : @Milky2018/moon_rodio.Source] automatic_gain_control(
  source : S,
  settings : AutomaticGainControlSettings,
) -> AutomaticGainControl {
  @Milky2018/moon_rodio.automatic_gain_control(source, settings)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] automatic_gain_control_with_params(
  source : S,
  target_level : Double,
  attack : @moon_cpal.Duration,
  release : @moon_cpal.Duration,
  absolute_max_gain : Double,
) -> AutomaticGainControl {
  @Milky2018/moon_rodio.automatic_gain_control_with_params(
    source, target_level, attack, release, absolute_max_gain,
  )
}
