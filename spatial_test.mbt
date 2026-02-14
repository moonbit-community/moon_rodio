///|
test "rodio::source::spatial_source_balance" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, 1.0])
  let spatial = SpatialSource::new(src, [-1.0, 0.0, 0.0], [-1.0, 0.0, 0.0], [
    1.0, 0.0, 0.0,
  ])

  assert_eq(spatial.channels(), 2)
  assert_eq(spatial.sample_rate(), 44_100)

  let l0 = spatial.next().unwrap()
  let r0 = spatial.next().unwrap()
  assert_true(l0 > r0)
}

///|
test "rodio::source::spatial_sink_append" {
  let (mix_tx, mix_rx) = mixer(2, 44_100)
  let sink = SpatialSink::connect_new(
    mix_tx,
    [0.0, 0.0, 0.0],
    [-1.0, 0.0, 0.0],
    [1.0, 0.0, 0.0],
  )

  sink.append(SamplesBuffer::new(1, 44_100, [1.0, 1.0]))
  assert_eq(sink.len(), 1)
  assert_true(!sink.empty())

  let a = mix_rx.next().unwrap()
  let b = mix_rx.next().unwrap()
  assert_true(a > 0.0)
  assert_true(b > 0.0)
}

///|
test "rodio::source::spatial_sink_seek_and_pos" {
  let (mix_tx, mix_rx) = mixer(2, 1)
  let sink = SpatialSink::connect_new(
    mix_tx,
    [0.0, 0.0, 0.0],
    [-1.0, 0.0, 0.0],
    [1.0, 0.0, 0.0],
  )

  sink.append(SamplesBuffer::new(1, 1, [1.0, 2.0]))
  let l0 = mix_rx.next().unwrap()
  let r0 = mix_rx.next().unwrap()
  sink.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(sink.get_pos().secs, (0 : UInt64))
  let l1 = mix_rx.next().unwrap()
  let r1 = mix_rx.next().unwrap()
  assert_eq(l1, l0)
  assert_eq(r1, r0)
}
