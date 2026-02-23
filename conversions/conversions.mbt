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
pub type ChannelCountConverter = @Milky2018/moon_rodio.ChannelCountConverter

///|
pub type SampleRateConverter = @Milky2018/moon_rodio.SampleRateConverter

///|
pub type SampleTypeConverter = @Milky2018/moon_rodio.SampleTypeConverter

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] convert_channels(
  source : S,
  target_channels : Int,
) -> DynSource {
  @Milky2018/moon_rodio.convert_channels(source, target_channels)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] convert_sample_rate(
  source : S,
  target_sample_rate : Int,
) -> DynSource {
  @Milky2018/moon_rodio.convert_sample_rate(source, target_sample_rate)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] uniform(
  source : S,
  target_channels : Int,
  target_sample_rate : Int,
) -> DynSource {
  @Milky2018/moon_rodio.uniform(source, target_channels, target_sample_rate)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] new_channel_count_converter(
  input : S,
  from : Int,
  to : Int,
) -> ChannelCountConverter {
  @Milky2018/moon_rodio.ChannelCountConverter::new(input, from, to)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] new_sample_rate_converter(
  input : S,
  from : Int,
  to : Int,
  num_channels : Int,
) -> SampleRateConverter {
  @Milky2018/moon_rodio.SampleRateConverter::new(input, from, to, num_channels)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] new_sample_type_converter(
  input : S,
) -> SampleTypeConverter {
  @Milky2018/moon_rodio.SampleTypeConverter::new(input)
}
