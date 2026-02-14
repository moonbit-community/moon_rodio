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

///|
pub struct FromIter {
  sources : Ref[Array[DynSource]]
  current : Ref[DynSource]
  has_current : Ref[Bool]
}

///|
pub fn from_iter(sources : Array[DynSource]) -> FromIter {
  if sources.is_empty() {
    {
      sources: @ref.new([]),
      current: @ref.new(make_empty_dyn_source(1, hz_44100)),
      has_current: @ref.new(false),
    }
  } else {
    let xs = sources
    let first = xs.remove(0)
    {
      sources: @ref.new(xs),
      current: @ref.new(first),
      has_current: @ref.new(true),
    }
  }
}

///|
fn FromIter::pull_next_source(self : FromIter) -> Bool {
  if self.sources.val.is_empty() {
    self.has_current.val = false
    false
  } else {
    self.current.val = self.sources.val.remove(0)
    self.has_current.val = true
    true
  }
}

///|
pub fn FromIter::next(self : FromIter) -> Sample? {
  while true {
    if !self.has_current.val && !self.pull_next_source() {
      return None
    }

    match self.current.val.next() {
      None => self.has_current.val = false
      Some(v) => return Some(v)
    }
  }

  None
}

///|
pub fn FromIter::channels(self : FromIter) -> ChannelCount {
  if self.has_current.val {
    self.current.val.channels()
  } else if self.sources.val.is_empty() {
    1
  } else {
    self.sources.val[0].channels()
  }
}

///|
pub fn FromIter::sample_rate(self : FromIter) -> SampleRate {
  if self.has_current.val {
    self.current.val.sample_rate()
  } else if self.sources.val.is_empty() {
    hz_44100
  } else {
    self.sources.val[0].sample_rate()
  }
}

///|
pub impl Source for FromIter with next(self : FromIter) {
  self.next()
}

///|
pub impl Source for FromIter with channels(self : FromIter) {
  self.channels()
}

///|
pub impl Source for FromIter with sample_rate(self : FromIter) {
  self.sample_rate()
}
