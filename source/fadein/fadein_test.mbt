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
test "rodio::source::fadein::aliases" {
  let a = fadein(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.1, 0.2]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(a.channels(), 1)
  assert_eq(a.sample_rate(), 8)
  assert_true(a.next() != None)

  let b = fade_in(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.1, 0.2]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(b.channels(), 1)
  assert_true(b.next() != None)
}
