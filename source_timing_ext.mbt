///|
pub struct TrackPosition {
  input : DynSource
  samples_counted : Ref[Int]
  offset_duration : Ref[@moon_cpal.Duration]
  current_span_sample_rate : Ref[SampleRate]
  current_span_channels : Ref[ChannelCount]
  current_span_len : Ref[Int?]
}

///|
pub fn[S : Source] track_position(source : S) -> TrackPosition {
  {
    input: to_dyn(source),
    samples_counted: @ref.new(0),
    offset_duration: @ref.new(@moon_cpal.Duration::from_secs((0 : UInt64))),
    current_span_sample_rate: @ref.new(0),
    current_span_channels: @ref.new(0),
    current_span_len: @ref.new(None),
  }
}

///|
fn TrackPosition::set_current_span(self : TrackPosition) -> Unit {
  self.current_span_len.val = self.input.current_span_len()
  self.current_span_sample_rate.val = self.input.sample_rate()
  self.current_span_channels.val = self.input.channels()
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
  if self.current_span_len.val is None {
    self.set_current_span()
  }

  match self.input.next() {
    None => None
    Some(v) => {
      self.samples_counted.val += 1

      if self.current_span_len.val == Some(self.samples_counted.val) {
        match
          duration_from_sample_count(
            self.samples_counted.val,
            self.current_span_channels.val,
            self.current_span_sample_rate.val,
          ) {
          Some(span_duration) =>
            self.offset_duration.val = duration_add(
              self.offset_duration.val,
              span_duration,
            )
          None => ()
        }
        self.samples_counted.val = 0
        self.set_current_span()
      }
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
  let played = match
    duration_from_sample_count(
      self.samples_counted.val,
      self.input.channels(),
      self.input.sample_rate(),
    ) {
    Some(v) => v
    None => @moon_cpal.Duration::from_secs((0 : UInt64))
  }
  if self.input.sample_rate() <= 0 || self.input.channels() <= 0 {
    return self.offset_duration.val
  }
  duration_add(self.offset_duration.val, played)
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
  self.samples_counted.val = 0
  self.offset_duration.val = pos
  self.current_span_len.val = None
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
