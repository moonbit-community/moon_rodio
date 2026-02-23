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
test "rodio::source::periodic::aliases" {
  let p1 = periodic_access(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 2.0, 3.0]),
    2,
    fn() {  },
  )
  assert_eq(p1.channels(), 1)
  assert_eq(p1.sample_rate(), 8)
  assert_eq(p1.next(), Some(1.0))
  assert_eq(p1.next(), Some(2.0))

  let p2 = periodic_access_with_source(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 2.0]),
    1,
    fn(_ : DynSource) {  },
  )
  assert_eq(p2.channels(), 1)
  assert_eq(p2.sample_rate(), 8)
  assert_true(p2.next() != None)

  let p3 = periodic(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 2.0]),
    @moon_cpal.Duration::new((0 : UInt64), 100_000_000),
    fn() {  },
  )
  assert_eq(p3.channels(), 1)
  assert_eq(p3.sample_rate(), 8)
  assert_true(p3.next() != None)
}
