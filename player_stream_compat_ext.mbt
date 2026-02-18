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
pub type DeviceSinkError = StreamError

///|
pub type DeviceSinkConfig = OutputStreamConfig

///|
pub struct MixerDeviceSink {
  inner : OutputStream
}

///|
pub fn MixerDeviceSink::mixer(self : MixerDeviceSink) -> Mixer {
  self.inner.mixer()
}

///|
pub fn MixerDeviceSink::config(self : MixerDeviceSink) -> DeviceSinkConfig {
  self.inner.config()
}

///|
pub fn MixerDeviceSink::log_on_drop(
  self : MixerDeviceSink,
  enabled : Bool,
) -> Unit {
  self.inner.log_on_drop(enabled)
}

///|
pub struct DeviceSinkBuilder {
  inner : OutputStreamBuilder
}

///|
pub fn DeviceSinkBuilder::default() -> DeviceSinkBuilder {
  { inner: OutputStreamBuilder::default() }
}

///|
pub fn DeviceSinkBuilder::from_device(
  device : @moon_cpal.Device,
) -> DeviceSinkBuilder raise DeviceSinkError {
  { inner: OutputStreamBuilder::from_device(device) }
}

///|
pub fn DeviceSinkBuilder::from_default_device() -> DeviceSinkBuilder raise DeviceSinkError {
  { inner: OutputStreamBuilder::from_default_device() }
}

///|
pub fn DeviceSinkBuilder::open_default_sink() -> MixerDeviceSink raise DeviceSinkError {
  { inner: OutputStreamBuilder::open_default_stream() }
}

///|
pub fn DeviceSinkBuilder::with_device(
  self : DeviceSinkBuilder,
  device : @moon_cpal.Device,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_device(device) }
}

///|
pub fn DeviceSinkBuilder::with_channels(
  self : DeviceSinkBuilder,
  channel_count : ChannelCount,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_channels(channel_count) }
}

///|
pub fn DeviceSinkBuilder::with_sample_rate(
  self : DeviceSinkBuilder,
  sample_rate : SampleRate,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_sample_rate(sample_rate) }
}

///|
pub fn DeviceSinkBuilder::with_buffer_size(
  self : DeviceSinkBuilder,
  buffer_size : @moon_cpal.BufferSize,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_buffer_size(buffer_size) }
}

///|
pub fn DeviceSinkBuilder::with_sample_format(
  self : DeviceSinkBuilder,
  sample_format : @moon_cpal.SampleFormat,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_sample_format(sample_format) }
}

///|
pub fn DeviceSinkBuilder::with_supported_config(
  self : DeviceSinkBuilder,
  config : @moon_cpal.SupportedStreamConfig,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_supported_config(config) }
}

///|
pub fn DeviceSinkBuilder::with_config(
  self : DeviceSinkBuilder,
  config : @moon_cpal.StreamConfig,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_config(config) }
}

///|
pub fn DeviceSinkBuilder::with_error_callback(
  self : DeviceSinkBuilder,
  callback : (@moon_cpal.StreamError) -> Unit,
) -> DeviceSinkBuilder {
  { inner: self.inner.with_error_callback(callback) }
}

///|
pub fn DeviceSinkBuilder::config(self : DeviceSinkBuilder) -> DeviceSinkConfig {
  self.inner.config
}

///|
pub fn DeviceSinkBuilder::open_stream(
  self : DeviceSinkBuilder,
) -> MixerDeviceSink raise DeviceSinkError {
  { inner: self.inner.open_stream() }
}

///|
pub fn DeviceSinkBuilder::open_sink_or_fallback(
  self : DeviceSinkBuilder,
) -> MixerDeviceSink raise DeviceSinkError {
  { inner: self.inner.open_stream_or_fallback() }
}

///|
pub struct Player {
  inner : Sink
}

///|
pub fn Player::connect_new(mixer : Mixer) -> Player {
  { inner: Sink::connect_new(mixer) }
}

///|
pub fn Player::new() -> (Player, ControlledQueueSource) {
  let (sink, source) = Sink::new()
  ({ inner: sink }, source)
}

///|
pub fn[S : Source] Player::append(self : Player, source : S) -> Unit {
  self.inner.append(source)
}

///|
pub fn Player::volume(self : Player) -> Sample {
  self.inner.volume()
}

///|
pub fn Player::set_volume(self : Player, value : Sample) -> Unit {
  self.inner.set_volume(value)
}

///|
pub fn Player::speed(self : Player) -> Sample {
  self.inner.speed()
}

///|
pub fn Player::set_speed(self : Player, value : Sample) -> Unit {
  self.inner.set_speed(value)
}

///|
pub fn Player::play(self : Player) -> Unit {
  self.inner.play()
}

///|
pub fn Player::pause(self : Player) -> Unit {
  self.inner.pause()
}

///|
pub fn Player::is_paused(self : Player) -> Bool {
  self.inner.is_paused()
}

///|
pub fn Player::clear(self : Player) -> Unit {
  self.inner.clear()
}

///|
pub fn Player::skip_one(self : Player) -> Unit {
  self.inner.skip_one()
}

///|
pub fn Player::stop(self : Player) -> Unit {
  self.inner.stop()
}

///|
pub fn Player::detach(self : Player) -> Unit {
  self.inner.detach()
}

///|
pub fn Player::sleep_until_end(self : Player) -> Unit {
  self.inner.sleep_until_end()
}

///|
pub fn Player::empty(self : Player) -> Bool {
  self.inner.empty()
}

///|
pub fn Player::len(self : Player) -> Int {
  self.inner.len()
}

///|
pub fn Player::get_pos(self : Player) -> @moon_cpal.Duration {
  self.inner.get_pos()
}

///|
pub fn Player::try_seek(
  self : Player,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  self.inner.try_seek(pos)
}
