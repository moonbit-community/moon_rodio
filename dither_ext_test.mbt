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
test "rodio::source::dither::bit_depth_new" {
  let b16 = BitDepth::new(16)
  assert_eq(b16.get(), 16)

  let invalid = try {
    ignore(BitDepth::new(0))
    false
  } catch {
    BitDepthError::OutOfRange(0) => true
    _ => false
  }
  assert_true(invalid)
}

///|
test "rodio::source::dither::adds_small_noise" {
  let bits = BitDepth::new(16)
  let d = dither(
    SamplesBuffer::new(1, 44_100, [0.25, 0.25, 0.25, 0.25]),
    bits,
    DitherAlgorithm::rpdf(),
  )
  let lsb = 1.0 / 32768.0
  let mut saw_non_zero = false
  for _ in 0..<4 {
    let out = d.next().unwrap()
    let diff = (out - 0.25).abs()
    assert_true(diff <= lsb * 2.0 + 1.0e-12)
    if diff > 0.0 {
      saw_non_zero = true
    }
  }
  assert_true(saw_non_zero)
}

///|
test "rodio::source::dither::algorithm_switch_and_forwarding" {
  let bits = BitDepth::new(16)
  let d = dither(
    SamplesBuffer::new(2, 2, [1.0, 2.0, 3.0, 4.0]),
    bits,
    DitherAlgorithm::tpdf(),
  )
  assert_eq(d.algorithm(), DitherAlgorithm::tpdf())
  d.set_algorithm(DitherAlgorithm::high_pass())
  assert_eq(d.algorithm(), DitherAlgorithm::high_pass())

  assert_eq(d.channels(), 2)
  assert_eq(d.sample_rate(), 2)
  let dur = d.total_duration().unwrap()
  assert_eq(dur.secs, (1 : UInt64))
  assert_eq(dur.nanos, 0)
}

///|
test "rodio::source::dither::seek_forwarding" {
  let bits = BitDepth::new(16)
  let d = dither(
    SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]),
    bits,
    DitherAlgorithm::gpdf(),
  )
  d.try_seek(@moon_cpal.Duration::new((3 : UInt64), 0))
  assert_eq(d.next(), None)
}
