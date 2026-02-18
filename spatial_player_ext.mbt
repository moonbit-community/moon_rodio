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
/// Naming-compatible wrapper around `SpatialSink`.
pub struct SpatialPlayer {
  inner : SpatialSink
}

///|
pub fn SpatialPlayer::connect_new(
  mixer : Mixer,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> SpatialPlayer {
  {
    inner: SpatialSink::connect_new(
      mixer, emitter_position, left_ear, right_ear,
    ),
  }
}

///|
pub fn SpatialPlayer::set_emitter_position(
  self : SpatialPlayer,
  pos : Array[Double],
) -> Unit {
  self.inner.set_emitter_position(pos)
}

///|
pub fn SpatialPlayer::set_left_ear_position(
  self : SpatialPlayer,
  pos : Array[Double],
) -> Unit {
  self.inner.set_left_ear_position(pos)
}

///|
pub fn SpatialPlayer::set_right_ear_position(
  self : SpatialPlayer,
  pos : Array[Double],
) -> Unit {
  self.inner.set_right_ear_position(pos)
}

///|
pub fn[S : Source] SpatialPlayer::append(
  self : SpatialPlayer,
  source : S,
) -> Unit {
  self.inner.append(source)
}

///|
pub fn SpatialPlayer::volume(self : SpatialPlayer) -> Sample {
  self.inner.volume()
}

///|
pub fn SpatialPlayer::set_volume(self : SpatialPlayer, value : Sample) -> Unit {
  self.inner.set_volume(value)
}

///|
pub fn SpatialPlayer::speed(self : SpatialPlayer) -> Sample {
  self.inner.speed()
}

///|
pub fn SpatialPlayer::set_speed(self : SpatialPlayer, value : Sample) -> Unit {
  self.inner.set_speed(value)
}

///|
pub fn SpatialPlayer::play(self : SpatialPlayer) -> Unit {
  self.inner.play()
}

///|
pub fn SpatialPlayer::pause(self : SpatialPlayer) -> Unit {
  self.inner.pause()
}

///|
pub fn SpatialPlayer::is_paused(self : SpatialPlayer) -> Bool {
  self.inner.is_paused()
}

///|
pub fn SpatialPlayer::clear(self : SpatialPlayer) -> Unit {
  self.inner.clear()
}

///|
pub fn SpatialPlayer::stop(self : SpatialPlayer) -> Unit {
  self.inner.stop()
}

///|
pub fn SpatialPlayer::detach(self : SpatialPlayer) -> Unit {
  self.inner.detach()
}

///|
pub fn SpatialPlayer::sleep_until_end(self : SpatialPlayer) -> Unit {
  self.inner.sleep_until_end()
}

///|
pub fn SpatialPlayer::empty(self : SpatialPlayer) -> Bool {
  self.inner.empty()
}

///|
pub fn SpatialPlayer::len(self : SpatialPlayer) -> Int {
  self.inner.len()
}

///|
pub fn SpatialPlayer::try_seek(
  self : SpatialPlayer,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub fn SpatialPlayer::get_pos(self : SpatialPlayer) -> @moon_cpal.Duration {
  self.inner.get_pos()
}
