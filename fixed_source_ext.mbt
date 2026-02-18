// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Compatibility trait mirroring `rodio::fixed_source::FixedSource`.
///
/// Unlike `Source`, a `FixedSource` never changes channel count and sample rate.
pub(open) trait FixedSource {
  next(Self) -> Sample?
  channels(Self) -> ChannelCount
  sample_rate(Self) -> SampleRate
  total_duration(Self) -> @moon_cpal.Duration?
}

///|
pub struct FixedSourceAdapter {
  inner : DynSource
}

///|
pub fn[S : FixedSource] FixedSourceAdapter::new(
  source : S,
) -> FixedSourceAdapter {
  {
    inner: DynSource::new(
      fn() { source.next() },
      source.channels(),
      source.sample_rate(),
      current_span_len=source_default_current_span_len,
      total_duration=fn() { source.total_duration() },
      try_seek=fn(_pos : @moon_cpal.Duration) { Err(SeekError::NotSupported) },
    ),
  }
}

///|
pub fn FixedSourceAdapter::inner(self : FixedSourceAdapter) -> DynSource {
  self.inner
}

///|
pub fn FixedSourceAdapter::next(self : FixedSourceAdapter) -> Sample? {
  self.inner.next()
}

///|
pub fn FixedSourceAdapter::channels(self : FixedSourceAdapter) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn FixedSourceAdapter::sample_rate(self : FixedSourceAdapter) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for FixedSourceAdapter with next(self : FixedSourceAdapter) {
  self.next()
}

///|
pub impl Source for FixedSourceAdapter with channels(self : FixedSourceAdapter) {
  self.channels()
}

///|
pub impl Source for FixedSourceAdapter with sample_rate(
  self : FixedSourceAdapter,
) {
  self.sample_rate()
}

///|
pub impl Source for FixedSourceAdapter with current_span_len(
  _self : FixedSourceAdapter,
) {
  None
}

///|
pub impl Source for FixedSourceAdapter with total_duration(
  _self : FixedSourceAdapter,
) {
  _self.inner.total_duration()
}

///|
pub impl Source for FixedSourceAdapter with try_seek(
  _self : FixedSourceAdapter,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.inner.try_seek(pos)
}

///|
pub struct FixedSamplesBuffer {
  channels : ChannelCount
  sample_rate : SampleRate
  samples : Array[Sample]
  cursor : Ref[Int]
  duration : @moon_cpal.Duration?
}

///|
pub fn FixedSamplesBuffer::new(
  channels : ChannelCount,
  sample_rate : SampleRate,
  samples : Array[Sample],
) -> FixedSamplesBuffer {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  let duration = duration_from_sample_count(
    samples.length(),
    channels,
    sample_rate,
  )
  { channels, sample_rate, samples, cursor: @ref.new(0), duration }
}

///|
pub impl FixedSource for FixedSamplesBuffer with next(self : FixedSamplesBuffer) {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let v = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(v)
  }
}

///|
pub impl FixedSource for FixedSamplesBuffer with channels(
  self : FixedSamplesBuffer,
) {
  self.channels
}

///|
pub impl FixedSource for FixedSamplesBuffer with sample_rate(
  self : FixedSamplesBuffer,
) {
  self.sample_rate
}

///|
pub impl FixedSource for FixedSamplesBuffer with total_duration(
  self : FixedSamplesBuffer,
) {
  self.duration
}
