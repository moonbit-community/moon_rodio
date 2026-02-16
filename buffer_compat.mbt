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
  _self : StaticSamplesBuffer,
) {
  None
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
  _self : StaticSamplesBuffer,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  raise SeekError::NotSupported
}

///|
pub fn buffer_from_iter(
  channels : ChannelCount,
  sample_rate : SampleRate,
  samples : Array[Sample],
) -> SamplesBuffer {
  SamplesBuffer::new(channels, sample_rate, samples)
}
