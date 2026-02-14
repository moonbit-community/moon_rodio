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
  let s = from_iter(1, 44_100, [1.0, 2.0])
  assert_eq(s.next(), Some(1.0))
  assert_eq(s.next(), Some(2.0))
  assert_eq(s.next(), None)
}
