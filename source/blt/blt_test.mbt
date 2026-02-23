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
test "rodio::source::blt::aliases" {
  let lp = low_pass(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8_000, [1.0, 0.0, -1.0, 0.0]),
    1_000,
  )
  assert_eq(lp.channels(), 1)
  assert_eq(lp.sample_rate(), 8_000)
  assert_true(lp.next() != None)

  let hp = high_pass(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8_000, [1.0, 0.0, -1.0, 0.0]),
    500,
  )
  assert_eq(hp.channels(), 1)
  assert_true(hp.next() != None)

  let lpq = low_pass_with_q(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8_000, [0.2, 0.3]),
    700,
    0.8,
  )
  assert_eq(lpq.channels(), 1)

  let hpq = high_pass_with_q(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8_000, [0.2, 0.3]),
    700,
    0.8,
  )
  assert_eq(hpq.channels(), 1)
}
