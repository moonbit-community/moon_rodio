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
pub suberror MicrophoneListError {
  DevicesError(@moon_cpal.DevicesError)
} derive(Show, Eq)

///|
pub suberror MicrophoneError {
  NoDevice
  NoConfig
  DefaultInputConfigError(@moon_cpal.DefaultStreamConfigError)
  SupportedInputConfigsError(@moon_cpal.SupportedStreamConfigsError)
  UnsupportedByDevice
  BuildStreamError(@moon_cpal.BuildStreamError)
  PlayStreamError(@moon_cpal.PlayStreamError)
  UnsupportedSampleFormat
} derive(Show, Eq)

///|
pub struct Input {
  inner : @moon_cpal.Device
}

///|
pub fn Input::into_inner(self : Input) -> @moon_cpal.Device {
  self.inner
}

///|
pub fn Input::name(self : Input) -> String {
  try self.inner.name() catch {
    _ => "unknown"
  } noraise {
    name => name
  }
}

///|
pub fn available_inputs() -> Array[Input] raise MicrophoneListError {
  let host = @moon_cpal.default_host()
  let devices = try host.input_devices() catch {
    err => raise MicrophoneListError::DevicesError(err)
  } noraise {
    xs => xs
  }

  let out : Array[Input] = []
  for device in devices {
    out.push({ inner: device })
  }
  out
}

///|
pub struct InputConfig {
  channel_count : ChannelCount
  sample_rate : SampleRate
  buffer_size : @moon_cpal.BufferSize
  sample_format : @moon_cpal.SampleFormat
} derive(Show, Eq)

///|
pub fn InputConfig::default() -> InputConfig {
  {
    channel_count: 1,
    sample_rate: hz_44100,
    buffer_size: @moon_cpal.BufferSize::default(),
    sample_format: @moon_cpal.SampleFormat::F32,
  }
}

///|
pub fn InputConfig::new(
  channel_count : ChannelCount,
  sample_rate : SampleRate,
  buffer_size : @moon_cpal.BufferSize,
  sample_format : @moon_cpal.SampleFormat,
) -> InputConfig {
  guard channel_count > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channel_count, sample_rate, buffer_size, sample_format }
}

///|
pub fn InputConfig::with_channel_count(
  self : InputConfig,
  channel_count : ChannelCount,
) -> InputConfig {
  InputConfig::new(
    channel_count,
    self.sample_rate,
    self.buffer_size,
    self.sample_format,
  )
}

///|
pub fn InputConfig::with_sample_rate(
  self : InputConfig,
  sample_rate : SampleRate,
) -> InputConfig {
  InputConfig::new(
    self.channel_count,
    sample_rate,
    self.buffer_size,
    self.sample_format,
  )
}

///|
pub fn InputConfig::with_buffer_size(
  self : InputConfig,
  buffer_size : @moon_cpal.BufferSize,
) -> InputConfig {
  InputConfig::new(
    self.channel_count,
    self.sample_rate,
    buffer_size,
    self.sample_format,
  )
}

///|
pub fn InputConfig::with_sample_format(
  self : InputConfig,
  sample_format : @moon_cpal.SampleFormat,
) -> InputConfig {
  InputConfig::new(
    self.channel_count,
    self.sample_rate,
    self.buffer_size,
    sample_format,
  )
}

///|
pub fn InputConfig::stream_config(
  self : InputConfig,
) -> @moon_cpal.StreamConfig {
  @moon_cpal.StreamConfig::new(
    self.channel_count,
    self.sample_rate,
    self.buffer_size,
  )
}

///|
fn InputConfig::with_f32_samples(self : InputConfig) -> InputConfig {
  { ..self, sample_format: @moon_cpal.SampleFormat::F32 }
}

///|
pub fn InputConfig::supported_given(
  self : InputConfig,
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
pub fn InputConfig::from_supported(
  value : @moon_cpal.SupportedStreamConfig,
) -> InputConfig {
  {
    channel_count: value.channels(),
    sample_rate: value.sample_rate(),
    buffer_size: @moon_cpal.BufferSize::default(),
    sample_format: value.sample_format(),
  }
}

///|
pub struct MicrophoneBuilder {
  device : @moon_cpal.Device?
  supported_configs : Array[@moon_cpal.SupportedStreamConfigRange]
  config : InputConfig?
  error_callback : (@moon_cpal.StreamError) -> Unit
}

///|
fn microphone_default_error_callback(err : @moon_cpal.StreamError) -> Unit {
  println("microphone stream error: \{err}")
}

///|
pub fn MicrophoneBuilder::new() -> MicrophoneBuilder {
  {
    device: None,
    supported_configs: [],
    config: None,
    error_callback: microphone_default_error_callback,
  }
}

///|
fn collect_supported_input_configs(
  device : @moon_cpal.Device,
) -> Array[@moon_cpal.SupportedStreamConfigRange] raise MicrophoneError {
  let ranges = try device.supported_input_configs() catch {
    err => raise MicrophoneError::SupportedInputConfigsError(err)
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
fn MicrophoneBuilder::with_device_inner(
  self : MicrophoneBuilder,
  device : @moon_cpal.Device,
) -> MicrophoneBuilder raise MicrophoneError {
  let supported_configs = collect_supported_input_configs(device)
  { ..self, device: Some(device), supported_configs, config: None }
}

///|
pub fn MicrophoneBuilder::device(
  self : MicrophoneBuilder,
  device : Input,
) -> MicrophoneBuilder raise MicrophoneError {
  self.with_device_inner(device.into_inner())
}

///|
pub fn MicrophoneBuilder::default_device(
  self : MicrophoneBuilder,
) -> MicrophoneBuilder raise MicrophoneError {
  let host = @moon_cpal.default_host()
  match host.default_input_device() {
    None => raise MicrophoneError::NoDevice
    Some(device) => self.with_device_inner(device)
  }
}

///|
fn MicrophoneBuilder::config_supported(
  self : MicrophoneBuilder,
  config : InputConfig,
) -> Bool {
  for range in self.supported_configs {
    if config.supported_given(range) {
      return true
    }
  }
  false
}

///|
fn MicrophoneBuilder::check_config(
  self : MicrophoneBuilder,
  config : InputConfig,
) -> Unit raise MicrophoneError {
  guard self.device is Some(_) else { raise MicrophoneError::NoDevice }
  guard self.config_supported(config) else {
    raise MicrophoneError::UnsupportedByDevice
  }
}

///|
pub fn MicrophoneBuilder::default_config(
  self : MicrophoneBuilder,
) -> MicrophoneBuilder raise MicrophoneError {
  let device = match self.device {
    None => raise MicrophoneError::NoDevice
    Some(device) => device
  }
  let default_config = try device.default_input_config() catch {
    err => raise MicrophoneError::DefaultInputConfigError(err)
  } noraise {
    cfg => cfg
  }
  let config = InputConfig::from_supported(default_config)
  let preferred = config.with_f32_samples()
  let selected = if self.config_supported(preferred) {
    preferred
  } else {
    config
  }
  { ..self, config: Some(selected) }
}

///|
pub fn MicrophoneBuilder::config(
  self : MicrophoneBuilder,
  config : InputConfig,
) -> MicrophoneBuilder raise MicrophoneError {
  self.check_config(config)
  { ..self, config: Some(config) }
}

///|
pub fn MicrophoneBuilder::with_error_callback(
  self : MicrophoneBuilder,
  callback : (@moon_cpal.StreamError) -> Unit,
) -> MicrophoneBuilder {
  { ..self, error_callback: callback }
}

///|
pub fn MicrophoneBuilder::get_config(
  self : MicrophoneBuilder,
) -> InputConfig raise MicrophoneError {
  match self.config {
    None => raise MicrophoneError::NoConfig
    Some(config) => config
  }
}

///|
pub fn MicrophoneBuilder::try_sample_rate(
  self : MicrophoneBuilder,
  sample_rate : SampleRate,
) -> MicrophoneBuilder raise MicrophoneError {
  let current = self.get_config()
  let next = { ..current, sample_rate, }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn MicrophoneBuilder::prefer_sample_rates(
  self : MicrophoneBuilder,
  sample_rates : Array[SampleRate],
) -> MicrophoneBuilder {
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
pub fn MicrophoneBuilder::try_channels(
  self : MicrophoneBuilder,
  channel_count : ChannelCount,
) -> MicrophoneBuilder raise MicrophoneError {
  let current = self.get_config()
  let next = { ..current, channel_count, }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn MicrophoneBuilder::prefer_channel_counts(
  self : MicrophoneBuilder,
  channel_counts : Array[ChannelCount],
) -> MicrophoneBuilder {
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
pub fn MicrophoneBuilder::try_buffer_size(
  self : MicrophoneBuilder,
  buffer_size : Int,
) -> MicrophoneBuilder raise MicrophoneError {
  let current = self.get_config()
  let next = {
    ..current,
    buffer_size: @moon_cpal.BufferSize::fixed(buffer_size),
  }
  self.check_config(next)
  { ..self, config: Some(next) }
}

///|
pub fn MicrophoneBuilder::prefer_buffer_sizes(
  self : MicrophoneBuilder,
  buffer_sizes : Array[Int],
) -> MicrophoneBuilder {
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
pub struct Microphone {
  _stream_handle : @moon_cpal.Stream
  queued_samples : Ref[Array[Sample]]
  read_pos : Ref[Int]
  config : InputConfig
  error_occurred : Ref[Bool]
}

///|
fn[A : @moon_cpal.Sample] microphone_push_samples(
  queue : Ref[Array[Sample]],
  samples : Array[A],
) -> Unit {
  for sample in samples {
    queue.val.push(@moon_cpal.sample_cast(sample))
  }
}

///|
fn microphone_pop_next(
  queue : Ref[Array[Sample]],
  read_pos : Ref[Int],
) -> Sample? {
  if read_pos.val >= queue.val.length() {
    return None
  }

  let out = queue.val[read_pos.val]
  read_pos.val += 1

  if read_pos.val >= 4096 && read_pos.val * 2 >= queue.val.length() {
    let remaining : Array[Sample] = []
    for i in read_pos.val..<queue.val.length() {
      remaining.push(queue.val[i])
    }
    queue.val = remaining
    read_pos.val = 0
  }

  Some(out)
}

///|
fn microphone_open(
  device : @moon_cpal.Device,
  config : InputConfig,
  error_callback : (@moon_cpal.StreamError) -> Unit,
) -> Microphone raise MicrophoneError {
  let queue = @ref.new([])
  let read_pos = @ref.new(0)
  let error_occurred = @ref.new(false)
  let stream_config = config.stream_config()
  let on_error = fn(err : @moon_cpal.StreamError) {
    error_occurred.val = true
    error_callback(err)
  }

  let stream = match config.sample_format {
    @moon_cpal.SampleFormat::F32 =>
      try
        device.build_input_stream_f32(
          stream_config,
          fn(data, _) { microphone_push_samples(queue, data) },
          on_error,
          None,
        )
      catch {
        err => raise MicrophoneError::BuildStreamError(err)
      } noraise {
        s => s
      }
    @moon_cpal.SampleFormat::I16 =>
      try
        device.build_input_stream_i16(
          stream_config,
          fn(data, _) { microphone_push_samples(queue, data) },
          on_error,
          None,
        )
      catch {
        err => raise MicrophoneError::BuildStreamError(err)
      } noraise {
        s => s
      }
    @moon_cpal.SampleFormat::U16 =>
      try
        device.build_input_stream_u16(
          stream_config,
          fn(data, _) { microphone_push_samples(queue, data) },
          on_error,
          None,
        )
      catch {
        err => raise MicrophoneError::BuildStreamError(err)
      } noraise {
        s => s
      }
    @moon_cpal.SampleFormat::U8 =>
      try
        device.build_input_stream_u8(
          stream_config,
          fn(data, _) { microphone_push_samples(queue, data) },
          on_error,
          None,
        )
      catch {
        err => raise MicrophoneError::BuildStreamError(err)
      } noraise {
        s => s
      }
    _ => raise MicrophoneError::UnsupportedSampleFormat
  }

  stream.play() catch {
    err => raise MicrophoneError::PlayStreamError(err)
  }

  {
    _stream_handle: stream,
    queued_samples: queue,
    read_pos,
    config,
    error_occurred,
  }
}

///|
pub fn MicrophoneBuilder::open_stream(
  self : MicrophoneBuilder,
) -> Microphone raise MicrophoneError {
  let device = match self.device {
    None => raise MicrophoneError::NoDevice
    Some(device) => device
  }
  let config = match self.config {
    None => raise MicrophoneError::NoConfig
    Some(config) => config
  }
  microphone_open(device, config, self.error_callback)
}

///|
pub fn Microphone::config(self : Microphone) -> InputConfig {
  self.config
}

///|
pub fn Microphone::next(self : Microphone) -> Sample? {
  while true {
    match microphone_pop_next(self.queued_samples, self.read_pos) {
      Some(sample) => return Some(sample)
      None => if self.error_occurred.val { return None }
    }
  }
  None
}

///|
pub impl Source for Microphone with next(self : Microphone) {
  self.next()
}

///|
pub impl Source for Microphone with channels(self : Microphone) {
  self.config.channel_count
}

///|
pub impl Source for Microphone with sample_rate(self : Microphone) {
  self.config.sample_rate
}

///|
pub impl Source for Microphone with current_span_len(_self : Microphone) {
  None
}

///|
pub impl Source for Microphone with total_duration(_self : Microphone) {
  None
}

///|
pub impl Source for Microphone with try_seek(
  _self : Microphone,
  _pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  raise SeekError::NotSupported
}
