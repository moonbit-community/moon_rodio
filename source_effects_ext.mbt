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
  let lhs = TakeDuration::new(left, duration)
  lhs.set_filter_fadeout()
  let rhs = FadeIn::new(TakeDuration::new(right, duration), duration)
  mix(lhs, rhs)
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
