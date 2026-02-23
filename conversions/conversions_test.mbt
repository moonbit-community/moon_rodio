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
test "rodio::conversions::aliases" {
  let source1 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [
    1.0, 2.0, 3.0, 4.0,
  ])
  let cc = new_channel_count_converter(source1, 1, 2)
  assert_eq(cc.channels(), 2)
  assert_eq(cc.sample_rate(), 4)
  assert_true(cc.next() != None)

  let source2 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [
    1.0, 2.0, 3.0, 4.0,
  ])
  let sr = new_sample_rate_converter(source2, 4, 8, 1)
  assert_eq(sr.channels(), 1)
  assert_eq(sr.sample_rate(), 8)
  assert_true(sr.next() != None)

  let source3 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [1.0, 2.0])
  let st = new_sample_type_converter(source3)
  assert_eq(st.channels(), 1)
  assert_eq(st.sample_rate(), 4)
  assert_true(st.next() != None)

  let source4 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [1.0, 2.0])
  let d1 = convert_channels(source4, 2)
  assert_eq(d1.channels(), 2)
  assert_eq(d1.sample_rate(), 4)

  let source5 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [1.0, 2.0])
  let d2 = convert_sample_rate(source5, 8)
  assert_eq(d2.channels(), 1)
  assert_eq(d2.sample_rate(), 8)

  let source6 = @Milky2018/moon_rodio.SamplesBuffer::new(1, 4, [1.0, 2.0])
  let d3 = uniform(source6, 2, 8)
  assert_eq(d3.channels(), 2)
  assert_eq(d3.sample_rate(), 8)
}
