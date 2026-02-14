///|
pub struct TrackPosition {
  input : DynSource
  played_samples : Ref[Int]
}

///|
pub fn[S : Source] track_position(source : S) -> TrackPosition {
  { input: to_dyn(source), played_samples: @ref.new(0) }
}

///|
pub fn TrackPosition::next(self : TrackPosition) -> Sample? {
  match self.input.next() {
    None => None
    Some(v) => {
      self.played_samples.val += 1
      Some(v)
    }
  }
}

///|
pub fn TrackPosition::channels(self : TrackPosition) -> ChannelCount {
  self.input.channels()
}

///|
pub fn TrackPosition::sample_rate(self : TrackPosition) -> SampleRate {
  self.input.sample_rate()
}

///|
pub fn TrackPosition::get_pos(self : TrackPosition) -> @moon_cpal.Duration {
  let sample_rate = self.input.sample_rate()
  if sample_rate <= 0 {
    return @moon_cpal.Duration::from_secs((0 : UInt64))
  }
  @moon_cpal.Duration::from_secs(
    (self.played_samples.val / sample_rate).to_uint64(),
  )
}

///|
pub impl Source for TrackPosition with next(self : TrackPosition) {
  self.next()
}

///|
pub impl Source for TrackPosition with channels(self : TrackPosition) {
  self.channels()
}

///|
pub impl Source for TrackPosition with sample_rate(self : TrackPosition) {
  self.sample_rate()
}

///|
pub struct PeriodicAccess {
  input : DynSource
  every_samples : Int
  remaining : Ref[Int]
  callback : () -> Unit
}

///|
pub fn[S : Source] periodic_access(
  source : S,
  every_samples : Int,
  callback : () -> Unit,
) -> PeriodicAccess {
  guard every_samples > 0 else { panic() }
  {
    input: to_dyn(source),
    every_samples,
    remaining: @ref.new(every_samples),
    callback,
  }
}

///|
pub fn PeriodicAccess::next(self : PeriodicAccess) -> Sample? {
  match self.input.next() {
    None => None
    Some(v) => {
      self.remaining.val -= 1
      if self.remaining.val <= 0 {
        (self.callback)()
        self.remaining.val = self.every_samples
      }
      Some(v)
    }
  }
}

///|
pub fn PeriodicAccess::channels(self : PeriodicAccess) -> ChannelCount {
  self.input.channels()
}

///|
pub fn PeriodicAccess::sample_rate(self : PeriodicAccess) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for PeriodicAccess with next(self : PeriodicAccess) {
  self.next()
}

///|
pub impl Source for PeriodicAccess with channels(self : PeriodicAccess) {
  self.channels()
}

///|
pub impl Source for PeriodicAccess with sample_rate(self : PeriodicAccess) {
  self.sample_rate()
}
