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
pub type Builder = @Milky2018/moon_rodio.MicrophoneBuilder

///|
pub type MicrophoneBuilder = @Milky2018/moon_rodio.MicrophoneBuilder

///|
pub type BuilderError = @Milky2018/moon_rodio.MicrophoneError

///|
pub type DeviceIsSet = @Milky2018/moon_rodio/microphone.DeviceIsSet

///|
pub type DeviceNotSet = @Milky2018/moon_rodio/microphone.DeviceNotSet

///|
pub type ConfigIsSet = @Milky2018/moon_rodio/microphone.ConfigIsSet

///|
pub type ConfigNotSet = @Milky2018/moon_rodio/microphone.ConfigNotSet

///|
pub fn new() -> Builder {
  @Milky2018/moon_rodio.MicrophoneBuilder::new()
}
