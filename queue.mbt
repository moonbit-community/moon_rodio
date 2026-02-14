///|
let threshold : Int = 512

///|
pub struct QueueSignal {
  done : Ref[Bool]
}

///|
pub fn QueueSignal::is_done(self : QueueSignal) -> Bool {
  self.done.val
}

///|
pub fn QueueSignal::mark_done(self : QueueSignal) -> Unit {
  self.done.val = true
}

///|
struct QueuedSource {
  source : DynSource
  signal : QueueSignal?
}

///|
pub struct SourcesQueueInput {
  next_sounds : Ref[Array[QueuedSource]]
  keep_alive_if_empty : Ref[Bool]
  reset_version : Ref[Int]
}

///|
pub struct SourcesQueueOutput {
  current : Ref[DynSource]
  current_is_fallback : Ref[Bool]
  prefetched : Ref[Sample?]
  has_prefetched : Ref[Bool]
  seen_reset_version : Ref[Int]
  signal_after_end : Ref[QueueSignal?]
  input : SourcesQueueInput
}

///|
pub fn queue(
  keep_alive_if_empty : Bool,
) -> (SourcesQueueInput, SourcesQueueOutput) {
  let input = {
    next_sounds: @ref.new([]),
    keep_alive_if_empty: @ref.new(keep_alive_if_empty),
    reset_version: @ref.new(0),
  }
  let output = {
    current: @ref.new(make_empty_dyn_source(1, hz_44100)),
    current_is_fallback: @ref.new(true),
    prefetched: @ref.new(None),
    has_prefetched: @ref.new(false),
    seen_reset_version: @ref.new(0),
    signal_after_end: @ref.new(None),
    input,
  }
  (input, output)
}

///|
pub fn[S : Source] SourcesQueueInput::append(
  self : SourcesQueueInput,
  source : S,
) -> Unit {
  self.next_sounds.val.push({ source: to_dyn(source), signal: None })
}

///|
pub fn[S : Source] SourcesQueueInput::append_with_signal(
  self : SourcesQueueInput,
  source : S,
) -> QueueSignal {
  let signal = { done: @ref.new(false) }
  self.next_sounds.val.push({ source: to_dyn(source), signal: Some(signal) })
  signal
}

///|
pub fn SourcesQueueInput::set_keep_alive_if_empty(
  self : SourcesQueueInput,
  keep_alive_if_empty : Bool,
) -> Unit {
  self.keep_alive_if_empty.val = keep_alive_if_empty
}

///|
pub fn SourcesQueueInput::clear(self : SourcesQueueInput) -> Int {
  let len = self.next_sounds.val.length()
  for entry in self.next_sounds.val {
    match entry.signal {
      Some(signal) => signal.mark_done()
      None => ()
    }
  }
  self.next_sounds.val.clear()
  self.reset_version.val += 1
  len
}

///|
fn SourcesQueueOutput::sync_reset(self : SourcesQueueOutput) -> Unit {
  if self.seen_reset_version.val != self.input.reset_version.val {
    match self.signal_after_end.val {
      Some(signal) => signal.mark_done()
      None => ()
    }
    self.signal_after_end.val = None
    self.current.val = make_empty_dyn_source(1, hz_44100)
    self.current_is_fallback.val = true
    self.prefetched.val = None
    self.has_prefetched.val = false
    self.seen_reset_version.val = self.input.reset_version.val
  }
}

///|
fn SourcesQueueOutput::go_next(self : SourcesQueueOutput) -> Bool {
  match self.signal_after_end.val {
    Some(signal) => signal.mark_done()
    None => ()
  }
  self.signal_after_end.val = None

  if !self.input.next_sounds.val.is_empty() {
    let next = self.input.next_sounds.val.remove(0)
    self.current.val = next.source
    self.signal_after_end.val = next.signal
    self.current_is_fallback.val = false
    self.prefetched.val = None
    self.has_prefetched.val = false
    true
  } else if self.input.keep_alive_if_empty.val {
    self.current.val = make_zero_dyn_source(1, hz_44100, threshold)
    self.current_is_fallback.val = true
    self.prefetched.val = None
    self.has_prefetched.val = false
    true
  } else {
    false
  }
}

///|
fn SourcesQueueOutput::ensure_prefetched(self : SourcesQueueOutput) -> Bool {
  if self.has_prefetched.val {
    return true
  }

  while true {
    if self.current_is_fallback.val && !self.input.next_sounds.val.is_empty() {
      let next = self.input.next_sounds.val.remove(0)
      self.current.val = next.source
      self.signal_after_end.val = next.signal
      self.current_is_fallback.val = false
    }

    match self.current.val.next() {
      Some(v) => {
        self.prefetched.val = Some(v)
        self.has_prefetched.val = true
        return true
      }
      None => if !self.go_next() { return false }
    }
  }

  false
}

///|
fn SourcesQueueOutput::next_internal(self : SourcesQueueOutput) -> Sample? {
  self.sync_reset()

  if self.current_is_fallback.val && !self.input.next_sounds.val.is_empty() {
    let next = self.input.next_sounds.val.remove(0)
    self.current.val = next.source
    self.signal_after_end.val = next.signal
    self.current_is_fallback.val = false
    self.prefetched.val = None
    self.has_prefetched.val = false
  }

  if !self.ensure_prefetched() {
    return None
  }

  let value = match self.prefetched.val {
    Some(v) => v
    None => return None
  }

  self.prefetched.val = None
  self.has_prefetched.val = false

  // Eagerly prefetch next sample so metadata and state are updated at source boundaries.
  ignore(self.ensure_prefetched())

  Some(value)
}

///|
pub fn SourcesQueueOutput::next(self : SourcesQueueOutput) -> Sample? {
  self.next_internal()
}

///|
pub fn SourcesQueueOutput::skip_one(self : SourcesQueueOutput) -> Unit {
  self.sync_reset()
  self.prefetched.val = None
  self.has_prefetched.val = false
  if !self.go_next() {
    self.current.val = make_empty_dyn_source(1, hz_44100)
    self.current_is_fallback.val = true
  }
}

///|
pub fn SourcesQueueOutput::channels(self : SourcesQueueOutput) -> ChannelCount {
  self.sync_reset()
  if self.current_is_fallback.val && !self.input.next_sounds.val.is_empty() {
    return self.input.next_sounds.val[0].source.channels()
  }
  self.current.val.channels()
}

///|
pub fn SourcesQueueOutput::sample_rate(self : SourcesQueueOutput) -> SampleRate {
  self.sync_reset()
  if self.current_is_fallback.val && !self.input.next_sounds.val.is_empty() {
    return self.input.next_sounds.val[0].source.sample_rate()
  }
  self.current.val.sample_rate()
}

///|
pub impl Source for SourcesQueueOutput with next(self : SourcesQueueOutput) {
  self.next()
}

///|
pub impl Source for SourcesQueueOutput with channels(self : SourcesQueueOutput) {
  self.channels()
}

///|
pub impl Source for SourcesQueueOutput with sample_rate(
  self : SourcesQueueOutput,
) {
  self.sample_rate()
}

///|
pub impl Source for SourcesQueueOutput with current_span_len(
  _self : SourcesQueueOutput,
) {
  source_default_current_span_len()
}

///|
pub impl Source for SourcesQueueOutput with total_duration(
  _self : SourcesQueueOutput,
) {
  source_default_total_duration()
}

///|
pub impl Source for SourcesQueueOutput with try_seek(
  _self : SourcesQueueOutput,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  source_default_try_seek(pos)
}
