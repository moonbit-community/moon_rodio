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
  max_buffered_samples : Int
  config : InputConfig
  error_occurred : Ref[Bool]
}

///|
fn microphone_compact_queue(
  queue : Ref[Array[Sample]],
  read_pos : Ref[Int],
) -> Unit {
  if read_pos.val >= 4096 && read_pos.val * 2 >= queue.val.length() {
    let remaining : Array[Sample] = []
    for i in read_pos.val..<queue.val.length() {
      remaining.push(queue.val[i])
    }
    queue.val = remaining
    read_pos.val = 0
  }
}

///|
fn microphone_push_sample(
  queue : Ref[Array[Sample]],
  read_pos : Ref[Int],
  max_buffered_samples : Int,
  sample : Sample,
) -> Unit {
  queue.val.push(sample)

  let buffered = queue.val.length() - read_pos.val
  if buffered > max_buffered_samples {
    read_pos.val += buffered - max_buffered_samples
  }
  microphone_compact_queue(queue, read_pos)
}

///|
fn read_u16_le(bytes : FixedArray[Byte], offset : Int) -> UInt16? {
  if offset + 2 > bytes.length() {
    None
  } else {
    Some(
      bytes[offset].to_int().to_uint16() |
      (bytes[offset + 1].to_int().to_uint16() << 8),
    )
  }
}

///|
fn read_u32_le(bytes : FixedArray[Byte], offset : Int) -> UInt? {
  if offset + 4 > bytes.length() {
    None
  } else {
    Some(
      bytes[offset].to_int().reinterpret_as_uint() |
      (bytes[offset + 1].to_int().reinterpret_as_uint() << 8) |
      (bytes[offset + 2].to_int().reinterpret_as_uint() << 16) |
      (bytes[offset + 3].to_int().reinterpret_as_uint() << 24),
    )
  }
}

///|
fn read_u64_le(bytes : FixedArray[Byte], offset : Int) -> UInt64? {
  if offset + 8 > bytes.length() {
    None
  } else {
    Some(
      bytes[offset].to_int().to_uint64() |
      (bytes[offset + 1].to_int().to_uint64() << 8) |
      (bytes[offset + 2].to_int().to_uint64() << 16) |
      (bytes[offset + 3].to_int().to_uint64() << 24) |
      (bytes[offset + 4].to_int().to_uint64() << 32) |
      (bytes[offset + 5].to_int().to_uint64() << 40) |
      (bytes[offset + 6].to_int().to_uint64() << 48) |
      (bytes[offset + 7].to_int().to_uint64() << 56),
    )
  }
}

///|
fn sample_from_i8(value : Int) -> Sample {
  Double::from_int(value) / 128.0
}

///|
fn sample_from_u8(value : Byte) -> Sample {
  Double::from_int(value.to_int()) / 255.0 * 2.0 - 1.0
}

///|
fn sample_from_i16(value : Int16) -> Sample {
  Double::from_int(value.to_int()) / 32768.0
}

///|
fn sample_from_u16(value : UInt16) -> Sample {
  Double::from_int(value.to_int()) / 65535.0 * 2.0 - 1.0
}

///|
fn sample_from_i24(value : Int) -> Sample {
  Double::from_int(value) / 8_388_608.0
}

///|
fn sample_from_u24(value : Int) -> Sample {
  Double::from_int(value) / 16_777_215.0 * 2.0 - 1.0
}

///|
fn sample_from_i32(value : Int) -> Sample {
  Double::from_int(value) / 2_147_483_648.0
}

///|
fn sample_from_u32(value : UInt) -> Sample {
  value.to_double() / 4_294_967_295.0 * 2.0 - 1.0
}

///|
fn sample_from_i64(value : Int64) -> Sample {
  value.to_double() / 9_223_372_036_854_775_808.0
}

///|
fn sample_from_u64(value : UInt64) -> Sample {
  value.to_double() / 18_446_744_073_709_551_615.0 * 2.0 - 1.0
}

///|
fn microphone_push_raw_samples(
  queue : Ref[Array[Sample]],
  read_pos : Ref[Int],
  max_buffered_samples : Int,
  data : @moon_cpal.Data,
) -> Unit {
  let format = data.sample_format()
  let len = data.len()
  let bytes = data.bytes()

  match format {
    @moon_cpal.SampleFormat::I8 =>
      for i in 0..<len {
        let raw = bytes[i].to_int()
        let sample = sample_from_i8(if raw >= 128 { raw - 256 } else { raw })
        microphone_push_sample(queue, read_pos, max_buffered_samples, sample)
      }
    @moon_cpal.SampleFormat::U8 =>
      for i in 0..<len {
        microphone_push_sample(
          queue,
          read_pos,
          max_buffered_samples,
          sample_from_u8(bytes[i]),
        )
      }
    @moon_cpal.SampleFormat::I16 =>
      for i in 0..<len {
        match read_u16_le(bytes, i * 2) {
          None => break
          Some(bits) => {
            let sample = sample_from_i16(Int16::reinterpret_from_uint16(bits))
            microphone_push_sample(
              queue, read_pos, max_buffered_samples, sample,
            )
          }
        }
      }
    @moon_cpal.SampleFormat::U16 =>
      for i in 0..<len {
        match read_u16_le(bytes, i * 2) {
          None => break
          Some(v) =>
            microphone_push_sample(
              queue,
              read_pos,
              max_buffered_samples,
              sample_from_u16(v),
            )
        }
      }
    @moon_cpal.SampleFormat::I24 =>
      for i in 0..<len {
        let offset = i * 3
        if offset + 3 > bytes.length() {
          break
        }
        let u = bytes[offset].to_int().reinterpret_as_uint() |
          (bytes[offset + 1].to_int().reinterpret_as_uint() << 8) |
          (bytes[offset + 2].to_int().reinterpret_as_uint() << 16)
        let signed = if (u & (0x00800000 : UInt)) != (0 : UInt) {
          (u | (0xff000000 : UInt)).reinterpret_as_int()
        } else {
          u.reinterpret_as_int()
        }
        microphone_push_sample(
          queue,
          read_pos,
          max_buffered_samples,
          sample_from_i24(signed),
        )
      }
    @moon_cpal.SampleFormat::U24 =>
      for i in 0..<len {
        let offset = i * 3
        if offset + 3 > bytes.length() {
          break
        }
        let u = bytes[offset].to_int() |
          (bytes[offset + 1].to_int() << 8) |
          (bytes[offset + 2].to_int() << 16)
        microphone_push_sample(
          queue,
          read_pos,
          max_buffered_samples,
          sample_from_u24(u),
        )
      }
    @moon_cpal.SampleFormat::I32 =>
      for i in 0..<len {
        match read_u32_le(bytes, i * 4) {
          None => break
          Some(bits) => {
            let sample = sample_from_i32(bits.reinterpret_as_int())
            microphone_push_sample(
              queue, read_pos, max_buffered_samples, sample,
            )
          }
        }
      }
    @moon_cpal.SampleFormat::U32 =>
      for i in 0..<len {
        match read_u32_le(bytes, i * 4) {
          None => break
          Some(v) =>
            microphone_push_sample(
              queue,
              read_pos,
              max_buffered_samples,
              sample_from_u32(v),
            )
        }
      }
    @moon_cpal.SampleFormat::F32 =>
      for i in 0..<len {
        match read_u32_le(bytes, i * 4) {
          None => break
          Some(bits) => {
            let sample = Float::reinterpret_from_uint(bits).to_double()
            microphone_push_sample(
              queue, read_pos, max_buffered_samples, sample,
            )
          }
        }
      }
    @moon_cpal.SampleFormat::I64 =>
      for i in 0..<len {
        match read_u64_le(bytes, i * 8) {
          None => break
          Some(bits) => {
            let sample = sample_from_i64(bits.reinterpret_as_int64())
            microphone_push_sample(
              queue, read_pos, max_buffered_samples, sample,
            )
          }
        }
      }
    @moon_cpal.SampleFormat::U64 =>
      for i in 0..<len {
        match read_u64_le(bytes, i * 8) {
          None => break
          Some(v) =>
            microphone_push_sample(
              queue,
              read_pos,
              max_buffered_samples,
              sample_from_u64(v),
            )
        }
      }
    @moon_cpal.SampleFormat::F64 =>
      for i in 0..<len {
        match read_u64_le(bytes, i * 8) {
          None => break
          Some(bits) =>
            microphone_push_sample(
              queue,
              read_pos,
              max_buffered_samples,
              bits.reinterpret_as_double(),
            )
        }
      }
    _ => ()
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
  microphone_compact_queue(queue, read_pos)
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
  let max_buffered_samples = Int::max(
    1,
    config.channel_count * config.sample_rate / 10,
  )
  let stream_config = config.stream_config()
  let on_error = fn(err : @moon_cpal.StreamError) {
    error_occurred.val = true
    error_callback(err)
  }

  let format_supported = match config.sample_format {
    @moon_cpal.SampleFormat::I8
    | @moon_cpal.SampleFormat::I16
    | @moon_cpal.SampleFormat::I24
    | @moon_cpal.SampleFormat::I32
    | @moon_cpal.SampleFormat::I64
    | @moon_cpal.SampleFormat::U8
    | @moon_cpal.SampleFormat::U16
    | @moon_cpal.SampleFormat::U24
    | @moon_cpal.SampleFormat::U32
    | @moon_cpal.SampleFormat::U64
    | @moon_cpal.SampleFormat::F32
    | @moon_cpal.SampleFormat::F64 => true
    _ => false
  }
  guard format_supported else { raise MicrophoneError::UnsupportedSampleFormat }

  let stream = match config.sample_format {
    _ =>
      try
        device.build_input_stream_raw(
          stream_config,
          config.sample_format,
          fn(data, _) {
            microphone_push_raw_samples(
              queue, read_pos, max_buffered_samples, data,
            )
          },
          on_error,
          None,
        )
      catch {
        err => raise MicrophoneError::BuildStreamError(err)
      } noraise {
        s => s
      }
  }

  stream.play() catch {
    err => raise MicrophoneError::PlayStreamError(err)
  }

  {
    _stream_handle: stream,
    queued_samples: queue,
    read_pos,
    max_buffered_samples,
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
    @core.sleep_millis(1)
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
