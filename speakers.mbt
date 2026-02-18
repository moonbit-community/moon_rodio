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
pub suberror SpeakersListError {
  DevicesError(@moon_cpal.DevicesError)
} derive(Show, Eq)

///|
pub suberror SpeakersError {
  NoDevice
  NoConfig
  DefaultOutputConfigError(@moon_cpal.DefaultStreamConfigError)
  SupportedOutputConfigsError(@moon_cpal.SupportedStreamConfigsError)
  UnsupportedByDevice
  DeviceSinkError(DeviceSinkError)
} derive(Show, Eq)

///|
pub struct Output {
  inner : @moon_cpal.Device
  default : Bool
}

///|
pub fn Output::into_inner(self : Output) -> @moon_cpal.Device {
  self.inner
}

///|
pub fn Output::is_default(self : Output) -> Bool {
  self.default
}

///|
pub fn Output::name(self : Output) -> String {
  try self.inner.name() catch {
    _ => "unknown"
  } noraise {
    name => name
  }
}

///|
pub fn available_outputs() -> Array[Output] raise SpeakersListError {
  let host = @moon_cpal.default_host()
  let default_id = match host.default_output_device() {
    None => None
    Some(device) => Some(device.id()) catch { _ => None }
  }
  let devices = try host.output_devices() catch {
    err => raise SpeakersListError::DevicesError(err)
  } noraise {
    xs => xs
  }

  let out : Array[Output] = []
  for device in devices {
    let is_default = match default_id {
      None => false
      Some(id) => {
        let current_id = Some(device.id()) catch { _ => None }
        match current_id {
          None => false
          Some(current) => current == id
        }
      }
    }
    out.push({ inner: device, default: is_default })
  }
  out
}

///|
pub struct OutputConfig {
  channel_count : ChannelCount
  sample_rate : SampleRate
  buffer_size : @moon_cpal.BufferSize
  sample_format : @moon_cpal.SampleFormat
} derive(Show, Eq)

///|
pub fn OutputConfig::default() -> OutputConfig {
  {
    channel_count: 1,
    sample_rate: hz_44100,
    buffer_size: @moon_cpal.BufferSize::default(),
    sample_format: @moon_cpal.SampleFormat::F32,
  }
}

///|
pub fn OutputConfig::new(
  channel_count : ChannelCount,
  sample_rate : SampleRate,
  buffer_size : @moon_cpal.BufferSize,
  sample_format : @moon_cpal.SampleFormat,
) -> OutputConfig {
  guard channel_count > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channel_count, sample_rate, buffer_size, sample_format }
}

///|
pub fn OutputConfig::with_channel_count(
  self : OutputConfig,
  channel_count : ChannelCount,
) -> OutputConfig {
  OutputConfig::new(
    channel_count,
    self.sample_rate,
    self.buffer_size,
    self.sample_format,
  )
}

///|
pub fn OutputConfig::with_sample_rate(
  self : OutputConfig,
  sample_rate : SampleRate,
) -> OutputConfig {
  OutputConfig::new(
    self.channel_count,
    sample_rate,
    self.buffer_size,
    self.sample_format,
  )
}

///|
pub fn OutputConfig::with_buffer_size(
  self : OutputConfig,
  buffer_size : @moon_cpal.BufferSize,
) -> OutputConfig {
  OutputConfig::new(
    self.channel_count,
    self.sample_rate,
    buffer_size,
    self.sample_format,
  )
}

///|
pub fn OutputConfig::with_sample_format(
  self : OutputConfig,
  sample_format : @moon_cpal.SampleFormat,
) -> OutputConfig {
  OutputConfig::new(
    self.channel_count,
    self.sample_rate,
    self.buffer_size,
    sample_format,
  )
}

///|
fn OutputConfig::with_f32_samples(self : OutputConfig) -> OutputConfig {
  { ..self, sample_format: @moon_cpal.SampleFormat::F32 }
}

///|
pub fn OutputConfig::supported_given(
  self : OutputConfig,
  supported : @moon_cpal.SupportedStreamConfigRange,
) -> Bool {
  let buffer_ok = match self.buffer_size {
    @moon_cpal.BufferSize::Default => true
    @moon_cpal.BufferSize::Fixed(n_frames) =>
      supported.buffer_size().contains(n_frames * self.channel_count)
  }

  buffer_ok &&
  self.channel_count == supported.channels() &&
  self.sample_format == supported.sample_format() &&
  self.sample_rate <= supported.max_sample_rate() &&
  self.sample_rate >= supported.min_sample_rate()
}

///|
pub fn OutputConfig::from_supported(
  value : @moon_cpal.SupportedStreamConfig,
) -> OutputConfig {
  {
    channel_count: value.channels(),
    sample_rate: value.sample_rate(),
    buffer_size: @moon_cpal.BufferSize::default(),
    sample_format: value.sample_format(),
  }
}

///|
pub struct SpeakersBuilder {
  device : @moon_cpal.Device?
  supported_configs : Array[@moon_cpal.SupportedStreamConfigRange]
  config : OutputConfig?
  error_callback : (@moon_cpal.StreamError) -> Unit
}

///|
fn speakers_default_error_callback(err : @moon_cpal.StreamError) -> Unit {
  println("speaker stream error: \{err}")
}

///|
pub fn SpeakersBuilder::new() -> SpeakersBuilder {
  {
    device: None,
    supported_configs: [],
    config: None,
    error_callback: speakers_default_error_callback,
  }
}

///|
fn collect_supported_output_configs(
  device : @moon_cpal.Device,
) -> Array[@moon_cpal.SupportedStreamConfigRange] raise SpeakersError {
  let ranges = try device.supported_output_configs() catch {
    err => raise SpeakersError::SupportedOutputConfigsError(err)
  } noraise {
    xs => xs
  }
  let out : Array[@moon_cpal.SupportedStreamConfigRange] = []
  for range in ranges {
    out.push(range)
  }
  out
}

///|
fn SpeakersBuilder::with_device_inner(
  self : SpeakersBuilder,
  device : @moon_cpal.Device,
) -> SpeakersBuilder raise SpeakersError {
  let supported_configs = collect_supported_output_configs(device)
  { ..self, device: Some(device), supported_configs, config: None }
}

///|
pub fn SpeakersBuilder::device(
  self : SpeakersBuilder,
  output : Output,
) -> SpeakersBuilder raise SpeakersError {
  self.with_device_inner(output.into_inner())
}

///|
pub fn SpeakersBuilder::default_device(
  self : SpeakersBuilder,
) -> SpeakersBuilder raise SpeakersError {
  let host = @moon_cpal.default_host()
  match host.default_output_device() {
    None => raise SpeakersError::NoDevice
    Some(device) => self.with_device_inner(device)
  }
}

///|
fn SpeakersBuilder::config_supported(
  self : SpeakersBuilder,
  config : OutputConfig,
) -> Bool {
  for range in self.supported_configs {
    if config.supported_given(range) {
      return true
    }
  }
  false
}

///|
fn SpeakersBuilder::check_config(
  self : SpeakersBuilder,
  config : OutputConfig,
) -> Unit raise SpeakersError {
  guard self.device is Some(_) else { raise SpeakersError::NoDevice }
  guard self.config_supported(config) else {
    raise SpeakersError::UnsupportedByDevice
  }
}

///|
pub fn SpeakersBuilder::default_config(
  self : SpeakersBuilder,
) -> SpeakersBuilder raise SpeakersError {
  let device = match self.device {
    None => raise SpeakersError::NoDevice
    Some(device) => device
  }
  let default_config = try device.default_output_config() catch {
    err => raise SpeakersError::DefaultOutputConfigError(err)
  } noraise {
    cfg => cfg
  }
  let config = OutputConfig::from_supported(default_config)
  let preferred = config.with_f32_samples()
  let selected = if self.config_supported(preferred) {
    preferred
  } else {
    config
  }
  { ..self, config: Some(selected) }
}

///|
pub fn SpeakersBuilder::config(
  self : SpeakersBuilder,
  config : OutputConfig,
) -> SpeakersBuilder raise SpeakersError {
  self.check_config(config)
  { ..self, config: Some(config) }
}

///|
pub fn SpeakersBuilder::with_error_callback(
  self : SpeakersBuilder,
  callback : (@moon_cpal.StreamError) -> Unit,
) -> SpeakersBuilder {
  { ..self, error_callback: callback }
}

///|
pub fn SpeakersBuilder::get_config(
  self : SpeakersBuilder,
) -> OutputConfig raise SpeakersError {
  match self.config {
    None => raise SpeakersError::NoConfig
    Some(config) => config
  }
}

///|
pub fn SpeakersBuilder::try_sample_rate(
  self : SpeakersBuilder,
  sample_rate : SampleRate,
) -> SpeakersBuilder raise SpeakersError {
  let current = self.get_config()
  let next = { ..current, sample_rate, }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn SpeakersBuilder::prefer_sample_rates(
  self : SpeakersBuilder,
  sample_rates : Array[SampleRate],
) -> SpeakersBuilder {
  let current = match self.config {
    None => return self
    Some(config) => config
  }

  let mut selected = current
  for sample_rate in sample_rates {
    let candidate = { ..current, sample_rate, }
    if self.config_supported(candidate) {
      selected = candidate
      break
    }
  }
  { ..self, config: Some(selected) }
}

///|
pub fn SpeakersBuilder::try_channels(
  self : SpeakersBuilder,
  channel_count : ChannelCount,
) -> SpeakersBuilder raise SpeakersError {
  let current = self.get_config()
  let next = { ..current, channel_count, }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn SpeakersBuilder::prefer_channel_counts(
  self : SpeakersBuilder,
  channel_counts : Array[ChannelCount],
) -> SpeakersBuilder {
  let current = match self.config {
    None => return self
    Some(config) => config
  }

  let mut selected = current
  for channel_count in channel_counts {
    let candidate = { ..current, channel_count, }
    if self.config_supported(candidate) {
      selected = candidate
      break
    }
  }
  { ..self, config: Some(selected) }
}

///|
pub fn SpeakersBuilder::try_buffer_size(
  self : SpeakersBuilder,
  buffer_size : Int,
) -> SpeakersBuilder raise SpeakersError {
  let current = self.get_config()
  let next = {
    ..current,
    buffer_size: @moon_cpal.BufferSize::fixed(buffer_size),
  }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn SpeakersBuilder::prefer_buffer_sizes(
  self : SpeakersBuilder,
  buffer_sizes : Array[Int],
) -> SpeakersBuilder {
  let current = match self.config {
    None => return self
    Some(config) => config
  }

  let mut selected = current
  for size in buffer_sizes {
    if size >= 100_000 {
      break
    }
    let candidate = {
      ..current,
      buffer_size: @moon_cpal.BufferSize::fixed(size),
    }
    if self.config_supported(candidate) {
      selected = candidate
      break
    }
  }
  { ..self, config: Some(selected) }
}

///|
pub fn SpeakersBuilder::open_mixer(
  self : SpeakersBuilder,
) -> MixerDeviceSink raise SpeakersError {
  let device = match self.device {
    None => raise SpeakersError::NoDevice
    Some(device) => device
  }
  let config = match self.config {
    None => raise SpeakersError::NoConfig
    Some(config) => config
  }

  let builder = DeviceSinkBuilder::default()
    .with_device(device)
    .with_channels(config.channel_count)
    .with_sample_rate(config.sample_rate)
    .with_buffer_size(config.buffer_size)
    .with_sample_format(config.sample_format)
    .with_error_callback(self.error_callback)

  try builder.open_stream() catch {
    err => raise SpeakersError::DeviceSinkError(err)
  } noraise {
    sink => sink
  }
}
