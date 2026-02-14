///|
test "rodio::mixer::tests::basic" {
  let (tx, rx) = @moon_rodio.mixer(1, 48_000)

  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]))
  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [5.0, 5.0, 5.0, 5.0]))

  assert_eq(rx.channels(), 1)
  assert_eq(rx.sample_rate(), 48_000)
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), None)
}

///|
test "rodio::mixer::tests::channels_conv" {
  let (tx, rx) = @moon_rodio.mixer(2, 48_000)

  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]))
  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [5.0, 5.0, 5.0, 5.0]))

  assert_eq(rx.channels(), 2)
  assert_eq(rx.sample_rate(), 48_000)
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), None)
}

///|
test "rodio::mixer::tests::rate_conv" {
  let (tx, rx) = @moon_rodio.mixer(1, 96_000)

  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]))
  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [5.0, 5.0, 5.0, 5.0]))

  assert_eq(rx.channels(), 1)
  assert_eq(rx.sample_rate(), 96_000)
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(-5.0))
  assert_eq(rx.next(), None)
}

///|
test "rodio::mixer::tests::start_afterwards" {
  let (tx, rx) = @moon_rodio.mixer(1, 48_000)

  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]))

  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))

  tx.add(
    @moon_rodio.SamplesBuffer::new(1, 48_000, [
      5.0, 5.0, 6.0, 6.0, 7.0, 7.0, 7.0,
    ]),
  )

  assert_eq(rx.next(), Some(15.0))
  assert_eq(rx.next(), Some(-5.0))

  assert_eq(rx.next(), Some(6.0))
  assert_eq(rx.next(), Some(6.0))

  tx.add(@moon_rodio.SamplesBuffer::new(1, 48_000, [2.0]))

  assert_eq(rx.next(), Some(9.0))
  assert_eq(rx.next(), Some(7.0))
  assert_eq(rx.next(), Some(7.0))

  assert_eq(rx.next(), None)
}

///|
test "rodio::queue::tests::basic" {
  let (tx, rx) = @moon_rodio.queue(false)

  tx.append(
    @moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]),
  )
  tx.append(@moon_rodio.SamplesBuffer::new(2, 96_000, [5.0, 5.0, 5.0, 5.0]))

  assert_eq(rx.channels(), 1)
  assert_eq(rx.sample_rate(), 48_000)
  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))
  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))
  assert_eq(rx.channels(), 2)
  assert_eq(rx.sample_rate(), 96_000)
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), Some(5.0))
  assert_eq(rx.next(), None)
}

///|
test "rodio::queue::tests::immediate_end" {
  let (_, rx) = @moon_rodio.queue(false)
  assert_eq(rx.next(), None)
}

///|
test "rodio::queue::tests::keep_alive" {
  let (tx, rx) = @moon_rodio.queue(true)
  tx.append(
    @moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]),
  )

  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))
  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))

  for _ in 0..<100_000 {
    assert_eq(rx.next(), Some(0.0))
  }
}

///|
test "rodio::queue::tests::no_delay_when_added" {
  let (tx, rx) = @moon_rodio.queue(true)

  for _ in 0..<500 {
    assert_eq(rx.next(), Some(0.0))
  }

  tx.append(
    @moon_rodio.SamplesBuffer::new(1, 48_000, [10.0, -10.0, 10.0, -10.0]),
  )
  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))
  assert_eq(rx.next(), Some(10.0))
  assert_eq(rx.next(), Some(-10.0))
}

///|
test "rodio::queue::tests::append_with_signal" {
  let (tx, rx) = @moon_rodio.queue(false)
  let signal = tx.append_with_signal(
    @moon_rodio.SamplesBuffer::new(1, 1, [7.0]),
  )
  assert_true(!signal.is_done())
  assert_eq(rx.next(), Some(7.0))
  assert_eq(rx.next(), None)
  assert_true(signal.is_done())
}

///|
test "rodio::queue::tests::clear_keeps_current_source" {
  let (tx, rx) = @moon_rodio.queue(false)
  tx.append(@moon_rodio.SamplesBuffer::new(1, 1, [1.0, 2.0]))
  tx.append(@moon_rodio.SamplesBuffer::new(1, 1, [3.0]))
  tx.append(@moon_rodio.SamplesBuffer::new(1, 1, [4.0]))

  assert_eq(rx.next(), Some(1.0))
  assert_eq(tx.clear(), 2)
  assert_eq(rx.next(), Some(2.0))
  assert_eq(rx.next(), None)
}

///|
test "rodio::queue::tests::set_keep_alive_if_empty_runtime_toggle" {
  let (tx, rx) = @moon_rodio.queue(true)
  assert_eq(rx.next(), Some(0.0))
  tx.set_keep_alive_if_empty(false)
  for _ in 0..<511 {
    assert_eq(rx.next(), Some(0.0))
  }
  assert_eq(rx.next(), None)
}
