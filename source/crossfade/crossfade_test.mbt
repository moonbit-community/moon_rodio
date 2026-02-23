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
test "rodio::source::crossfade::aliases" {
  let a = @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 1.0, 1.0, 1.0])
  let b = @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.0, 0.0, 0.0, 0.0])
  let x = crossfade(a, b, @moon_cpal.Duration::new((0 : UInt64), 250_000_000))
  assert_eq(x.channels(), 1)
  assert_eq(x.sample_rate(), 8)
  assert_true(x.next() != None)

  let y = take_crossfade_with(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 1.0, 1.0, 1.0]),
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.0, 0.0, 0.0, 0.0]),
    @moon_cpal.Duration::new((0 : UInt64), 250_000_000),
  )
  assert_eq(y.channels(), 1)
  assert_eq(y.sample_rate(), 8)
  assert_true(y.next() != None)
}
