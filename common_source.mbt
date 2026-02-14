///|
pub type Sample = Double

///|
pub type ChannelCount = Int

///|
pub type SampleRate = Int

///|
let hz_44100 : SampleRate = 44_100

///|
pub trait Source {
  next(Self) -> Sample?
  channels(Self) -> ChannelCount
  sample_rate(Self) -> SampleRate
  current_span_len(Self) -> Int?
  total_duration(Self) -> @moon_cpal.Duration?
  try_seek(Self, pos : @moon_cpal.Duration) -> Unit raise SeekError
}

///|
pub struct DynSource {
  next_sample : () -> Sample?
  channels_fn : () -> ChannelCount
  sample_rate_fn : () -> SampleRate
  current_span_len_fn : () -> Int?
  total_duration_fn : () -> @moon_cpal.Duration?
  try_seek_fn : (@moon_cpal.Duration) -> Result[Unit, SeekError]
}

///|
fn source_default_try_seek_result(
  pos : @moon_cpal.Duration,
) -> Result[Unit, SeekError] {
  try {
    source_default_try_seek(pos)
    Ok(())
  } catch {
    err => Err(err)
  }
}

///|
pub fn DynSource::new(
  next_sample : () -> Sample?,
  channels : ChannelCount,
  sample_rate : SampleRate,
  current_span_len? : () -> Int? = source_default_current_span_len,
  total_duration? : () -> @moon_cpal.Duration? = source_default_total_duration,
  try_seek? : (@moon_cpal.Duration) -> Result[Unit, SeekError] = source_default_try_seek_result,
) -> DynSource {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  {
    next_sample,
    channels_fn: fn() { channels },
    sample_rate_fn: fn() { sample_rate },
    current_span_len_fn: current_span_len,
    total_duration_fn: total_duration,
    try_seek_fn: try_seek,
  }
}

///|
pub fn DynSource::new_dynamic(
  next_sample : () -> Sample?,
  channels : () -> ChannelCount,
  sample_rate : () -> SampleRate,
  current_span_len? : () -> Int? = source_default_current_span_len,
  total_duration? : () -> @moon_cpal.Duration? = source_default_total_duration,
  try_seek? : (@moon_cpal.Duration) -> Result[Unit, SeekError] = source_default_try_seek_result,
) -> DynSource {
  guard channels() > 0 else { panic() }
  guard sample_rate() > 0 else { panic() }
  {
    next_sample,
    channels_fn: channels,
    sample_rate_fn: sample_rate,
    current_span_len_fn: current_span_len,
    total_duration_fn: total_duration,
    try_seek_fn: try_seek,
  }
}

///|
pub fn DynSource::next(self : DynSource) -> Sample? {
  (self.next_sample)()
}

///|
pub fn DynSource::channels(self : DynSource) -> ChannelCount {
  (self.channels_fn)()
}

///|
pub fn DynSource::sample_rate(self : DynSource) -> SampleRate {
  (self.sample_rate_fn)()
}

///|
pub fn DynSource::current_span_len(self : DynSource) -> Int? {
  (self.current_span_len_fn)()
}

///|
pub fn DynSource::total_duration(self : DynSource) -> @moon_cpal.Duration? {
  (self.total_duration_fn)()
}

///|
pub fn DynSource::try_seek(
  self : DynSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  match (self.try_seek_fn)(pos) {
    Ok(_) => ()
    Err(err) => raise err
  }
}

///|
pub impl Source for DynSource with next(self : DynSource) {
  self.next()
}

///|
pub impl Source for DynSource with channels(self : DynSource) {
  self.channels()
}

///|
pub impl Source for DynSource with sample_rate(self : DynSource) {
  self.sample_rate()
}

///|
pub impl Source for DynSource with current_span_len(_self : DynSource) {
  _self.current_span_len()
}

///|
pub impl Source for DynSource with total_duration(_self : DynSource) {
  _self.total_duration()
}

///|
pub impl Source for DynSource with try_seek(
  _self : DynSource,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  _self.try_seek(pos)
}

///|
pub fn[S : Source] to_dyn(source : S) -> DynSource {
  DynSource::new_dynamic(
    fn() { source.next() },
    fn() { source.channels() },
    fn() { source.sample_rate() },
    current_span_len=fn() { source.current_span_len() },
    total_duration=fn() { source.total_duration() },
    try_seek=fn(pos : @moon_cpal.Duration) {
      try {
        source.try_seek(pos)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}

///|
pub struct SamplesBuffer {
  channels : ChannelCount
  sample_rate : SampleRate
  samples : Array[Sample]
  cursor : Ref[Int]
}

///|
pub fn SamplesBuffer::new(
  channels : ChannelCount,
  sample_rate : SampleRate,
  samples : Array[Sample],
) -> SamplesBuffer {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channels, sample_rate, samples, cursor: @ref.new(0) }
}

///|
pub fn SamplesBuffer::channels(self : SamplesBuffer) -> ChannelCount {
  self.channels
}

///|
pub fn SamplesBuffer::sample_rate(self : SamplesBuffer) -> SampleRate {
  self.sample_rate
}

///|
pub fn SamplesBuffer::next(self : SamplesBuffer) -> Sample? {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let value = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(value)
  }
}

///|
fn duration_from_sample_count(
  total_samples : Int,
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> @moon_cpal.Duration? {
  if total_samples < 0 || channels <= 0 || sample_rate <= 0 {
    return None
  }
  let per_second = channels.to_uint64() * sample_rate.to_uint64()
  let total = total_samples.to_uint64()
  let secs = total / per_second
  let rem_samples = total % per_second
  let nanos = (rem_samples * (1_000_000_000 : UInt64) / per_second).to_int()
  Some(@moon_cpal.Duration::new(secs, nanos))
}

///|
fn sample_index_from_duration(
  pos : @moon_cpal.Duration,
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> Int {
  if channels <= 0 || sample_rate <= 0 {
    return 0
  }
  let per_second = sample_rate.to_uint64() * channels.to_uint64()
  let secs_part = pos.secs * per_second
  let nanos_part = pos.nanos.to_uint64() * per_second / (1_000_000_000 : UInt64)
  (secs_part + nanos_part).to_int()
}

///|
fn duration_secs_f64(pos : @moon_cpal.Duration) -> Double {
  Double::from_int(pos.secs.to_int()) +
  Double::from_int(pos.nanos) / 1_000_000_000.0
}

///|
fn duration_from_secs_floor(secs : Double) -> @moon_cpal.Duration {
  if secs <= 0.0 {
    @moon_cpal.Duration::from_secs((0 : UInt64))
  } else {
    let secs_int = secs.to_int()
    let frac = secs - Double::from_int(secs_int)
    let nanos = (frac * 1_000_000_000.0).to_int()
    @moon_cpal.Duration::new(secs_int.to_uint64(), nanos)
  }
}

///|
fn duration_mul_ratio_floor(
  pos : @moon_cpal.Duration,
  ratio : Double,
) -> @moon_cpal.Duration {
  duration_from_secs_floor(duration_secs_f64(pos) * ratio)
}

///|
fn duration_div_ratio_floor(
  pos : @moon_cpal.Duration,
  ratio : Double,
) -> @moon_cpal.Duration {
  if ratio <= 0.0 {
    @moon_cpal.Duration::from_secs((0 : UInt64))
  } else {
    duration_from_secs_floor(duration_secs_f64(pos) / ratio)
  }
}

///|
fn duration_compare(a : @moon_cpal.Duration, b : @moon_cpal.Duration) -> Int {
  if a.secs < b.secs {
    -1
  } else if a.secs > b.secs {
    1
  } else if a.nanos < b.nanos {
    -1
  } else if a.nanos > b.nanos {
    1
  } else {
    0
  }
}

///|
fn duration_min(
  a : @moon_cpal.Duration,
  b : @moon_cpal.Duration,
) -> @moon_cpal.Duration {
  if duration_compare(a, b) <= 0 {
    a
  } else {
    b
  }
}

///|
fn duration_add(
  a : @moon_cpal.Duration,
  b : @moon_cpal.Duration,
) -> @moon_cpal.Duration {
  @moon_cpal.Duration::new(a.secs + b.secs, a.nanos + b.nanos)
}

///|
fn duration_saturating_sub(
  a : @moon_cpal.Duration,
  b : @moon_cpal.Duration,
) -> @moon_cpal.Duration {
  if duration_compare(a, b) <= 0 {
    @moon_cpal.Duration::from_secs((0 : UInt64))
  } else if a.nanos >= b.nanos {
    @moon_cpal.Duration::new(a.secs - b.secs, a.nanos - b.nanos)
  } else {
    @moon_cpal.Duration::new(
      a.secs - b.secs - (1 : UInt64),
      a.nanos + 1_000_000_000 - b.nanos,
    )
  }
}

///|
fn source_default_current_span_len() -> Int? {
  None
}

///|
fn source_default_total_duration() -> @moon_cpal.Duration? {
  None
}

///|
fn source_default_try_seek(_pos : @moon_cpal.Duration) -> Unit raise SeekError {
  raise SeekError::NotSupported
}

///|
pub fn SamplesBuffer::amplify(
  self : SamplesBuffer,
  factor : Sample,
) -> DynSource {
  let src = to_dyn(self)
  DynSource::new(
    fn() {
      match src.next() {
        None => None
        Some(v) => Some(v * factor)
      }
    },
    src.channels(),
    src.sample_rate(),
  )
}

///|
pub impl Source for SamplesBuffer with next(self : SamplesBuffer) {
  self.next()
}

///|
pub impl Source for SamplesBuffer with channels(self : SamplesBuffer) {
  self.channels()
}

///|
pub impl Source for SamplesBuffer with sample_rate(self : SamplesBuffer) {
  self.sample_rate()
}

///|
pub impl Source for SamplesBuffer with current_span_len(self : SamplesBuffer) {
  let remaining = self.samples.length() - self.cursor.val
  if remaining <= 0 {
    Some(0)
  } else {
    Some(remaining)
  }
}

///|
pub impl Source for SamplesBuffer with total_duration(self : SamplesBuffer) {
  duration_from_sample_count(
    self.samples.length(),
    self.channels(),
    self.sample_rate(),
  )
}

///|
pub impl Source for SamplesBuffer with try_seek(
  self : SamplesBuffer,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  let target = sample_index_from_duration(
    pos,
    self.channels(),
    self.sample_rate(),
  )
  let clamped = if target < 0 {
    0
  } else if target > self.samples.length() {
    self.samples.length()
  } else {
    target
  }
  self.cursor.val = clamped
}

///|
fn make_empty_dyn_source(
  channels : ChannelCount,
  sample_rate : SampleRate,
) -> DynSource {
  DynSource::new(fn() { None }, channels, sample_rate, total_duration=fn() {
    Some(@moon_cpal.Duration::from_secs((0 : UInt64)))
  })
}

///|
fn make_zero_dyn_source(
  channels : ChannelCount,
  sample_rate : SampleRate,
  sample_count : Int,
) -> DynSource {
  let remaining = @ref.new(sample_count)
  DynSource::new(
    fn() {
      if remaining.val <= 0 {
        None
      } else {
        remaining.val -= 1
        Some(0.0)
      }
    },
    channels,
    sample_rate,
  )
}

///|
fn channel_convert(
  input : DynSource,
  target_channels : ChannelCount,
) -> DynSource {
  let from = input.channels()
  let to = target_channels
  if from == to {
    return input
  }

  let sample_repeat = @ref.new(None)
  let next_output_sample_pos = @ref.new(0)

  DynSource::new(
    fn() {
      let pos = next_output_sample_pos.val
      let result = if pos == 0 {
        let value = input.next()
        sample_repeat.val = value
        value
      } else if pos < from {
        input.next()
      } else if pos == 1 {
        sample_repeat.val
      } else {
        Some(0.0)
      }

      match result {
        None => None
        Some(value) => {
          next_output_sample_pos.val += 1
          if next_output_sample_pos.val == to {
            next_output_sample_pos.val = 0
            if from > to {
              for _ in to..<from {
                ignore(input.next())
              }
            }
          }
          Some(value)
        }
      }
    },
    to,
    input.sample_rate(),
  )
}

///|
fn read_frame(input : DynSource, channels : ChannelCount) -> Array[Sample]? {
  let frame : Array[Sample] = []
  for _ in 0..<channels {
    match input.next() {
      None => return None
      Some(v) => frame.push(v)
    }
  }
  Some(frame)
}

///|
fn sample_rate_convert(
  input : DynSource,
  target_sample_rate : SampleRate,
) -> DynSource {
  let from_rate = input.sample_rate()
  let to_rate = target_sample_rate
  let channels = input.channels()

  if from_rate == to_rate {
    return input
  }

  let left = @ref.new(read_frame(input, channels))
  let right = @ref.new(read_frame(input, channels))
  let base_index = @ref.new(0)
  let output_index = @ref.new(0)
  let pending = @ref.new([])
  let pending_cursor = @ref.new(0)

  DynSource::new(
    fn() {
      if pending_cursor.val < pending.val.length() {
        let value = pending.val[pending_cursor.val]
        pending_cursor.val += 1
        return Some(value)
      }

      let position_num = output_index.val * from_rate
      let required_left_index = position_num / to_rate
      let frac_num = position_num % to_rate

      while required_left_index > base_index.val {
        match right.val {
          None => break
          Some(rf) => {
            left.val = Some(rf)
            right.val = read_frame(input, channels)
            base_index.val += 1
          }
        }
      }

      let left_frame = match left.val {
        None => return None
        Some(frame) => frame
      }

      let out_frame : Array[Sample] = []
      match right.val {
        None => {
          if frac_num != 0 {
            return None
          }
          for i in 0..<channels {
            out_frame.push(left_frame[i])
          }
        }
        Some(right_frame) => {
          let t = Double::from_int(frac_num) / Double::from_int(to_rate)
          for i in 0..<channels {
            let a = left_frame[i]
            let b = right_frame[i]
            out_frame.push(a + (b - a) * t)
          }
        }
      }

      output_index.val += 1
      pending.val = out_frame
      pending_cursor.val = 1
      Some(pending.val[0])
    },
    channels,
    to_rate,
  )
}

///|
fn uniform_source(
  input : DynSource,
  target_channels : ChannelCount,
  target_sample_rate : SampleRate,
) -> DynSource {
  let sampled = sample_rate_convert(input, target_sample_rate)
  channel_convert(sampled, target_channels)
}
