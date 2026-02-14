///|
pub struct Pausable {
  input : DynSource
  paused : Ref[Bool]
  remaining_paused_samples : Ref[Int]
}

///|
pub fn[S : Source] pausable(source : S, paused : Bool) -> Pausable {
  {
    input: to_dyn(source),
    paused: @ref.new(paused),
    remaining_paused_samples: @ref.new(0),
  }
}

///|
pub fn Pausable::set_paused(self : Pausable, paused : Bool) -> Unit {
  self.paused.val = paused
}

///|
pub fn Pausable::is_paused(self : Pausable) -> Bool {
  self.paused.val
}

///|
pub fn Pausable::inner(self : Pausable) -> DynSource {
  self.input
}

///|
pub fn Pausable::inner_mut(self : Pausable) -> DynSource {
  self.input
}

///|
pub fn Pausable::into_inner(self : Pausable) -> DynSource {
  self.input
}

///|
pub fn Pausable::next(self : Pausable) -> Sample? {
  if self.remaining_paused_samples.val > 0 {
    self.remaining_paused_samples.val -= 1
    return Some(0.0)
  }

  if self.paused.val {
    self.remaining_paused_samples.val = self.input.channels() - 1
    return Some(0.0)
  }

  self.input.next()
}

///|
pub fn Pausable::channels(self : Pausable) -> ChannelCount {
  self.input.channels()
}

///|
pub fn Pausable::sample_rate(self : Pausable) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for Pausable with next(self : Pausable) {
  self.next()
}

///|
pub impl Source for Pausable with channels(self : Pausable) {
  self.channels()
}

///|
pub impl Source for Pausable with sample_rate(self : Pausable) {
  self.sample_rate()
}

///|
pub struct Stoppable {
  input : DynSource
  stopped : Ref[Bool]
}

///|
pub fn[S : Source] stoppable(source : S) -> Stoppable {
  { input: to_dyn(source), stopped: @ref.new(false) }
}

///|
pub fn Stoppable::stop(self : Stoppable) -> Unit {
  self.stopped.val = true
}

///|
pub fn Stoppable::inner(self : Stoppable) -> DynSource {
  self.input
}

///|
pub fn Stoppable::inner_mut(self : Stoppable) -> DynSource {
  self.input
}

///|
pub fn Stoppable::into_inner(self : Stoppable) -> DynSource {
  self.input
}

///|
pub fn Stoppable::next(self : Stoppable) -> Sample? {
  if self.stopped.val {
    None
  } else {
    self.input.next()
  }
}

///|
pub fn Stoppable::channels(self : Stoppable) -> ChannelCount {
  self.input.channels()
}

///|
pub fn Stoppable::sample_rate(self : Stoppable) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for Stoppable with next(self : Stoppable) {
  self.next()
}

///|
pub impl Source for Stoppable with channels(self : Stoppable) {
  self.channels()
}

///|
pub impl Source for Stoppable with sample_rate(self : Stoppable) {
  self.sample_rate()
}

///|
pub struct Skippable {
  input : DynSource
  do_skip : Ref[Bool]
}

///|
pub fn[S : Source] skippable(source : S) -> Skippable {
  { input: to_dyn(source), do_skip: @ref.new(false) }
}

///|
pub fn Skippable::skip(self : Skippable) -> Unit {
  self.do_skip.val = true
}

///|
pub fn Skippable::inner(self : Skippable) -> DynSource {
  self.input
}

///|
pub fn Skippable::inner_mut(self : Skippable) -> DynSource {
  self.input
}

///|
pub fn Skippable::into_inner(self : Skippable) -> DynSource {
  self.input
}

///|
pub fn Skippable::next(self : Skippable) -> Sample? {
  if self.do_skip.val {
    None
  } else {
    self.input.next()
  }
}

///|
pub fn Skippable::channels(self : Skippable) -> ChannelCount {
  self.input.channels()
}

///|
pub fn Skippable::sample_rate(self : Skippable) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for Skippable with next(self : Skippable) {
  self.next()
}

///|
pub impl Source for Skippable with channels(self : Skippable) {
  self.channels()
}

///|
pub impl Source for Skippable with sample_rate(self : Skippable) {
  self.sample_rate()
}
