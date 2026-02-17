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
pub struct Mixer {
  has_pending : Ref[Bool]
  pending_sources : Ref[Array[DynSource]]
  channels : ChannelCount
  sample_rate : SampleRate
}

///|
pub struct MixerSource {
  current_sources : Ref[Array[DynSource]]
  input : Mixer
  sample_count : Ref[Int]
}

///|
pub fn mixer(
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> (Mixer, MixerSource) {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }

  let input = {
    has_pending: @ref.new(false),
    pending_sources: @ref.new([]),
    channels,
    sample_rate,
  }
  let output = {
    current_sources: @ref.new([]),
    input,
    sample_count: @ref.new(0),
  }
  (input, output)
}

///|
pub fn[S : Source] Mixer::add(self : Mixer, source : S) -> Unit {
  let uniform = uniform_source(to_dyn(source), self.channels, self.sample_rate)
  self.pending_sources.val.push(uniform)
  self.has_pending.val = true
}

///|
fn MixerSource::start_pending_sources(self : MixerSource) -> Unit {
  if !self.input.has_pending.val {
    return
  }

  let mut has_pending = false
  let still_pending : Array[DynSource] = []

  for source in self.input.pending_sources.val {
    let in_step = self.sample_count.val % source.channels() == 0
    if in_step {
      self.current_sources.val.push(source)
    } else {
      still_pending.push(source)
      has_pending = true
    }
  }

  self.input.pending_sources.val = still_pending
  self.input.has_pending.val = has_pending
}

///|
fn MixerSource::sum_current_sources(self : MixerSource) -> (Sample, Int) {
  let mut sum = 0.0
  let still_current : Array[DynSource] = []

  for source in self.current_sources.val {
    match source.next() {
      None => ()
      Some(value) => {
        sum += value
        still_current.push(source)
      }
    }
  }

  let active = still_current.length()
  self.current_sources.val = still_current
  (sum, active)
}

///|
pub fn MixerSource::next(self : MixerSource) -> Sample? {
  self.start_pending_sources()
  self.sample_count.val += 1

  let (sum, active) = self.sum_current_sources()
  if active == 0 {
    None
  } else {
    Some(sum)
  }
}

///|
pub fn MixerSource::channels(self : MixerSource) -> ChannelCount {
  self.input.channels
}

///|
pub fn MixerSource::sample_rate(self : MixerSource) -> SampleRate {
  self.input.sample_rate
}

///|
pub impl Source for MixerSource with next(self : MixerSource) {
  self.next()
}

///|
pub impl Source for MixerSource with channels(self : MixerSource) {
  self.channels()
}

///|
pub impl Source for MixerSource with sample_rate(self : MixerSource) {
  self.sample_rate()
}

///|
pub impl Source for MixerSource with current_span_len(_self : MixerSource) {
  source_default_current_span_len()
}

///|
pub impl Source for MixerSource with total_duration(_self : MixerSource) {
  source_default_total_duration()
}

///|
pub impl Source for MixerSource with try_seek(
  _self : MixerSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  source_default_try_seek(pos)
}
