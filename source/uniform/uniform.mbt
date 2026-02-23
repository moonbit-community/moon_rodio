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
pub type UniformSourceIterator = @Milky2018/moon_rodio.UniformSourceIterator

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] uniform(
  source : S,
  target_channels : Int,
  target_sample_rate : Int,
) -> DynSource {
  @Milky2018/moon_rodio.uniform(source, target_channels, target_sample_rate)
}
