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
test "rodio::source::limit::aliases" {
  let settings = LimitSettings::default().with_threshold(-6.0)
  let src = @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [
    1.2, -1.1, 0.4, -0.2,
  ])
  let out = limit(src, settings)
  assert_eq(out.channels(), 1)
  assert_eq(out.sample_rate(), 8)
  assert_true(out.next() != None)

  let ranged = limit_range(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [2.0, -2.0]),
    -0.5,
    0.5,
  )
  assert_eq(ranged.channels(), 1)
  assert_eq(ranged.sample_rate(), 8)
  assert_true(ranged.next() != None)

  let mono = LimitMono::new(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0]),
    LimitSettings::default(),
  )
  assert_eq(mono.channels(), 1)
}
