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
test "rodio::microphone::builder::aliases" {
  let b0 = new()
  let b1 : Builder = b0
  let b2 : MicrophoneBuilder = b1
  let b3 = MicrophoneBuilder::new()
  let b4 : Builder = b3
  let e : BuilderError? = None
  let _root_e : @Milky2018/moon_rodio.MicrophoneError? = e

  let _ : DeviceIsSet? = None
  let _ : DeviceNotSet? = None
  let _ : ConfigIsSet? = None
  let _ : ConfigNotSet? = None

  let no_config = try {
    ignore(b2.get_config())
    false
  } catch {
    _ => true
  }
  assert_true(no_config)
  let no_config_b4 = try {
    ignore(b4.get_config())
    false
  } catch {
    _ => true
  }
  assert_true(no_config_b4)
}
