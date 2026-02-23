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
pub type Crossfade = @Milky2018/moon_rodio.Crossfade

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[A : @Milky2018/moon_rodio.Source, B : @Milky2018/moon_rodio.Source] crossfade(
  first : A,
  second : B,
  duration : @moon_cpal.Duration,
) -> DynSource {
  @Milky2018/moon_rodio.crossfade(first, second, duration)
}

///|
pub fn[A : @Milky2018/moon_rodio.Source, B : @Milky2018/moon_rodio.Source] take_crossfade_with(
  first : A,
  second : B,
  duration : @moon_cpal.Duration,
) -> DynSource {
  @Milky2018/moon_rodio.take_crossfade_with(first, second, duration)
}
