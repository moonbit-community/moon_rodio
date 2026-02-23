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
pub type FadeOut = @Milky2018/moon_rodio.FadeOut

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] fadeout(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  @Milky2018/moon_rodio.fadeout(source, duration)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] fade_out(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  @Milky2018/moon_rodio.fade_out(source, duration)
}
