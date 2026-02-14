///|
pub struct SinkControls {
  pause : Ref[Bool]
  stopped : Ref[Bool]
  skip_one : Ref[Bool]
  volume : Ref[Sample]
  speed : Ref[Sample]
  sound_count : Ref[Int]
  position_samples : Ref[Int]
  position_sample_rate : Ref[SampleRate]
  position_channels : Ref[ChannelCount]
}

///|
pub struct ControlledQueueSource {
  inner : SourcesQueueOutput
  controls : SinkControls
}

///|
pub struct Sink {
  queue_tx : SourcesQueueInput
  controls : SinkControls
  detached : Ref[Bool]
  last_signal : Ref[QueueSignal?]
}

///|
fn with_done_count(source : DynSource, sound_count : Ref[Int]) -> DynSource {
  let ended = @ref.new(false)
  DynSource::new(
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
    source.channels(),
    source.sample_rate(),
  )
}

///|
pub fn ControlledQueueSource::next(self : ControlledQueueSource) -> Sample? {
  if self.controls.skip_one.val {
    self.controls.skip_one.val = false
    self.inner.skip_one()
    self.controls.position_samples.val = 0
  }

  if self.controls.stopped.val || self.controls.pause.val {
    Some(0.0)
  } else {
    match self.inner.next() {
      None => None
      Some(v) => {
        self.controls.position_samples.val += 1
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
pub fn Sink::new() -> (Sink, ControlledQueueSource) {
  let (queue_tx, queue_rx) = queue(true)
  let controls = {
    pause: @ref.new(false),
    stopped: @ref.new(false),
    skip_one: @ref.new(false),
    volume: @ref.new(1.0),
    speed: @ref.new(1.0),
    sound_count: @ref.new(0),
    position_samples: @ref.new(0),
    position_sample_rate: @ref.new(hz_44100),
    position_channels: @ref.new(1),
  }
  (
    {
      queue_tx,
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
  let speeded = speed(source, self.controls.speed.val)
  if self.empty() {
    self.controls.position_samples.val = 0
    self.controls.position_sample_rate.val = speeded.sample_rate()
    self.controls.position_channels.val = speeded.channels()
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
  self.controls.position_samples.val = 0
  self.controls.sound_count.val = 0
  self.last_signal.val = None
  ignore(self.queue_tx.clear())
}

///|
pub fn Sink::clear(self : Sink) -> Unit {
  self.controls.position_samples.val = 0
  self.controls.sound_count.val = 0
  self.last_signal.val = None
  ignore(self.queue_tx.clear())
  self.pause()
}

///|
pub fn Sink::skip_one(self : Sink) -> Unit {
  if self.controls.sound_count.val > 0 {
    self.controls.sound_count.val -= 1
  }
  self.controls.skip_one.val = true
}

///|
pub fn Sink::try_seek(
  self : Sink,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  if self.controls.sound_count.val <= 0 {
    return
  }
  raise SeekError::NotSupported
}

///|
pub fn Sink::get_pos(self : Sink) -> @moon_cpal.Duration {
  let sample_rate = self.controls.position_sample_rate.val
  let channels = self.controls.position_channels.val
  if sample_rate <= 0 || channels <= 0 {
    return @moon_cpal.Duration::from_secs((0 : UInt64))
  }

  let samples = self.controls.position_samples.val
  if samples <= 0 {
    return @moon_cpal.Duration::from_secs((0 : UInt64))
  }

  let frames = samples / channels
  let secs = frames / sample_rate
  @moon_cpal.Duration::from_secs(secs.to_uint64())
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
