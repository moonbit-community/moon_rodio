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
test "rodio::source::position::aliases" {
  let t = track_position(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0]),
  )
  assert_eq(t.channels(), 1)
  assert_eq(t.sample_rate(), 2)
  assert_eq(t.get_pos().secs, (0 : UInt64))
  assert_eq(t.next(), Some(1.0))
  assert_eq(t.next(), Some(2.0))
  let pos = t.get_pos()
  assert_true(pos.secs > (0 : UInt64) || pos.nanos > 0)
}
