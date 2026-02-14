///|
fn duration_to_sample_count(
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
pub fn[S : Source] buffered(source : S) -> SamplesBuffer {
  let src = to_dyn(source)
  let out : Array[Sample] = []
  while true {
    match src.next() {
      None => break
      Some(v) => out.push(v)
    }
  }
  SamplesBuffer::new(src.channels(), src.sample_rate(), out)
}

///|
pub fn[S : Source] repeat_infinite(source : S) -> DynSource {
  buffered(source).repeat_infinite()
}

///|
pub fn[S : Source] repeat(source : S) -> DynSource {
  repeat_infinite(source)
}

///|
pub fn[S : Source] take_duration(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let sample_count = duration_to_sample_count(
    duration,
    source.channels(),
    source.sample_rate(),
  )
  take(source, sample_count)
}

///|
pub fn[S : Source] skip_duration(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let src = to_dyn(source)
  let remaining = @ref.new(
    duration_to_sample_count(duration, src.channels(), src.sample_rate()),
  )

  DynSource::new(
    fn() {
      while remaining.val > 0 {
        remaining.val -= 1
        match src.next() {
          None => return None
          Some(_) => ()
        }
      }
      src.next()
    },
    src.channels(),
    src.sample_rate(),
  )
}

///|
pub fn[S : Source] delay(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let src = to_dyn(source)
  let remaining = @ref.new(
    duration_to_sample_count(duration, src.channels(), src.sample_rate()),
  )

  DynSource::new(
    fn() {
      if remaining.val > 0 {
        remaining.val -= 1
        Some(0.0)
      } else {
        src.next()
      }
    },
    src.channels(),
    src.sample_rate(),
  )
}

///|
pub fn[S : Source] amplify_decibel(source : S, value : Sample) -> DynSource {
  let factor = @math.pow(10.0, value / 20.0)
  amplify(source, factor)
}

///|
pub fn[S : Source] amplify_normalized(source : S, value : Sample) -> DynSource {
  let mut clamped = value
  if clamped < 0.0 {
    clamped = 0.0
  } else if clamped > 1.0 {
    clamped = 1.0
  }

  let mut amplitude = @math.exp(6.907_755_4 * clamped) / 1000.0
  if clamped < 0.1 {
    amplitude *= clamped * 10.0
  }

  amplify(source, amplitude)
}
