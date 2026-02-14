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
  let (sink, src) = Sink::new()
  assert_eq(sink.len(), 0)
  sink.append(SamplesBuffer::new(1, 1, [1.0]))
  assert_eq(sink.len(), 1)
  ignore(src.next())
  assert_eq(sink.len(), 0)
}

///|
test "rodio::sink::tests::speed" {
  let (sink, queue_rx) = Sink::new()
  sink.set_speed(2.0)
  assert_eq(sink.speed(), 2.0)
  sink.append(SamplesBuffer::new(1, 10, [1.0, 2.0]))
  assert_eq(queue_rx.sample_rate(), 20)
}

///|
test "rodio::sink::tests::skip_one" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 1, [1.0, 2.0]))
  sink.append(SamplesBuffer::new(1, 1, [10.0, 20.0]))

  assert_eq(queue_rx.next(), Some(1.0))
  sink.skip_one()
  assert_eq(queue_rx.next(), Some(10.0))
}

///|
test "rodio::sink::tests::get_pos_and_try_seek" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]))

  ignore(queue_rx.next())
  ignore(queue_rx.next())
  ignore(queue_rx.next())
  assert_eq(sink.get_pos().secs, (0 : UInt64))

  ignore(queue_rx.next())
  assert_eq(sink.get_pos().secs, (1 : UInt64))

  let err = try {
    sink.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
    panic()
  } catch {
    e => e
  }
  assert_true(err is SeekError::NotSupported)
  assert_true(err.source_intact())
}

///|
test "rodio::stream::builder::with_config" {
  let cfg = @moon_cpal.StreamConfig::new(
    1,
    22_050,
    @moon_cpal.BufferSize::fixed(512),
  )
  let builder = OutputStreamBuilder::default().with_config(cfg)
  assert_eq(builder.config.channel_count, 1)
  assert_eq(builder.config.sample_rate, 22_050)
  assert_eq(builder.config.buffer_size, @moon_cpal.BufferSize::fixed(512))
}
