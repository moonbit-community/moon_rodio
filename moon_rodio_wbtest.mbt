///|
test "rodio::sink::tests::test_pause_and_stop" {
  let (sink, source) = Sink::new()

  assert_eq(source.next(), Some(0.0))

  let v = [10.0, -10.0, 20.0, -20.0, 30.0, -30.0]

  sink.append(SamplesBuffer::new(1, 1, v))
  assert_eq(source.next(), Some(10.0))
  assert_eq(source.next(), Some(-10.0))

  sink.pause()
  assert_eq(source.next(), Some(0.0))

  sink.play()
  assert_eq(source.next(), Some(20.0))
  assert_eq(source.next(), Some(-20.0))

  sink.stop()
  assert_eq(source.next(), Some(0.0))
  assert_true(sink.empty())
}

///|
test "rodio::sink::tests::test_stop_and_start" {
  let (sink, queue_rx) = Sink::new()

  let v = [10.0, -10.0, 20.0, -20.0, 30.0, -30.0]

  sink.append(SamplesBuffer::new(1, 1, v))

  assert_eq(queue_rx.next(), Some(10.0))
  assert_eq(queue_rx.next(), Some(-10.0))

  sink.stop()
  assert_eq(queue_rx.next(), Some(0.0))

  sink.append(SamplesBuffer::new(1, 1, v))
  assert_eq(queue_rx.next(), Some(10.0))
}

///|
test "rodio::sink::tests::test_volume" {
  let (sink, queue_rx) = Sink::new()

  let v = [10.0, -10.0, 20.0, -20.0, 30.0, -30.0]
  sink.append(SamplesBuffer::new(2, 44_100, v))

  sink.set_volume(0.5)

  assert_eq(queue_rx.next(), Some(5.0))
  assert_eq(queue_rx.next(), Some(-5.0))
  assert_eq(queue_rx.next(), Some(10.0))
  assert_eq(queue_rx.next(), Some(-10.0))
}

///|
test "rodio::sink::tests::len" {
  let (sink, _) = Sink::new()
  assert_eq(sink.len(), 0)
  sink.append(SamplesBuffer::new(1, 1, [1.0]))
  assert_eq(sink.len(), 1)
}

///|
test "rodio::sink::tests::speed" {
  let (sink, queue_rx) = Sink::new()
  sink.set_speed(2.0)
  assert_eq(sink.speed(), 2.0)
  sink.append(SamplesBuffer::new(1, 10, [1.0, 2.0]))
  assert_eq(queue_rx.sample_rate(), 20)
}
