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

///|
test "rodio::queue::tests::try_seek_only_current_source" {
  let (tx, rx) = @moon_rodio.queue(true)
  tx.append(@moon_rodio.SamplesBuffer::new(1, 1, [7.0, 8.0]))

  // Seek while current is initial empty source. This should not seek the pending source.
  let seek_err = try {
    rx.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(seek_err)
  assert_eq(rx.next(), Some(7.0))
  assert_eq(rx.next(), Some(8.0))
}

///|
test "rodio::queue::tests::append_updates_metadata" {
  for keep_alive in [false, true] {
    let (tx, rx) = @moon_rodio.queue(keep_alive)
    assert_eq(rx.channels(), 1)
    assert_eq(rx.sample_rate(), 44_100)

    tx.append(@moon_rodio.SamplesBuffer::new(2, 44_100, [0.1, 0.2, 0.3, 0.4]))
    assert_eq(rx.channels(), 2)
    assert_eq(rx.sample_rate(), 44_100)
  }
}

///|
struct SpanMismatchSource {
  samples : Array[@moon_rodio.Sample]
  cursor : Ref[Int]
  channels : @moon_rodio.ChannelCount
  sample_rate : @moon_rodio.SampleRate
  total_span_len : Int?
}

///|
fn SpanMismatchSource::new(
  samples : Array[@moon_rodio.Sample],
  channels : @moon_rodio.ChannelCount,
  sample_rate : @moon_rodio.SampleRate,
  total_span_len : Int?,
) -> SpanMismatchSource {
  { samples, cursor: @ref.new(0), channels, sample_rate, total_span_len }
}

///|
impl @moon_rodio.Source for SpanMismatchSource with next(
  self : SpanMismatchSource,
) {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let value = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(value)
  }
}

///|
impl @moon_rodio.Source for SpanMismatchSource with channels(
  self : SpanMismatchSource,
) {
  self.channels
}

///|
impl @moon_rodio.Source for SpanMismatchSource with sample_rate(
  self : SpanMismatchSource,
) {
  self.sample_rate
}

///|
impl @moon_rodio.Source for SpanMismatchSource with current_span_len(
  self : SpanMismatchSource,
) {
  match self.total_span_len {
    Some(total) =>
      Some(if total > self.cursor.val { total - self.cursor.val } else { 0 })
    None => None
  }
}

///|
impl @moon_rodio.Source for SpanMismatchSource with total_duration(
  _self : SpanMismatchSource,
) {
  None
}

///|
impl @moon_rodio.Source for SpanMismatchSource with try_seek(
  _self : SpanMismatchSource,
  pos : @moon_cpal.Duration,
) -> Unit raise @moon_rodio.SeekError {
  @moon_rodio.Empty::new(1, 1).try_seek(pos)
}

///|
test "rodio::queue::tests::span_ending_mid_frame" {
  let source1 = SpanMismatchSource::new(
    [0.1, 0.2, 0.1, 0.2, 0.1],
    2,
    44_100,
    Some(6),
  )
  let source2 = @moon_rodio.SamplesBuffer::new(2, 44_100, [0.3, 0.4, 0.3, 0.4])

  let (controls, source) = @moon_rodio.queue(true)
  controls.append(source1)
  controls.append(source2)

  assert_eq(source.next(), Some(0.1))
  assert_eq(source.next(), Some(0.2))
  assert_eq(source.next(), Some(0.1))
  assert_eq(source.next(), Some(0.2))
  assert_eq(source.next(), Some(0.1))
  assert_eq(source.next(), Some(0.0))
  assert_eq(source.next(), Some(0.3))
  assert_eq(source.next(), Some(0.4))
  assert_eq(source.next(), Some(0.3))
  assert_eq(source.next(), Some(0.4))
}
