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
test "rodio::mixer::aliases" {
  let (tx, rx) = mixer(1, 8)
  tx.add(@Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 2.0]))
  tx.add(@Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.5, 0.25]))
  assert_eq(rx.channels(), 1)
  assert_eq(rx.sample_rate(), 8)
  assert_eq(rx.next(), Some(1.5))
  assert_eq(rx.next(), Some(2.25))
  assert_eq(rx.next(), None)
}
