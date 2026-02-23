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
test "rodio::source::channel_volume::aliases" {
  let cv = channel_volume(
    @Milky2018/moon_rodio.SamplesBuffer::new(2, 8, [0.5, 1.0, 0.5, 1.0]),
    [0.5, 1.0],
  )
  assert_eq(cv.channels(), 2)
  assert_eq(cv.sample_rate(), 8)
  assert_true(cv.next() != None)
}
