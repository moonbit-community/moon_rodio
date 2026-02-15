///|
pub struct SinkControls {
  pause : Ref[Bool]
  stopped : Ref[Bool]
  to_clear : Ref[Int]
  volume : Ref[Sample]
  speed : Ref[Sample]
  sound_count : Ref[Int]
  position : Ref[@moon_cpal.Duration]
}

///|
pub struct ControlledQueueSource {
  inner : SourcesQueueOutput
  controls : SinkControls
}

///|
pub struct Sink {
  queue_tx : SourcesQueueInput
  queue_rx : SourcesQueueOutput
  controls : SinkControls
  detached : Ref[Bool]
  last_signal : Ref[QueueSignal?]
}

///|
fn with_done_count(source : DynSource, sound_count : Ref[Int]) -> DynSource {
  let ended = @ref.new(false)
  DynSource::new_dynamic(
    fn() {
      if ended.val {
        return None
      }

      match source.next() {
        None => {
          ended.val = true
          if sound_count.val > 0 {
            sound_count.val -= 1
          }
          None
        }
        Some(v) => Some(v)
      }
    },
    fn() { source.channels() },
    fn() { source.sample_rate() },
    current_span_len=fn() { source.current_span_len() },
    total_duration=fn() { source.total_duration() },
    try_seek=fn(pos : @moon_cpal.Duration) {
      try {
        source.try_seek(pos)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
fn speed_with_control(source : DynSource, speed : Ref[Sample]) -> DynSource {
  DynSource::new_dynamic(
    fn() { source.next() },
    fn() { source.channels() },
    fn() {
      let rate = (Double::from_int(source.sample_rate()) * speed.val).to_int()
      if rate <= 0 {
        1
      } else {
        rate
      }
    },
    // Keep spans short so runtime speed changes are observed quickly by consumers.
    current_span_len=fn() { Some(1) },
    total_duration=fn() {
      source
      .total_duration()
      .map(fn(d) { duration_div_ratio_floor(d, speed.val) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
      let mapped = duration_mul_ratio_floor(pos, speed.val)
      try {
        source.try_seek(mapped)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
pub fn ControlledQueueSource::next(self : ControlledQueueSource) -> Sample? {
  while self.controls.to_clear.val > 0 {
    self.controls.to_clear.val -= 1
    if self.controls.sound_count.val > 0 {
      self.controls.sound_count.val -= 1
    }
    self.inner.skip_one()
    self.controls.position.val = @moon_cpal.Duration::from_secs((0 : UInt64))
  }

  if self.controls.stopped.val || self.controls.pause.val {
    Some(0.0)
  } else {
    match self.inner.next() {
      None => None
      Some(v) => {
        let step = match
          duration_from_sample_count(
            1,
            self.inner.channels(),
            self.inner.sample_rate(),
          ) {
          Some(d) => d
          None => @moon_cpal.Duration::from_secs((0 : UInt64))
        }
        self.controls.position.val = duration_add(
          self.controls.position.val,
          step,
        )
        Some(v * self.controls.volume.val)
      }
    }
  }
}

///|
pub fn ControlledQueueSource::channels(
  self : ControlledQueueSource,
) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn ControlledQueueSource::sample_rate(
  self : ControlledQueueSource,
) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for ControlledQueueSource with next(
  self : ControlledQueueSource,
) {
  self.next()
}

///|
pub impl Source for ControlledQueueSource with channels(
  self : ControlledQueueSource,
) {
  self.channels()
}

///|
pub impl Source for ControlledQueueSource with sample_rate(
  self : ControlledQueueSource,
) {
  self.sample_rate()
}

///|
pub impl Source for ControlledQueueSource with current_span_len(
  self : ControlledQueueSource,
) {
  self.inner.current_span_len()
}

///|
pub impl Source for ControlledQueueSource with total_duration(
  self : ControlledQueueSource,
) {
  self.inner.total_duration()
}

///|
pub impl Source for ControlledQueueSource with try_seek(
  self : ControlledQueueSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub fn Sink::new() -> (Sink, ControlledQueueSource) {
  let (queue_tx, queue_rx) = queue(true)
  let controls = {
    pause: @ref.new(false),
    stopped: @ref.new(false),
    to_clear: @ref.new(0),
    volume: @ref.new(1.0),
    speed: @ref.new(1.0),
    sound_count: @ref.new(0),
    position: @ref.new(@moon_cpal.Duration::from_secs((0 : UInt64))),
  }
  (
    {
      queue_tx,
      queue_rx,
      controls,
      detached: @ref.new(false),
      last_signal: @ref.new(None),
    },
    { inner: queue_rx, controls },
  )
}

///|
pub fn Sink::connect_new(mixer : Mixer) -> Sink {
  let (sink, source) = Sink::new()
  mixer.add(source)
  sink
}

///|
pub fn[S : Source] Sink::append(self : Sink, source : S) -> Unit {
  self.controls.stopped.val = false
  let speeded = speed_with_control(to_dyn(source), self.controls.speed)
  if self.empty() {
    self.controls.position.val = @moon_cpal.Duration::from_secs((0 : UInt64))
  }
  self.controls.sound_count.val += 1
  let signal = self.queue_tx.append_with_signal(
    with_done_count(speeded, self.controls.sound_count),
  )
  self.last_signal.val = Some(signal)
}

///|
pub fn Sink::volume(self : Sink) -> Sample {
  self.controls.volume.val
}

///|
pub fn Sink::set_volume(self : Sink, value : Sample) -> Unit {
  self.controls.volume.val = value
}

///|
pub fn Sink::speed(self : Sink) -> Sample {
  self.controls.speed.val
}

///|
pub fn Sink::set_speed(self : Sink, value : Sample) -> Unit {
  guard value > 0.0 else { panic() }
  self.controls.speed.val = value
}

///|
pub fn Sink::play(self : Sink) -> Unit {
  self.controls.pause.val = false
}

///|
pub fn Sink::pause(self : Sink) -> Unit {
  self.controls.pause.val = true
}

///|
pub fn Sink::is_paused(self : Sink) -> Bool {
  self.controls.pause.val
}

///|
pub fn Sink::stop(self : Sink) -> Unit {
  self.controls.stopped.val = true
  self.controls.to_clear.val = 0
  self.controls.position.val = @moon_cpal.Duration::from_secs((0 : UInt64))
  self.controls.sound_count.val = 0
  self.last_signal.val = None
  ignore(self.queue_tx.clear())
  self.queue_rx.skip_one()
}

///|
pub fn Sink::clear(self : Sink) -> Unit {
  self.controls.to_clear.val = 0
  self.controls.position.val = @moon_cpal.Duration::from_secs((0 : UInt64))
  self.controls.sound_count.val = 0
  self.last_signal.val = None
  ignore(self.queue_tx.clear())
  self.queue_rx.skip_one()
  self.pause()
}

///|
pub fn Sink::skip_one(self : Sink) -> Unit {
  // Queue skip requests up to current queue length; apply them in playback loop.
  if self.controls.sound_count.val > self.controls.to_clear.val {
    self.controls.to_clear.val += 1
  }
}

///|
pub fn Sink::try_seek(
  self : Sink,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  if self.controls.sound_count.val <= 0 {
    return
  }
  self.queue_rx.try_seek(pos)
  self.controls.position.val = pos
}

///|
pub fn Sink::get_pos(self : Sink) -> @moon_cpal.Duration {
  self.controls.position.val
}

///|
pub fn Sink::sleep_until_end(self : Sink) -> Unit {
  match self.last_signal.val {
    None => ()
    Some(signal) => {
      while !signal.is_done() {

      }
      self.last_signal.val = None
    }
  }
}

///|
pub fn Sink::empty(self : Sink) -> Bool {
  self.len() == 0
}

///|
pub fn Sink::len(self : Sink) -> Int {
  self.controls.sound_count.val
}

///|
pub fn Sink::detach(self : Sink) -> Unit {
  self.detached.val = true
}
