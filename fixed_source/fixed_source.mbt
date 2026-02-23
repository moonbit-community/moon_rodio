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
pub type FixedSourceAdapter = @Milky2018/moon_rodio.FixedSourceAdapter

///|
pub type FixedSamplesBuffer = @Milky2018/moon_rodio.FixedSamplesBuffer

///|
pub fn[S : @Milky2018/moon_rodio.FixedSource] adapt(
  source : S,
) -> FixedSourceAdapter {
  @Milky2018/moon_rodio.FixedSourceAdapter::new(source)
}

///|
pub fn new_samples_buffer(
  channels : Int,
  sample_rate : Int,
  samples : Array[Double],
) -> FixedSamplesBuffer {
  @Milky2018/moon_rodio.FixedSamplesBuffer::new(channels, sample_rate, samples)
}
