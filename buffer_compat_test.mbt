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
test "rodio::buffer::static_samples_buffer" {
  let s = StaticSamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 44_100)
  assert_eq(s.next(), Some(1.0))
  assert_eq(s.next(), Some(2.0))
  assert_eq(s.next(), Some(3.0))
  assert_eq(s.next(), None)
}

///|
test "rodio::buffer::from_iter" {
  let s = buffer_from_iter(1, 44_100, [1.0, 2.0])
  assert_eq(s.next(), Some(1.0))
  assert_eq(s.next(), Some(2.0))
  assert_eq(s.next(), None)
}

///|
test "rodio::buffer::static_samples_buffer_seek_not_supported" {
  let s = StaticSamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  let not_supported = try {
    s.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(not_supported)
}

///|
test "rodio::buffer::static_samples_buffer_current_span_len_none" {
  let s = StaticSamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  assert_eq(s.current_span_len(), None)
}
