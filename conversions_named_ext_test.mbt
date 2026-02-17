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
fn[S : Source] collect_n_conv_named(source : S, n : Int) -> Array[Sample] {
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
test "rodio::conversions::channel_count_converter" {
  let src = SamplesBuffer::new(1, 48_000, [1.0, -2.0])
  let out = ChannelCountConverter::new(src, 1, 2)
  assert_eq(out.channels(), 2)
  assert_eq(collect_n_conv_named(out, 6), [1.0, 1.0, -2.0, -2.0])
}

///|
test "rodio::conversions::sample_rate_converter" {
  let src = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let out = SampleRateConverter::new(src, 2, 4, 1)
  assert_eq(out.sample_rate(), 4)
  let vals = collect_n_conv_named(out, 5)
  assert_eq(vals[0], 0.0)
  assert_true(vals[1] > 0.99 && vals[1] < 1.01)
  assert_eq(vals[2], 2.0)
}

///|
test "rodio::conversions::sample_type_converter" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, 2.0])
  let out = SampleTypeConverter::new(src)
  assert_eq(out.channels(), 1)
  assert_eq(out.sample_rate(), 44_100)
  assert_eq(collect_n_conv_named(out, 10), [1.0, 2.0])
}
