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
fn[S : Source] collect_n_conv(source : S, n : Int) -> Array[Sample] {
  let out : Array[Sample] = []
  for _ in 0..<n {
    match source.next() {
      None => break
      Some(v) => out.push(v)
    }
  }
  out
}

///|
test "rodio::conversions::convert_channels" {
  let src = SamplesBuffer::new(1, 48_000, [1.0, -2.0])
  let out = convert_channels(src, 2)
  assert_eq(out.channels(), 2)
  assert_eq(collect_n_conv(out, 6), [1.0, 1.0, -2.0, -2.0])

  let remove_3_to_2 = convert_channels(
    SamplesBuffer::new(3, 48_000, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
    2,
  )
  assert_eq(collect_n_conv(remove_3_to_2, 16), [1.0, 2.0, 4.0, 5.0])

  let remove_4_to_1 = convert_channels(
    SamplesBuffer::new(4, 48_000, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    1,
  )
  assert_eq(collect_n_conv(remove_4_to_1, 16), [1.0, 5.0])

  let add_1_to_4 = convert_channels(
    SamplesBuffer::new(1, 48_000, [1.0, 2.0]),
    4,
  )
  assert_eq(collect_n_conv(add_1_to_4, 16), [
    1.0, 1.0, 0.0, 0.0, 2.0, 2.0, 0.0, 0.0,
  ])

  let add_2_to_4 = convert_channels(
    SamplesBuffer::new(2, 48_000, [1.0, 2.0, 3.0, 4.0]),
    4,
  )
  assert_eq(collect_n_conv(add_2_to_4, 16), [
    1.0, 2.0, 0.0, 0.0, 3.0, 4.0, 0.0, 0.0,
  ])
}

///|
test "rodio::conversions::convert_sample_rate" {
  let src = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let out = convert_sample_rate(src, 4)
  assert_eq(out.sample_rate(), 4)
  // Linear interpolation at x=[0,0.5,1,1.5,2]
  let vals = collect_n_conv(out, 5)
  assert_eq(vals[0], 0.0)
  assert_true(vals[1] > 0.99 && vals[1] < 1.01)
  assert_eq(vals[2], 2.0)
  assert_true(vals[3] > 2.99 && vals[3] < 3.01)
  assert_eq(vals[4], 4.0)
}

///|
test "rodio::conversions::uniform" {
  let src = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let out = uniform(src, 2, 4)
  assert_eq(out.channels(), 2)
  assert_eq(out.sample_rate(), 4)
  let vals = collect_n_conv(out, 10)
  assert_eq(vals[0], 0.0)
  assert_eq(vals[1], 0.0)
  assert_true(vals[2] > 0.99 && vals[2] < 1.01)
  assert_true(vals[3] > 0.99 && vals[3] < 1.01)
}

///|
test "rodio::conversions::convert_channels_length_behavior" {
  let len_more = collect_n_conv(
    convert_channels(SamplesBuffer::new(2, 48_000, [1.0, 2.0, 3.0, 4.0]), 3),
    64,
  )
  assert_eq(len_more.length(), 6)

  let len_less = collect_n_conv(
    convert_channels(SamplesBuffer::new(2, 48_000, [1.0, 2.0, 3.0, 4.0]), 1),
    64,
  )
  assert_eq(len_less.length(), 2)
}
