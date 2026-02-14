///|
pub struct SinkControls {
  pause : Ref[Bool]
  stopped : Ref[Bool]
  volume : Ref[Sample]
  speed : Ref[Sample]
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
}

///|
pub fn ControlledQueueSource::next(self : ControlledQueueSource) -> Sample? {
  if self.controls.stopped.val || self.controls.pause.val {
    Some(0.0)
  } else {
    match self.inner.next() {
      None => None
      Some(v) => Some(v * self.controls.volume.val)
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
    volume: @ref.new(1.0),
    speed: @ref.new(1.0),
  }
  (
    { queue_tx, controls, detached: @ref.new(false) },
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
  self.queue_tx.append(speeded)
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
  ignore(self.queue_tx.clear())
}

///|
pub fn Sink::clear(self : Sink) -> Unit {
  ignore(self.queue_tx.clear())
  self.pause()
}

///|
pub fn Sink::sleep_until_end(self : Sink) -> Unit {
  ignore(self)
}

///|
pub fn Sink::empty(self : Sink) -> Bool {
  self.queue_tx.next_sounds.val.is_empty()
}

///|
pub fn Sink::len(self : Sink) -> Int {
  self.queue_tx.next_sounds.val.length()
}

///|
pub fn Sink::detach(self : Sink) -> Unit {
  self.detached.val = true
}
