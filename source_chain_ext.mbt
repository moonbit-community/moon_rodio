///|
pub struct Done {
  input : DynSource
  signal : Ref[Int]
  signal_sent : Ref[Bool]
}

///|
pub fn[S : Source] Done::new(source : S, signal : Ref[Int]) -> Done {
  { input: to_dyn(source), signal, signal_sent: @ref.new(false) }
}

///|
pub fn Done::next(self : Done) -> Sample? {
  let next = self.input.next()
  if !self.signal_sent.val && next is None {
    self.signal.val -= 1
    self.signal_sent.val = true
  }
  next
}

///|
pub fn Done::channels(self : Done) -> ChannelCount {
  self.input.channels()
}

///|
pub fn Done::sample_rate(self : Done) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for Done with next(self : Done) {
  self.next()
}

///|
pub impl Source for Done with channels(self : Done) {
  self.channels()
}

///|
pub impl Source for Done with sample_rate(self : Done) {
  self.sample_rate()
}

///|
pub struct EmptyCallback {
  callback : () -> Unit
  called : Ref[Bool]
}

///|
pub fn EmptyCallback::new(callback : () -> Unit) -> EmptyCallback {
  { callback, called: @ref.new(false) }
}

///|
pub fn EmptyCallback::next(self : EmptyCallback) -> Sample? {
  if !self.called.val {
    self.called.val = true
    (self.callback)()
  }
  None
}

///|
pub fn EmptyCallback::channels(_self : EmptyCallback) -> ChannelCount {
  1
}

///|
pub fn EmptyCallback::sample_rate(_self : EmptyCallback) -> SampleRate {
  48_000
}

///|
pub impl Source for EmptyCallback with next(self : EmptyCallback) {
  self.next()
}

///|
pub impl Source for EmptyCallback with channels(self : EmptyCallback) {
  self.channels()
}

///|
pub impl Source for EmptyCallback with sample_rate(self : EmptyCallback) {
  self.sample_rate()
}

///|
pub struct UniformSourceIterator {
  input : DynSource
  target_channels : ChannelCount
  target_sample_rate : SampleRate
}

///|
pub fn[S : Source] UniformSourceIterator::new(
  source : S,
  target_channels : ChannelCount,
  target_sample_rate : SampleRate,
) -> UniformSourceIterator {
  guard target_channels > 0 else { panic() }
  guard target_sample_rate > 0 else { panic() }
  {
    input: uniform_source(to_dyn(source), target_channels, target_sample_rate),
    target_channels,
    target_sample_rate,
  }
}

///|
pub fn UniformSourceIterator::next(self : UniformSourceIterator) -> Sample? {
  self.input.next()
}

///|
pub fn UniformSourceIterator::channels(
  self : UniformSourceIterator,
) -> ChannelCount {
  self.target_channels
}

///|
pub fn UniformSourceIterator::sample_rate(
  self : UniformSourceIterator,
) -> SampleRate {
  self.target_sample_rate
}

///|
pub impl Source for UniformSourceIterator with next(
  self : UniformSourceIterator,
) {
  self.next()
}

///|
pub impl Source for UniformSourceIterator with channels(
  self : UniformSourceIterator,
) {
  self.channels()
}

///|
pub impl Source for UniformSourceIterator with sample_rate(
  self : UniformSourceIterator,
) {
  self.sample_rate()
}
