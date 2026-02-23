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
test "rodio::buffer::new_and_record_source_aliases" {
  let b = new(2, 4, [1.0, 2.0, 3.0, 4.0])
  assert_eq(b.channels(), 2)
  assert_eq(b.sample_rate(), 4)
  assert_eq(b.next(), Some(1.0))

  let recorded = record_source(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [9.0, 8.0]),
  )
  assert_eq(recorded.channels(), 1)
  assert_eq(recorded.sample_rate(), 8)
  assert_eq(recorded.next(), Some(9.0))
  assert_eq(recorded.next(), Some(8.0))
  assert_eq(recorded.next(), None)
}
