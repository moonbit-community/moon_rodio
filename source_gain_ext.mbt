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
pub fn[S : Source] channel_volume(
  source : S,
  channel_factors : Array[Sample],
) -> DynSource {
  guard !channel_factors.is_empty() else { panic() }
  let src = to_dyn(source)
  let channels = src.channels()
  let cursor = @ref.new(0)

  DynSource::new(
    fn() {
      match src.next() {
        None => None
        Some(v) => {
          let ch = cursor.val % channels
          cursor.val += 1
          let factor = if ch < channel_factors.length() {
            channel_factors[ch]
          } else {
            1.0
          }
          Some(v * factor)
        }
      }
    },
    channels,
    src.sample_rate(),
  )
}

///|
pub fn[S : Source] linear_gain_ramp(
  source : S,
  start_gain : Sample,
  end_gain : Sample,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let src = to_dyn(source)
  let sample_count = gain_duration_to_sample_count(
    duration,
    src.channels(),
    src.sample_rate(),
  )
  let idx = @ref.new(0)

  DynSource::new(
    fn() {
      match src.next() {
        None => None
        Some(v) => {
          let factor = if sample_count <= 0 {
            end_gain
          } else if idx.val >= sample_count {
            end_gain
          } else {
            let t = Double::from_int(idx.val) / Double::from_int(sample_count)
            start_gain + (end_gain - start_gain) * t
          }
          idx.val += 1
          Some(v * factor)
        }
      }
    },
    src.channels(),
    src.sample_rate(),
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
