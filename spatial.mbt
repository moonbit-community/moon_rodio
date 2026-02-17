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
fn clone_vec3(v : Array[Double]) -> Array[Double] {
  guard v.length() == 3 else { panic() }
  [v[0], v[1], v[2]]
}

///|
fn dist_sq(a : Array[Double], b : Array[Double]) -> Double {
  guard a.length() == 3 else { panic() }
  guard b.length() == 3 else { panic() }
  let dx = a[0] - b[0]
  let dy = a[1] - b[1]
  let dz = a[2] - b[2]
  dx * dx + dy * dy + dz * dz
}

///|
fn calc_spatial_gains(
  emitter_pos : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> (Sample, Sample) {
  let left_dist_sq = dist_sq(left_ear, emitter_pos)
  let right_dist_sq = dist_sq(right_ear, emitter_pos)

  let mut max_diff = @math.hypot(dist_sq(left_ear, right_ear), 0.0)
  if max_diff < 1.0e-9 {
    max_diff = 1.0
  }

  let left_dist = @math.hypot(left_dist_sq, 0.0)
  let right_dist = @math.hypot(right_dist_sq, 0.0)

  let left_diff_modifier = ((left_dist - right_dist) / max_diff + 1.0) / 4.0 +
    0.5
  let right_diff_modifier = ((right_dist - left_dist) / max_diff + 1.0) / 4.0 +
    0.5

  let left_dist_modifier = if left_dist_sq <= 1.0e-9 {
    1.0
  } else {
    let v = 1.0 / left_dist_sq
    if v < 1.0 {
      v
    } else {
      1.0
    }
  }
  let right_dist_modifier = if right_dist_sq <= 1.0e-9 {
    1.0
  } else {
    let v = 1.0 / right_dist_sq
    if v < 1.0 {
      v
    } else {
      1.0
    }
  }

  let left_diff_capped = if left_diff_modifier < 1.0 {
    left_diff_modifier
  } else {
    1.0
  }
  let right_diff_capped = if right_diff_modifier < 1.0 {
    right_diff_modifier
  } else {
    1.0
  }

  (
    left_diff_capped * left_dist_modifier,
    right_diff_capped * right_dist_modifier,
  )
}

///|
pub struct SpatialSource {
  input : DynSource
  emitter_position : Ref[Array[Double]]
  left_ear : Ref[Array[Double]]
  right_ear : Ref[Array[Double]]
  left_gain : Ref[Sample]
  right_gain : Ref[Sample]
  pending_mono : Ref[Sample]
  has_pending : Ref[Bool]
  pending_channel : Ref[Int]
}

///|
pub fn[S : Source] SpatialSource::new(
  input : S,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> SpatialSource {
  let emitter = clone_vec3(emitter_position)
  let left = clone_vec3(left_ear)
  let right = clone_vec3(right_ear)
  let (lg, rg) = calc_spatial_gains(emitter, left, right)

  {
    input: to_dyn(input),
    emitter_position: @ref.new(emitter),
    left_ear: @ref.new(left),
    right_ear: @ref.new(right),
    left_gain: @ref.new(lg),
    right_gain: @ref.new(rg),
    pending_mono: @ref.new(0.0),
    has_pending: @ref.new(false),
    pending_channel: @ref.new(0),
  }
}

///|
pub fn SpatialSource::set_positions(
  self : SpatialSource,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> Unit {
  self.emitter_position.val = clone_vec3(emitter_position)
  self.left_ear.val = clone_vec3(left_ear)
  self.right_ear.val = clone_vec3(right_ear)
  let (lg, rg) = calc_spatial_gains(
    self.emitter_position.val,
    self.left_ear.val,
    self.right_ear.val,
  )
  self.left_gain.val = lg
  self.right_gain.val = rg
}

///|
fn SpatialSource::next_mono_frame(self : SpatialSource) -> Sample? {
  let ch = self.input.channels()
  guard ch > 0 else { panic() }

  let mut sum = 0.0
  for i in 0..<ch {
    match self.input.next() {
      None => if i == 0 { return None } else { return None }
      Some(v) => sum += v
    }
  }
  Some(sum / Double::from_int(ch))
}

///|
pub fn SpatialSource::next(self : SpatialSource) -> Sample? {
  if !self.has_pending.val {
    match self.next_mono_frame() {
      None => return None
      Some(v) => {
        self.pending_mono.val = v
        self.has_pending.val = true
        self.pending_channel.val = 0
      }
    }
  }

  let out = if self.pending_channel.val == 0 {
    self.pending_channel.val = 1
    self.pending_mono.val * self.left_gain.val
  } else {
    self.pending_channel.val = 0
    self.has_pending.val = false
    self.pending_mono.val * self.right_gain.val
  }

  Some(out)
}

///|
pub fn SpatialSource::channels(_self : SpatialSource) -> ChannelCount {
  2
}

///|
pub fn SpatialSource::sample_rate(self : SpatialSource) -> SampleRate {
  self.input.sample_rate()
}

///|
pub impl Source for SpatialSource with next(self : SpatialSource) {
  self.next()
}

///|
pub impl Source for SpatialSource with channels(self : SpatialSource) {
  self.channels()
}

///|
pub impl Source for SpatialSource with sample_rate(self : SpatialSource) {
  self.sample_rate()
}

///|
pub impl Source for SpatialSource with current_span_len(self : SpatialSource) {
  self.input.current_span_len()
}

///|
pub impl Source for SpatialSource with total_duration(self : SpatialSource) {
  self.input.total_duration()
}

///|
pub impl Source for SpatialSource with try_seek(
  self : SpatialSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.input.try_seek(pos)
}

///|
priv struct SpatialSinkSource {
  inner : SpatialSource
  emitter_position : Ref[Array[Double]]
  left_ear : Ref[Array[Double]]
  right_ear : Ref[Array[Double]]
}

///|
fn[S : Source] spatial_sink_source_new(
  input : S,
  emitter_position : Ref[Array[Double]],
  left_ear : Ref[Array[Double]],
  right_ear : Ref[Array[Double]],
) -> SpatialSinkSource {
  {
    inner: SpatialSource::new(
      input,
      emitter_position.val,
      left_ear.val,
      right_ear.val,
    ),
    emitter_position,
    left_ear,
    right_ear,
  }
}

///|
fn SpatialSinkSource::next(self : SpatialSinkSource) -> Sample? {
  self.inner.set_positions(
    self.emitter_position.val,
    self.left_ear.val,
    self.right_ear.val,
  )
  self.inner.next()
}

///|
impl Source for SpatialSinkSource with next(self : SpatialSinkSource) {
  self.next()
}

///|
impl Source for SpatialSinkSource with channels(self : SpatialSinkSource) {
  self.inner.channels()
}

///|
impl Source for SpatialSinkSource with sample_rate(self : SpatialSinkSource) {
  self.inner.sample_rate()
}

///|
impl Source for SpatialSinkSource with current_span_len(
  self : SpatialSinkSource,
) {
  self.inner.current_span_len()
}

///|
impl Source for SpatialSinkSource with total_duration(self : SpatialSinkSource) {
  self.inner.total_duration()
}

///|
impl Source for SpatialSinkSource with try_seek(
  self : SpatialSinkSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}

///|
pub struct SpatialSink {
  sink : Sink
  emitter_position : Ref[Array[Double]]
  left_ear : Ref[Array[Double]]
  right_ear : Ref[Array[Double]]
}

///|
pub fn SpatialSink::connect_new(
  mixer : Mixer,
  emitter_position : Array[Double],
  left_ear : Array[Double],
  right_ear : Array[Double],
) -> SpatialSink {
  {
    sink: Sink::connect_new(mixer),
    emitter_position: @ref.new(clone_vec3(emitter_position)),
    left_ear: @ref.new(clone_vec3(left_ear)),
    right_ear: @ref.new(clone_vec3(right_ear)),
  }
}

///|
pub fn SpatialSink::set_emitter_position(
  self : SpatialSink,
  pos : Array[Double],
) -> Unit {
  self.emitter_position.val = clone_vec3(pos)
}

///|
pub fn SpatialSink::set_left_ear_position(
  self : SpatialSink,
  pos : Array[Double],
) -> Unit {
  self.left_ear.val = clone_vec3(pos)
}

///|
pub fn SpatialSink::set_right_ear_position(
  self : SpatialSink,
  pos : Array[Double],
) -> Unit {
  self.right_ear.val = clone_vec3(pos)
}

///|
pub fn[S : Source] SpatialSink::append(self : SpatialSink, source : S) -> Unit {
  let spatial = spatial_sink_source_new(
    source,
    self.emitter_position,
    self.left_ear,
    self.right_ear,
  )
  self.sink.append(spatial)
}

///|
pub fn SpatialSink::volume(self : SpatialSink) -> Sample {
  self.sink.volume()
}

///|
pub fn SpatialSink::set_volume(self : SpatialSink, value : Sample) -> Unit {
  self.sink.set_volume(value)
}

///|
pub fn SpatialSink::speed(self : SpatialSink) -> Sample {
  self.sink.speed()
}

///|
pub fn SpatialSink::set_speed(self : SpatialSink, value : Sample) -> Unit {
  self.sink.set_speed(value)
}

///|
pub fn SpatialSink::play(self : SpatialSink) -> Unit {
  self.sink.play()
}

///|
pub fn SpatialSink::pause(self : SpatialSink) -> Unit {
  self.sink.pause()
}

///|
pub fn SpatialSink::is_paused(self : SpatialSink) -> Bool {
  self.sink.is_paused()
}

///|
pub fn SpatialSink::clear(self : SpatialSink) -> Unit {
  self.sink.clear()
}

///|
pub fn SpatialSink::stop(self : SpatialSink) -> Unit {
  self.sink.stop()
}

///|
pub fn SpatialSink::skip_one(self : SpatialSink) -> Unit {
  self.sink.skip_one()
}

///|
pub fn SpatialSink::detach(self : SpatialSink) -> Unit {
  self.sink.detach()
}

///|
pub fn SpatialSink::sleep_until_end(self : SpatialSink) -> Unit {
  self.sink.sleep_until_end()
}

///|
pub fn SpatialSink::empty(self : SpatialSink) -> Bool {
  self.sink.empty()
}

///|
pub fn SpatialSink::len(self : SpatialSink) -> Int {
  self.sink.len()
}

///|
pub fn SpatialSink::try_seek(
  self : SpatialSink,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.sink.try_seek(pos)
}

///|
pub fn SpatialSink::get_pos(self : SpatialSink) -> @moon_cpal.Duration {
  self.sink.get_pos()
}
