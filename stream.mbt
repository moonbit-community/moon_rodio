///|
pub struct OutputStreamConfig {
  channel_count : ChannelCount
  sample_rate : SampleRate
  buffer_size : @moon_cpal.BufferSize
  sample_format : @moon_cpal.SampleFormat
} derive(Show, Eq)

///|
pub fn OutputStreamConfig::default() -> OutputStreamConfig {
  {
    channel_count: 2,
    sample_rate: hz_44100,
    buffer_size: @moon_cpal.BufferSize::default(),
    sample_format: @moon_cpal.SampleFormat::F32,
  }
}

///|
pub fn OutputStreamConfig::channel_count(
  self : OutputStreamConfig,
) -> ChannelCount {
  self.channel_count
}

///|
pub fn OutputStreamConfig::sample_rate(self : OutputStreamConfig) -> SampleRate {
  self.sample_rate
}

///|
pub fn OutputStreamConfig::buffer_size(
  self : OutputStreamConfig,
) -> @moon_cpal.BufferSize {
  self.buffer_size
}

///|
pub fn OutputStreamConfig::sample_format(
  self : OutputStreamConfig,
) -> @moon_cpal.SampleFormat {
  self.sample_format
}

///|
pub suberror StreamError {
  PlayStreamError(@moon_cpal.PlayStreamError)
  DefaultStreamConfigError(@moon_cpal.DefaultStreamConfigError)
  BuildStreamError(@moon_cpal.BuildStreamError)
  SupportedStreamConfigsError(@moon_cpal.SupportedStreamConfigsError)
  NoDevice
  UnsupportedSampleFormat
} derive(Show, Eq)

///|
pub struct OutputStream {
  config : OutputStreamConfig
  mixer : Mixer
  _stream : @moon_cpal.Stream
  log_on_drop : Ref[Bool]
}

///|
pub fn OutputStream::mixer(self : OutputStream) -> Mixer {
  self.mixer
}

///|
pub fn OutputStream::config(self : OutputStream) -> OutputStreamConfig {
  self.config
}

///|
pub fn OutputStream::log_on_drop(self : OutputStream, enabled : Bool) -> Unit {
  self.log_on_drop.val = enabled
}

///|
pub struct OutputStreamBuilder {
  device : @moon_cpal.Device?
  config : OutputStreamConfig
  error_callback : (@moon_cpal.StreamError) -> Unit
}

///|
fn default_error_callback(err : @moon_cpal.StreamError) -> Unit {
  println("audio stream error: \{err}")
}

///|
pub fn OutputStreamBuilder::default() -> OutputStreamBuilder {
  {
    device: None,
    config: OutputStreamConfig::default(),
    error_callback: default_error_callback,
  }
}

///|
pub fn OutputStreamBuilder::from_device(
  device : @moon_cpal.Device,
) -> OutputStreamBuilder raise StreamError {
  let supported = try device.default_output_config() catch {
    err => raise StreamError::DefaultStreamConfigError(err)
  } noraise {
    cfg => cfg
  }
  OutputStreamBuilder::default()
  .with_device(device)
  .with_supported_config(supported)
}

///|
pub fn OutputStreamBuilder::from_default_device() -> OutputStreamBuilder raise StreamError {
  let host = @moon_cpal.default_host()
  match host.default_output_device() {
    None => raise StreamError::NoDevice
    Some(device) => OutputStreamBuilder::from_device(device)
  }
}

///|
pub fn OutputStreamBuilder::open_default_stream() -> OutputStream raise StreamError {
  let builder = OutputStreamBuilder::from_default_device()
  try builder.open_stream() catch {
    original_err => {
      let host = @moon_cpal.default_host()
      let devices = try host.output_devices() catch {
        _ => raise original_err
      } noraise {
        xs => xs
      }

      for device in devices {
        let maybe_stream = try {
          let next_builder = OutputStreamBuilder::from_device(device)
          Some(next_builder.open_stream_or_fallback())
        } catch {
          _ => None
        }
        match maybe_stream {
          Some(stream) => return stream
          None => ()
        }
      }

      raise original_err
    }
  } noraise {
    stream => stream
  }
}

///|
pub fn OutputStreamBuilder::with_device(
  self : OutputStreamBuilder,
  device : @moon_cpal.Device,
) -> OutputStreamBuilder {
  { ..self, device: Some(device) }
}

///|
pub fn OutputStreamBuilder::with_channels(
  self : OutputStreamBuilder,
  channel_count : ChannelCount,
) -> OutputStreamBuilder {
  guard channel_count > 0 else { panic() }
  { ..self, config: { ..self.config, channel_count, } }
}

///|
pub fn OutputStreamBuilder::with_sample_rate(
  self : OutputStreamBuilder,
  sample_rate : SampleRate,
) -> OutputStreamBuilder {
  guard sample_rate > 0 else { panic() }
  { ..self, config: { ..self.config, sample_rate, } }
}

///|
pub fn OutputStreamBuilder::with_buffer_size(
  self : OutputStreamBuilder,
  buffer_size : @moon_cpal.BufferSize,
) -> OutputStreamBuilder {
  { ..self, config: { ..self.config, buffer_size, } }
}

///|
pub fn OutputStreamBuilder::with_sample_format(
  self : OutputStreamBuilder,
  sample_format : @moon_cpal.SampleFormat,
) -> OutputStreamBuilder {
  { ..self, config: { ..self.config, sample_format, } }
}

///|
pub fn OutputStreamBuilder::with_supported_config(
  self : OutputStreamBuilder,
  config : @moon_cpal.SupportedStreamConfig,
) -> OutputStreamBuilder {
  {
    ..self,
    config: {
      ..self.config,
      channel_count: config.channels(),
      sample_rate: config.sample_rate(),
      sample_format: config.sample_format(),
    },
  }
}

///|
pub fn OutputStreamBuilder::with_config(
  self : OutputStreamBuilder,
  config : @moon_cpal.StreamConfig,
) -> OutputStreamBuilder {
  {
    ..self,
    config: {
      ..self.config,
      channel_count: config.channels,
      sample_rate: config.sample_rate,
      buffer_size: config.buffer_size,
    },
  }
}

///|
pub fn OutputStreamBuilder::with_error_callback(
  self : OutputStreamBuilder,
  callback : (@moon_cpal.StreamError) -> Unit,
) -> OutputStreamBuilder {
  { ..self, error_callback: callback }
}

///|
pub fn OutputStreamBuilder::open_stream(
  self : OutputStreamBuilder,
) -> OutputStream raise StreamError {
  match self.device {
    None => raise StreamError::NoDevice
    Some(device) => OutputStream::open(device, self.config, self.error_callback)
  }
}

///|
pub fn OutputStreamBuilder::open_stream_or_fallback(
  self : OutputStreamBuilder,
) -> OutputStream raise StreamError {
  try self.open_stream() catch {
    original_err => {
      let device = match self.device {
        None => raise StreamError::NoDevice
        Some(d) => d
      }
      let configs = supported_output_configs(device)
      for config in configs {
        let attempt = Some(
          OutputStreamBuilder::default()
          .with_device(device)
          .with_supported_config(config)
          .with_error_callback(self.error_callback)
          .open_stream(),
        ) catch {
          _ => None
        }
        match attempt {
          Some(stream) => return stream
          None => ()
        }
      }
      raise original_err
    }
  } noraise {
    stream => stream
  }
}

///|
fn sample_to_i16(value : Sample) -> Int16 {
  let v = if value < -1.0 { -1.0 } else if value > 1.0 { 1.0 } else { value }
  Int16::from_int((v * 32767.0).to_int())
}

///|
fn sample_to_u16(value : Sample) -> UInt16 {
  let v = if value < -1.0 { -1.0 } else if value > 1.0 { 1.0 } else { value }
  ((v * 0.5 + 0.5) * 65535.0).to_int().to_uint16()
}

///|
fn sample_to_u8(value : Sample) -> Byte {
  let v = if value < -1.0 { -1.0 } else if value > 1.0 { 1.0 } else { value }
  ((v * 0.5 + 0.5) * 255.0).to_int().to_byte()
}

///|
fn next_or_silence(samples : MixerSource) -> Sample {
  match samples.next() {
    None => 0.0
    Some(v) => v
  }
}

///|
fn build_output_stream(
  device : @moon_cpal.Device,
  config : OutputStreamConfig,
  samples : MixerSource,
  error_callback : (@moon_cpal.StreamError) -> Unit,
) -> @moon_cpal.Stream raise StreamError {
  let stream_config = @moon_cpal.StreamConfig::new(
    config.channel_count,
    config.sample_rate,
    config.buffer_size,
  )

  match config.sample_format {
    @moon_cpal.SampleFormat::F32 =>
      try
        device.build_output_stream_f32(
          stream_config,
          fn(data, _) {
            for i in 0..<data.length() {
              data[i] = Float::from_double(next_or_silence(samples))
            }
          },
          error_callback,
          None,
        )
      catch {
        err => raise StreamError::BuildStreamError(err)
      } noraise {
        stream => stream
      }
    @moon_cpal.SampleFormat::I16 =>
      try
        device.build_output_stream_i16(
          stream_config,
          fn(data, _) {
            for i in 0..<data.length() {
              data[i] = sample_to_i16(next_or_silence(samples))
            }
          },
          error_callback,
          None,
        )
      catch {
        err => raise StreamError::BuildStreamError(err)
      } noraise {
        stream => stream
      }
    @moon_cpal.SampleFormat::U16 =>
      try
        device.build_output_stream_u16(
          stream_config,
          fn(data, _) {
            for i in 0..<data.length() {
              data[i] = sample_to_u16(next_or_silence(samples))
            }
          },
          error_callback,
          None,
        )
      catch {
        err => raise StreamError::BuildStreamError(err)
      } noraise {
        stream => stream
      }
    @moon_cpal.SampleFormat::U8 =>
      try
        device.build_output_stream_u8(
          stream_config,
          fn(data, _) {
            for i in 0..<data.length() {
              data[i] = sample_to_u8(next_or_silence(samples))
            }
          },
          error_callback,
          None,
        )
      catch {
        err => raise StreamError::BuildStreamError(err)
      } noraise {
        stream => stream
      }
    _ => raise StreamError::UnsupportedSampleFormat
  }
}

///|
pub fn OutputStream::open(
  device : @moon_cpal.Device,
  config : OutputStreamConfig,
  error_callback : (@moon_cpal.StreamError) -> Unit,
) -> OutputStream raise StreamError {
  let (controller, source) = mixer(config.channel_count, config.sample_rate)
  let stream = build_output_stream(device, config, source, error_callback)
  stream.play() catch {
    err => raise StreamError::PlayStreamError(err)
  }
  { config, mixer: controller, _stream: stream, log_on_drop: @ref.new(true) }
}

///|
pub fn supported_output_configs(
  device : @moon_cpal.Device,
) -> Array[@moon_cpal.SupportedStreamConfig] raise StreamError {
  let ranges = try device.supported_output_configs() catch {
    err => raise StreamError::SupportedStreamConfigsError(err)
  } noraise {
    xs => xs
  }

  let out : Array[@moon_cpal.SupportedStreamConfig] = []
  for sf in ranges {
    let max_rate = sf.max_sample_rate()
    let min_rate = sf.min_sample_rate()
    out.push(sf.with_max_sample_rate())
    if hz_44100 < max_rate && hz_44100 > min_rate {
      out.push(sf.with_sample_rate(hz_44100))
    }
    out.push(sf.with_sample_rate(min_rate))
  }
  out
}
