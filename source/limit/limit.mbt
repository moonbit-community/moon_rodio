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
pub type Limit = @Milky2018/moon_rodio.Limit

///|
pub type LimitMono = @Milky2018/moon_rodio.LimitMono

///|
pub type LimitStereo = @Milky2018/moon_rodio.LimitStereo

///|
pub type LimitMulti = @Milky2018/moon_rodio.LimitMulti

///|
pub type LimitSettings = @Milky2018/moon_rodio.LimitSettings

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] limit(
  source : S,
  settings : LimitSettings,
) -> DynSource {
  @Milky2018/moon_rodio.limit(source, settings)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] limit_range(
  source : S,
  min_value : Double,
  max_value : Double,
) -> DynSource {
  @Milky2018/moon_rodio.limit_range(source, min_value, max_value)
}
