///|
pub struct StaticSamplesBuffer {
  channels : ChannelCount
  sample_rate : SampleRate
  samples : Array[Sample]
  cursor : Ref[Int]
}

///|
pub fn StaticSamplesBuffer::new(
  channels : ChannelCount,
  sample_rate : SampleRate,
  samples : Array[Sample],
) -> StaticSamplesBuffer {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channels, sample_rate, samples, cursor: @ref.new(0) }
}

///|
pub fn StaticSamplesBuffer::channels(
  self : StaticSamplesBuffer,
) -> ChannelCount {
  self.channels
}

///|
pub fn StaticSamplesBuffer::sample_rate(
  self : StaticSamplesBuffer,
) -> SampleRate {
  self.sample_rate
}

///|
pub fn StaticSamplesBuffer::next(self : StaticSamplesBuffer) -> Sample? {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let v = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(v)
  }
}

///|
pub impl Source for StaticSamplesBuffer with next(self : StaticSamplesBuffer) {
  self.next()
}

///|
pub impl Source for StaticSamplesBuffer with channels(
  self : StaticSamplesBuffer,
) {
  self.channels()
}

///|
pub impl Source for StaticSamplesBuffer with sample_rate(
  self : StaticSamplesBuffer,
) {
  self.sample_rate()
}

///|
pub impl Source for StaticSamplesBuffer with current_span_len(
  self : StaticSamplesBuffer,
) {
  let remaining = self.samples.length() - self.cursor.val
  if remaining <= 0 {
    Some(0)
  } else {
    Some(remaining)
  }
}

///|
pub impl Source for StaticSamplesBuffer with total_duration(
  self : StaticSamplesBuffer,
) {
  duration_from_sample_count(
    self.samples.length(),
    self.channels(),
    self.sample_rate(),
  )
}

///|
pub impl Source for StaticSamplesBuffer with try_seek(
  self : StaticSamplesBuffer,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  let target = sample_index_from_duration(
    pos,
    self.channels(),
    self.sample_rate(),
  )
  let clamped = if target < 0 {
    0
  } else if target > self.samples.length() {
    self.samples.length()
  } else {
    target
  }
  self.cursor.val = clamped
}

///|
pub fn buffer_from_iter(
  channels : ChannelCount,
  sample_rate : SampleRate,
  samples : Array[Sample],
) -> SamplesBuffer {
  SamplesBuffer::new(channels, sample_rate, samples)
}
