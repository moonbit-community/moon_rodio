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
pub fn[S : Source] limit(source : S, settings : LimitSettings) -> DynSource {
  to_dyn(Limit::new(source, settings))
}

///|
pub fn[S : Source] limit_range(
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
pub fn[S : Source] distortion(
  source : S,
  gain : Sample,
  threshold : Sample,
) -> DynSource {
  guard gain >= 0.0 else { panic() }
  guard threshold >= 0.0 else { panic() }
  limit_range(amplify(source, gain), -threshold, threshold)
}

///|
pub fn[S : Source] distortion_with_gain(
  source : S,
  gain : Sample,
  threshold : Sample,
) -> DynSource {
  distortion(source, gain, threshold)
}

///|
pub fn[S : Source] distortion_threshold(
  source : S,
  threshold : Sample,
) -> DynSource {
  distortion(source, 1.0, threshold)
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
  let src = to_dyn(source)
  let channels = src.channels()
  let sample_rate = src.sample_rate()
  let delay_samples = duration_to_sample_count(duration, channels, sample_rate)
  if delay_samples <= 0 {
    return amplify(src, 1.0 + amplitude)
  }

  let delay_line : Array[Sample] = []
  for _ in 0..<delay_samples {
    delay_line.push(0.0)
  }
  let write_idx = @ref.new(0)
  let source_done = @ref.new(false)
  let tail_remaining = @ref.new(0)

  fn step_delay_line(
    line : Array[Sample],
    idx_ref : Ref[Int],
    current : Sample,
    feedback_gain : Sample,
  ) -> Sample {
    let delayed = line[idx_ref.val]
    let out = current + delayed * feedback_gain
    line[idx_ref.val] = current
    idx_ref.val = (idx_ref.val + 1) % line.length()
    out
  }

  DynSource::new_dynamic(
    fn() {
      if source_done.val {
        if tail_remaining.val <= 0 {
          return None
        }
        tail_remaining.val -= 1
        return Some(step_delay_line(delay_line, write_idx, 0.0, amplitude))
      }

      match src.next() {
        Some(v) => Some(step_delay_line(delay_line, write_idx, v, amplitude))
        None => {
          source_done.val = true
          tail_remaining.val = delay_samples
          if tail_remaining.val <= 0 {
            None
          } else {
            tail_remaining.val -= 1
            Some(step_delay_line(delay_line, write_idx, 0.0, amplitude))
          }
        }
      }
    },
    fn() { channels },
    fn() { sample_rate },
    current_span_len=fn() {
      match src.current_span_len() {
        Some(v) => Some(v + delay_samples)
        None => None
      }
    },
    total_duration=fn() {
      src.total_duration().map(fn(v) { duration_add(v, duration) })
    },
    try_seek=fn(pos : @moon_cpal.Duration) {
      let history_duration = duration_min(pos, duration)
      let history_samples = duration_to_sample_count(
        history_duration, channels, sample_rate,
      )

      for i in 0..<delay_samples {
        delay_line[i] = 0.0
      }
      write_idx.val = 0
      source_done.val = false
      tail_remaining.val = 0

      let history_start = duration_saturating_sub(pos, history_duration)
      src.try_seek(history_start) catch {
        err => return Err(err)
      }

      let to_copy = if history_samples < delay_samples {
        history_samples
      } else {
        delay_samples
      }
      for i in 0..<to_copy {
        match src.next() {
          Some(v) => delay_line[i] = v
          None => break
        }
      }
      write_idx.val = to_copy % delay_samples

      try {
        src.try_seek(pos)
        Ok(())
      } catch {
        err => Err(err)
      }
    },
  )
}
