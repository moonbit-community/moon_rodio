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
pub type DeviceSinkConfig = @Milky2018/moon_rodio.DeviceSinkConfig

///|
pub type DeviceSinkBuilder = @Milky2018/moon_rodio.DeviceSinkBuilder

///|
pub type DeviceSinkError = @Milky2018/moon_rodio.DeviceSinkError

///|
pub type MixerDeviceSink = @Milky2018/moon_rodio.MixerDeviceSink

///|
pub type PlayError = @Milky2018/moon_rodio.PlayError

///|
pub type Reader = @Milky2018/moon_rodio.Reader

///|
pub type Player = @Milky2018/moon_rodio.Player

///|
pub fn play(
  mixer : @Milky2018/moon_rodio.Mixer,
  reader : Reader,
) -> Player raise PlayError {
  @Milky2018/moon_rodio.play(mixer, reader)
}

///|
pub fn play_reader(
  mixer : @Milky2018/moon_rodio.Mixer,
  reader : Reader,
) -> Player raise PlayError {
  @Milky2018/moon_rodio.play_reader(mixer, reader)
}

///|
pub fn play_file(
  mixer : @Milky2018/moon_rodio.Mixer,
  path : StringView,
) -> Player raise PlayError {
  @Milky2018/moon_rodio.play_file(mixer, path)
}

///|
pub fn supported_output_configs(
  device : @moon_cpal.Device,
) -> Array[@moon_cpal.SupportedStreamConfig] raise DeviceSinkError {
  @Milky2018/moon_rodio.supported_output_configs(device)
}
