///|
fn effects_duration_to_sample_count(
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
pub fn[S : Source] limit(
  source : S,
  min_value : Sample,
  max_value : Sample,
) -> DynSource {
  guard min_value <= max_value else { panic() }
  let src = to_dyn(source)
  DynSource::new_dynamic(
    fn() {
      match src.next() {
        None => None
        Some(v) =>
          if v < min_value {
            Some(min_value)
          } else if v > max_value {
            Some(max_value)
          } else {
            Some(v)
          }
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
  )
}

///|
pub fn[S : Source] distortion(source : S, threshold : Sample) -> DynSource {
  distortion_with_gain(source, 1.0, threshold)
}

///|
pub fn[S : Source] distortion_with_gain(
  source : S,
  gain : Sample,
  threshold : Sample,
) -> DynSource {
  guard gain >= 0.0 else { panic() }
  guard threshold >= 0.0 else { panic() }
  limit(amplify(source, gain), -threshold, threshold)
}

///|
pub fn[A : Source, B : Source] crossfade(
  left : A,
  right : B,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let lhs = to_dyn(left)
  let rhs = uniform_source(to_dyn(right), lhs.channels(), lhs.sample_rate())
  let fade_samples = effects_duration_to_sample_count(
    duration,
    lhs.channels(),
    lhs.sample_rate(),
  )
  let idx = @ref.new(0)

  DynSource::new_dynamic(
    fn() {
      if fade_samples > 0 && idx.val < fade_samples {
        let t = Double::from_int(idx.val) / Double::from_int(fade_samples)
        idx.val += 1
        match (lhs.next(), rhs.next()) {
          (None, None) => None
          (Some(a), None) => Some(a * (1.0 - t))
          (None, Some(b)) => Some(b * t)
          (Some(a), Some(b)) => Some(a * (1.0 - t) + b * t)
        }
      } else {
        rhs.next()
      }
    },
    fn() { lhs.channels() },
    fn() { lhs.sample_rate() },
  )
}

///|
pub fn[A : Source, B : Source] take_crossfade_with(
  left : A,
  right : B,
  duration : @moon_cpal.Duration,
) -> DynSource {
  crossfade(left, right, duration)
}

///|
pub fn[S : Source] reverb(
  source : S,
  duration : @moon_cpal.Duration,
  amplitude : Sample,
) -> DynSource {
  let buf = buffered(source)
  let channels = buf.channels()
  let sample_rate = buf.sample_rate()
  let dry = SamplesBuffer::new(channels, sample_rate, buf.samples)
  let wet = delay(
    amplify(SamplesBuffer::new(channels, sample_rate, buf.samples), amplitude),
    duration,
  )
  mix(dry, wet)
}
