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
fn skip_samples(input : DynSource, count : Int) -> Unit {
  let limit = if count < 0 { 0 } else { count }
  for _ in 0..<limit {
    if input.next() is None {
      break
    }
  }
}

///|
fn skip_duration_unchecked(
  input : DynSource,
  duration : @moon_cpal.Duration,
) -> Unit {
  let to_skip = duration_to_sample_count(
    duration,
    input.channels(),
    input.sample_rate(),
  )
  skip_samples(input, to_skip)
}

///|
fn skip_duration_span_aware(
  input : DynSource,
  duration : @moon_cpal.Duration,
) -> Unit {
  let remaining = @ref.new(duration)
  while duration_compare(
          remaining.val,
          @moon_cpal.Duration::from_secs((0 : UInt64)),
        ) >
        0 {
    match input.current_span_len() {
      None => {
        skip_duration_unchecked(input, remaining.val)
        return
      }
      Some(span_len) => {
        if span_len <= 0 {
          return
        }

        let samples_to_skip = duration_to_sample_count(
          remaining.val,
          input.channels(),
          input.sample_rate(),
        )
        if samples_to_skip <= 0 {
          return
        }

        if samples_to_skip < span_len {
          skip_samples(input, samples_to_skip)
          return
        }

        skip_samples(input, span_len)
        let skipped_duration = match
          duration_from_sample_count(
            span_len,
            input.channels(),
            input.sample_rate(),
          ) {
          Some(v) => v
          None => @moon_cpal.Duration::from_secs((0 : UInt64))
        }
        remaining.val = duration_saturating_sub(remaining.val, skipped_duration)
      }
    }
  }
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
  let src = to_dyn(source)
  let channels = src.channels()
  let sample_rate = src.sample_rate()
  let sample_count = duration_to_sample_count(duration, channels, sample_rate)
  let remaining = @ref.new(sample_count)

  DynSource::new_dynamic(
    fn() {
      if remaining.val <= 0 {
        None
      } else {
        match src.next() {
          None => {
            remaining.val = 0
            None
          }
          Some(v) => {
            remaining.val -= 1
            Some(v)
          }
        }
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
    current_span_len=fn() {
      let rem = if remaining.val <= 0 { 0 } else { remaining.val }
      match src.current_span_len() {
        None => Some(rem)
        Some(v) => Some(if v < rem { v } else { rem })
      }
    },
    total_duration=fn() {
      src.total_duration().map(fn(v) { duration_min(v, duration) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
      try {
        src.try_seek(pos)
        let target = sample_index_from_duration(pos, channels, sample_rate)
        remaining.val = if target >= sample_count {
          0
        } else {
          sample_count - target
        }
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
pub fn[S : Source] skip_duration(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let src = to_dyn(source)
  skip_duration_span_aware(src, duration)

  DynSource::new_dynamic(
    fn() { src.next() },
    fn() { src.channels() },
    fn() { src.sample_rate() },
    current_span_len=fn() { src.current_span_len() },
    total_duration=fn() {
      src.total_duration().map(fn(v) { duration_saturating_sub(v, duration) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
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
pub fn[S : Source] delay(
  source : S,
  duration : @moon_cpal.Duration,
) -> DynSource {
  let src = to_dyn(source)
  let channels = src.channels()
  let sample_rate = src.sample_rate()
  let remaining = @ref.new(
    duration_to_sample_count(duration, channels, sample_rate),
  )

  DynSource::new_dynamic(
    fn() {
      if remaining.val > 0 {
        remaining.val -= 1
        Some(0.0)
      } else {
        src.next()
      }
    },
    fn() { src.channels() },
    fn() { src.sample_rate() },
    current_span_len=fn() {
      let rem = if remaining.val > 0 { remaining.val } else { 0 }
      src.current_span_len().map(fn(v) { v + rem })
    },
    total_duration=fn() {
      src.total_duration().map(fn(v) { duration_add(v, duration) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
      let zero = @moon_cpal.Duration::from_secs((0 : UInt64))
      if duration_compare(pos, duration) < 0 {
        let until_playback = duration_saturating_sub(duration, pos)
        let rem = duration_to_sample_count(
          until_playback, channels, sample_rate,
        )
        try {
          src.try_seek(zero)
          remaining.val = rem
          Ok(())
        } catch {
          err => Err(err)
        }
      } else {
        let compensated = duration_saturating_sub(pos, duration)
        try {
          src.try_seek(compensated)
          remaining.val = 0
          Ok(())
        } catch {
          err => Err(err)
        }
      }
    },
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
