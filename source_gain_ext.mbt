///|
fn gain_duration_to_sample_count(
  duration : @moon_cpal.Duration,
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> Int {
  if channels <= 0 || sample_rate <= 0 {
    return 0
  }

  let per_second = channels * sample_rate
  let secs_part = duration.secs.to_int() * per_second
  let nanos_part = duration.nanos * per_second / 1_000_000_000
  secs_part + nanos_part
}

///|
fn gain_duration_to_nanos(duration : @moon_cpal.Duration) -> Double {
  Double::from_int(duration.secs.to_int()) * 1_000_000_000.0 +
  Double::from_int(duration.nanos)
}

///|
pub fn[S : Source] channel_volume(
  source : S,
  channel_factors : Array[Sample],
) -> DynSource {
  guard !channel_factors.is_empty() else { panic() }
  let src = to_dyn(source)
  let from_channels = src.channels()
  let out_channels = channel_factors.length()
  let current_channel = @ref.new(out_channels)
  let current_sample = @ref.new(None)

  DynSource::new_dynamic(
    fn() {
      if current_channel.val >= out_channels {
        current_channel.val = 0
        current_sample.val = None
        for _ in 0..<from_channels {
          match src.next() {
            None => ()
            Some(s) =>
              current_sample.val = Some(current_sample.val.unwrap_or(0.0) + s)
          }
        }
        current_sample.val = current_sample.val.map(fn(v) {
          v / Double::from_int(from_channels)
        })
      }

      let result = current_sample.val.map(fn(v) {
        v * channel_factors[current_channel.val]
      })
      current_channel.val += 1
      result
    },
    fn() { out_channels },
    fn() { src.sample_rate() },
  )
}

///|
pub fn[S : Source] linear_gain_ramp(
  source : S,
  start_gain : Sample,
  end_gain : Sample,
  duration : @moon_cpal.Duration,
) -> DynSource {
  linear_gain_ramp_with_clamp(source, start_gain, end_gain, duration, true)
}

///|
pub fn[S : Source] linear_gain_ramp_with_clamp(
  source : S,
  start_gain : Sample,
  end_gain : Sample,
  duration : @moon_cpal.Duration,
  clamp_end : Bool,
) -> DynSource {
  guard duration.secs > (0 : UInt64) || duration.nanos > 0 else { panic() }
  let src = to_dyn(source)
  let elapsed_ns = @ref.new(0.0)
  let total_ns = gain_duration_to_nanos(duration)
  let sample_idx = @ref.new(0)

  DynSource::new_dynamic(
    fn() {
      match src.next() {
        None => None
        Some(v) => {
          let remaining_ns = total_ns - elapsed_ns.val
          let factor = if remaining_ns < 0.0 && clamp_end {
            end_gain
          } else if remaining_ns < 0.0 {
            1.0
          } else {
            let p = elapsed_ns.val / total_ns
            start_gain * (1.0 - p) + end_gain * p
          }

          sample_idx.val += 1
          let channels = src.channels()
          if channels > 0 && sample_idx.val % channels == 0 {
            elapsed_ns.val += 1_000_000_000.0 /
              Double::from_int(src.sample_rate())
          }

          Some(v * factor)
        }
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
    current_span_len=fn() { src.current_span_len() },
    total_duration=fn() { src.total_duration() },
    try_seek=fn(pos : @moon_cpal.Duration) {
      elapsed_ns.val = gain_duration_to_nanos(pos)
      try {
        src.try_seek(pos)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
pub fn[S : Source] fade_in(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  linear_gain_ramp(source, 0.0, 1.0, duration)
}

///|
pub fn[S : Source] fadein(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  fade_in(source, duration)
}

///|
pub fn[S : Source] fade_out(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let buf = buffered(source)
  let data = buf.samples
  let len = data.length()
  let count = gain_duration_to_sample_count(
    duration,
    buf.channels(),
    buf.sample_rate(),
  )

  if count <= 0 || len == 0 {
    return to_dyn(buf)
  }

  let n = if count < len { count } else { len }
  let start = len - n
  for i in 0..<n {
    let t = Double::from_int(i + 1) / Double::from_int(n)
    data[start + i] *= 1.0 - t
  }

  to_dyn(SamplesBuffer::new(buf.channels(), buf.sample_rate(), data))
}

///|
pub fn[S : Source] fadeout(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  fade_out(source, duration)
}
