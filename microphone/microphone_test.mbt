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
test "rodio::microphone::alias_error_types" {
  let err : OpenError? = None
  let open_err : OpenError? = None
  let list_err : ListError? = None

  let root_err : @Milky2018/moon_rodio.MicrophoneError? = err
  let root_open_err : @Milky2018/moon_rodio.MicrophoneError? = open_err
  let root_list_err : @Milky2018/moon_rodio.MicrophoneListError? = list_err

  assert_eq(root_err, None)
  assert_eq(root_open_err, None)
  assert_eq(root_list_err, None)
}

///|
test "rodio::microphone::marker_types_constructible" {
  let _ : DeviceIsSet? = None
  let _ : DeviceNotSet? = None
  let _ : ConfigIsSet? = None
  let _ : ConfigNotSet? = None
}

///|
test "rodio::microphone::builder_new_alias" {
  let builder = new_builder()
  let _ = builder
}
