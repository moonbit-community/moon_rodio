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
test "rodio::sink::tests::stop_flushes_queue_on_poll" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 1, [1.0]))
  sink.append(SamplesBuffer::new(1, 1, [2.0]))
  assert_eq(sink.len(), 2)

  sink.stop()
  // stop() only marks sink as stopped; queue is flushed by playback polling.
  assert_eq(sink.len(), 2)
  assert_eq(queue_rx.next(), Some(0.0))
  assert_eq(sink.len(), 0)
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
test "rodio::sink::tests::speed_runtime_update_affects_current_source" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 10, [1.0, 2.0, 3.0]))
  assert_eq(queue_rx.sample_rate(), 10)
  sink.set_speed(2.0)
  assert_eq(queue_rx.sample_rate(), 20)
  sink.set_speed(0.5)
  assert_eq(queue_rx.sample_rate(), 5)
}

///|
test "rodio::sink::tests::get_pos_tracks_runtime_speed_changes" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 10, [1.0, 2.0, 3.0, 4.0]))
  assert_eq(queue_rx.next(), Some(1.0))
  let p1 = sink.get_pos()
  assert_eq(p1.secs, (0 : UInt64))
  assert_eq(p1.nanos, 100_000_000)

  sink.set_speed(2.0)
  assert_eq(queue_rx.next(), Some(2.0))
  let p2 = sink.get_pos()
  assert_eq(p2.secs, (0 : UInt64))
  assert_eq(p2.nanos, 150_000_000)
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
test "rodio::sink::tests::skip_one_accumulates_bounded_requests" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 1, [1.0]))
  sink.append(SamplesBuffer::new(1, 1, [2.0]))
  sink.append(SamplesBuffer::new(1, 1, [3.0]))
  assert_eq(queue_rx.next(), Some(1.0))

  sink.skip_one()
  sink.skip_one()
  sink.skip_one()
  sink.skip_one()
  // len() is decremented when queued skips are processed by playback loop.
  assert_eq(sink.len(), 2)

  assert_eq(queue_rx.next(), Some(0.0))
  assert_eq(sink.len(), 0)
}

///|
test "rodio::sink::tests::get_pos_and_try_seek" {
  let (sink, queue_rx) = Sink::new()
  sink.append(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]))

  ignore(queue_rx.next())
  ignore(queue_rx.next())
  ignore(queue_rx.next())
  let pos0 = sink.get_pos()
  assert_eq(pos0.secs, (0 : UInt64))
  assert_eq(pos0.nanos, 750_000_000)

  sink.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(sink.get_pos().secs, (0 : UInt64))
  assert_eq(queue_rx.next(), Some(1.0))

  ignore(queue_rx.next())
  assert_eq(queue_rx.next(), Some(3.0))
  let pos1 = sink.get_pos()
  assert_eq(pos1.secs, (0 : UInt64))
  assert_eq(pos1.nanos, 750_000_000)

  sink.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  let pos2 = sink.get_pos()
  assert_eq(pos2.secs, (1 : UInt64))
  assert_eq(pos2.nanos, 0)
  assert_eq(queue_rx.next(), Some(0.0))
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

///|
test "rodio::sink::tests::sleep_until_end" {
  let (sink, source) = Sink::new()
  sink.append(SamplesBuffer::new(1, 1, [1.0]))
  assert_eq(source.next(), Some(1.0))
  ignore(source.next())
  sink.sleep_until_end()
  assert_true(sink.empty())
}
