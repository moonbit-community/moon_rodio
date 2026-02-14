///|
pub struct TrackPosition {
  input : DynSource
  played_samples : Ref[Int]
  offset_secs : Ref[Int]
}

///|
pub fn[S : Source] track_position(source : S) -> TrackPosition {
  {
    input: to_dyn(source),
    played_samples: @ref.new(0),
    offset_secs: @ref.new(0),
  }
}

///|
pub fn TrackPosition::inner(self : TrackPosition) -> DynSource {
  self.input
}

///|
pub fn TrackPosition::inner_mut(self : TrackPosition) -> DynSource {
  self.input
}

///|
pub fn TrackPosition::into_inner(self : TrackPosition) -> DynSource {
  self.input
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
  let channels = self.input.channels()
  let sample_rate = self.input.sample_rate()
  if sample_rate <= 0 || channels <= 0 {
    return @moon_cpal.Duration::from_secs((0 : UInt64))
  }
  let per_second = sample_rate * channels
  let elapsed_secs = self.played_samples.val / per_second + self.offset_secs.val
  @moon_cpal.Duration::from_secs(elapsed_secs.to_uint64())
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
pub impl Source for TrackPosition with current_span_len(_self : TrackPosition) {
  _self.input.current_span_len()
}

///|
pub impl Source for TrackPosition with total_duration(_self : TrackPosition) {
  _self.input.total_duration()
}

///|
pub impl Source for TrackPosition with try_seek(
  self : TrackPosition,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.input.try_seek(pos)
  self.played_samples.val = 0
  self.offset_secs.val = pos.secs.to_int()
}

///|
pub struct PeriodicAccess {
  input : DynSource
  every_samples : Int
  remaining : Ref[Int]
  callback : () -> Unit
}

///|
fn period_to_sample_count(
  period : @moon_cpal.Duration,
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> Int {
  if channels <= 0 || sample_rate <= 0 {
    return 1
  }
  let per_second = channels * sample_rate
  let secs_part = period.secs.to_int() * per_second
  let nanos_part = period.nanos * per_second / 1_000_000_000
  let total = secs_part + nanos_part
  if total <= 0 {
    1
  } else {
    total
  }
}

///|
pub fn[S : Source] periodic_access(
  source : S,
  every_samples : Int,
  callback : () -> Unit,
) -> PeriodicAccess {
  guard every_samples > 0 else { panic() }
  { input: to_dyn(source), every_samples, remaining: @ref.new(1), callback }
}

///|
pub fn[S : Source] periodic(
  source : S,
  period : @moon_cpal.Duration,
  callback : () -> Unit,
) -> PeriodicAccess {
  let every = period_to_sample_count(
    period,
    source.channels(),
    source.sample_rate(),
  )
  periodic_access(source, every, callback)
}

///|
pub fn PeriodicAccess::inner(self : PeriodicAccess) -> DynSource {
  self.input
}

///|
pub fn PeriodicAccess::inner_mut(self : PeriodicAccess) -> DynSource {
  self.input
}

///|
pub fn PeriodicAccess::into_inner(self : PeriodicAccess) -> DynSource {
  self.input
}

///|
pub fn PeriodicAccess::next(self : PeriodicAccess) -> Sample? {
  self.remaining.val -= 1
  if self.remaining.val <= 0 {
    (self.callback)()
    self.remaining.val = self.every_samples
  }
  self.input.next()
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

///|
pub impl Source for PeriodicAccess with current_span_len(_self : PeriodicAccess) {
  _self.input.current_span_len()
}

///|
pub impl Source for PeriodicAccess with total_duration(_self : PeriodicAccess) {
  _self.input.total_duration()
}

///|
pub impl Source for PeriodicAccess with try_seek(
  self : PeriodicAccess,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.input.try_seek(pos)
}
