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
pub type Zero = @Milky2018/moon_rodio.Zero

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn zero(channels : Int, sample_rate : Int) -> DynSource {
  @Milky2018/moon_rodio.zero(channels, sample_rate)
}

///|
pub fn zero_samples(
  channels : Int,
  sample_rate : Int,
  count : Int,
) -> DynSource {
  @Milky2018/moon_rodio.zero_samples(channels, sample_rate, count)
}
