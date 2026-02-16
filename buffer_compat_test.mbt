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
