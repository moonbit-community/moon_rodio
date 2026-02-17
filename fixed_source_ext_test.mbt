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
test "rodio::fixed_source::adapter_from_samples_buffer" {
  let adapted = FixedSourceAdapter::new(
    FixedSamplesBuffer::new(1, 48_000, [1.0, 2.0, 3.0]),
  )
  assert_eq(adapted.channels(), 1)
  assert_eq(adapted.sample_rate(), 48_000)
  assert_eq(adapted.next(), Some(1.0))
  assert_eq(adapted.next(), Some(2.0))
  assert_eq(adapted.next(), Some(3.0))
  assert_eq(adapted.next(), None)
}

///|
test "rodio::fixed_source::adapter_uses_inner_duration" {
  let adapted = FixedSourceAdapter::new(
    FixedSamplesBuffer::new(2, 2, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
  )
  let d = adapted.total_duration().unwrap()
  assert_eq(d.secs, (1 : UInt64))
  assert_eq(d.nanos, 500_000_000)
}

///|
test "rodio::fixed_source::adapter_seek_not_supported" {
  let adapted = FixedSourceAdapter::new(
    FixedSamplesBuffer::new(1, 44_100, [1.0]),
  )
  let got_not_supported = try {
    adapted.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(got_not_supported)
}
