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
pub struct Pausable {
  input : DynSource
  paused_channels : Ref[ChannelCount?]
  remaining_paused_samples : Ref[Int]
}

///|
pub fn[S : Source] pausable(source : S, paused : Bool) -> Pausable {
  let input = to_dyn(source)
  {
    input,
    paused_channels: @ref.new(
      if paused {
        Some(input.channels())
      } else {
        None
      },
    ),
    remaining_paused_samples: @ref.new(0),
  }
}

///|
pub fn Pausable::set_paused(self : Pausable, paused : Bool) -> Unit {
  match (self.paused_channels.val, paused) {
    (None, true) => self.paused_channels.val = Some(self.input.channels())
    (Some(_), false) => self.paused_channels.val = None
    _ => ()
  }
}

///|
pub fn Pausable::is_paused(self : Pausable) -> Bool {
  self.paused_channels.val is Some(_)
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

  match self.paused_channels.val {
    Some(paused_channels) => {
      self.remaining_paused_samples.val = paused_channels - 1
      Some(0.0)
    }
    None => self.input.next()
  }
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
pub impl Source for Pausable with current_span_len(_self : Pausable) {
  _self.input.current_span_len()
}

///|
pub impl Source for Pausable with total_duration(_self : Pausable) {
  _self.input.total_duration()
}

///|
pub impl Source for Pausable with try_seek(
  _self : Pausable,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
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
pub impl Source for Stoppable with current_span_len(_self : Stoppable) {
  _self.input.current_span_len()
}

///|
pub impl Source for Stoppable with total_duration(_self : Stoppable) {
  _self.input.total_duration()
}

///|
pub impl Source for Stoppable with try_seek(
  _self : Stoppable,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
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

///|
pub impl Source for Skippable with current_span_len(_self : Skippable) {
  _self.input.current_span_len()
}

///|
pub impl Source for Skippable with total_duration(_self : Skippable) {
  _self.input.total_duration()
}

///|
pub impl Source for Skippable with try_seek(
  _self : Skippable,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.input.try_seek(pos)
}
