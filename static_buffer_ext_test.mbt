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
test "rodio::static_buffer::basic" {
  let _ = StaticSamplesBuffer::new(1, 44_100, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
}

///|
test "rodio::static_buffer::duration_basic" {
  let buf = StaticSamplesBuffer::new(2, 2, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
  let dur = buf.total_duration().unwrap()
  assert_eq(dur.secs, (1 : UInt64))
  assert_eq(dur.nanos, 500_000_000)
}

///|
test "rodio::static_buffer::iteration" {
  let buf = StaticSamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
  assert_eq(buf.next(), Some(1.0))
  assert_eq(buf.next(), Some(2.0))
  assert_eq(buf.next(), Some(3.0))
  assert_eq(buf.next(), Some(4.0))
  assert_eq(buf.next(), Some(5.0))
  assert_eq(buf.next(), Some(6.0))
  assert_eq(buf.next(), None)
}

///|
test "rodio::static_buffer::seek_not_supported" {
  let buf = StaticSamplesBuffer::new(1, 44_100, [1.0])
  let got_not_supported = try {
    buf.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(got_not_supported)
}
