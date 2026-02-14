///|
fn[S : Source] collect_n(source : S, n : Int) -> Array[Sample] {
  let out : Array[Sample] = []
  for _ in 0..<n {
    match source.next() {
      None => break
      Some(v) => out.push(v)
    }
  }
  out
}

///|
fn skip_duration_samples_left(
  channels : ChannelCount,
  sample_rate : SampleRate,
  seconds : Int,
  seconds_to_skip : Int,
) -> Int {
  let len = channels * sample_rate * seconds
  let samples : Array[Sample] = []
  for _ in 0..<len {
    samples.push(0.0)
  }
  let src = SamplesBuffer::new(channels, sample_rate, samples)
  let skipped = skip_duration(
    src,
    @moon_cpal.Duration::from_secs(seconds_to_skip.to_uint64()),
  )
  collect_n(skipped, len + 4).length()
}

///|
test "rodio::source::sine_wave" {
  let s = SineWave::new(440.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 48_000)
  assert_true(s.next().unwrap().abs() < 1.0e-12)
  let v1 = s.next().unwrap()
  assert_true(v1 > 0.05 && v1 < 0.06)
}

///|
test "rodio::source::square_wave" {
  let s = SquareWave::new(440.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 48_000)
  assert_eq(s.next(), Some(1.0))
}

///|
test "rodio::source::sawtooth_wave" {
  let s = SawtoothWave::new(440.0)
  assert_eq(s.next(), Some(0.0))
  assert_true(s.next().unwrap() > 0.0)
}

///|
test "rodio::source::triangle_wave" {
  let s = TriangleWave::new(440.0)
  assert_eq(s.next(), Some(-1.0))
  assert_true(s.next().unwrap() > -1.0)
}

///|
test "rodio::source::empty_and_zero" {
  let e = empty(1, 44_100)
  assert_eq(e.next(), None)

  let z = zero(1, 44_100)
  assert_eq(collect_n(z, 4), [0.0, 0.0, 0.0, 0.0])

  let zf = zero_samples(1, 44_100, 3)
  assert_eq(collect_n(zf, 10), [0.0, 0.0, 0.0])
}

///|
test "rodio::source::metadata_and_seek_on_samples_buffer" {
  let src = SamplesBuffer::new(2, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])

  assert_eq(src.current_span_len(), Some(6))
  let total = src.total_duration().unwrap()
  assert_eq(total.secs, (0 : UInt64))
  assert_eq(total.nanos, 750_000_000)

  src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(src.current_span_len(), Some(0))
  assert_eq(src.next(), None)

  src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(src.current_span_len(), Some(6))
  assert_eq(src.next(), Some(1.0))
}

///|
test "rodio::source::duration_precision_and_subsecond_seek" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0])
  let total = src.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  assert_eq(total.nanos, 500_000_000)

  src.try_seek(@moon_cpal.Duration::new((0 : UInt64), 500_000_000))
  assert_eq(src.next(), Some(2.0))
}

///|
test "rodio::source::default_try_seek_not_supported" {
  let src = Zero::new(1, 44_100)
  let got_not_supported = try {
    src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
    false
  } catch {
    SeekError::NotSupported => true
  }
  assert_true(got_not_supported)
}

///|
test "rodio::source::signal_generator_seek" {
  let src = SineWave::new(100.0)
  assert_eq(src.next(), Some(0.0))
  assert_true(src.next().unwrap() > 0.01)
  src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(src.next(), Some(0.0))

  let saw = SawtoothWave::new(50.0)
  assert_eq(saw.next(), Some(0.0))
  saw.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  assert_eq(saw.next(), Some(0.0))
}

///|
test "rodio::source::to_dyn_preserves_seek_metadata" {
  let src = SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0])
  let dyn_src = to_dyn(src)
  assert_eq(dyn_src.current_span_len(), Some(4))
  dyn_src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(dyn_src.next(), None)
}

///|
test "rodio::source::named_wrapper_forwards_seek" {
  let amp = Amplify::new(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]), 1.0)
  assert_eq(amp.current_span_len(), Some(4))
  amp.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(amp.next(), None)
}

///|
test "rodio::source::amplify_take" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, -2.0, 3.0, -4.0])
  let amp = amplify(src, 0.5)
  let t = take(amp, 3)
  assert_eq(collect_n(t, 10), [0.5, -1.0, 1.5])
}

///|
test "rodio::source::mix" {
  let a = SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  let b = SamplesBuffer::new(1, 44_100, [4.0, 5.0])
  let m = mix(a, b)
  assert_eq(collect_n(m, 5), [5.0, 7.0, 3.0])
}

///|
test "rodio::source::speed" {
  let a = SamplesBuffer::new(1, 44_100, [1.0, 2.0])
  let s = speed(a, 2.0)
  assert_eq(s.channels(), 1)
  assert_eq(s.sample_rate(), 88_200)
  assert_eq(collect_n(s, 3), [1.0, 2.0])

  let s2 = speed(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    2.0,
  )
  let total = s2.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  s2.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(s2.next(), None)
}

///|
test "rodio::source::repeat_infinite" {
  let a = SamplesBuffer::new(1, 44_100, [2.0, -1.0])
  let r = a.repeat_infinite()
  assert_eq(collect_n(r, 6), [2.0, -1.0, 2.0, -1.0, 2.0, -1.0])
}

///|
test "rodio::source::buffered_and_repeat_infinite_fn" {
  let src = SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0])
  let b = buffered(src)
  assert_eq(collect_n(b, 10), [1.0, 2.0, 3.0])

  let src2 = SamplesBuffer::new(1, 44_100, [2.0, -1.0])
  let r = repeat_infinite(src2)
  assert_eq(collect_n(r, 6), [2.0, -1.0, 2.0, -1.0, 2.0, -1.0])

  let src3 = SamplesBuffer::new(1, 44_100, [3.0])
  assert_eq(collect_n(repeat(src3), 4), [3.0, 3.0, 3.0, 3.0])
}

///|
test "rodio::source::duration_filters" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0, 5.0])
  let t = take_duration(src, @moon_cpal.Duration::from_secs((2 : UInt64)))
  assert_eq(collect_n(t, 10), [1.0, 2.0, 3.0, 4.0])

  let src2 = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0, 5.0])
  let sk = skip_duration(src2, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(sk, 10), [3.0, 4.0, 5.0])

  let src3 = SamplesBuffer::new(1, 2, [9.0, 8.0])
  let d = delay(src3, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(d, 6), [0.0, 0.0, 9.0, 8.0])
}

///|
test "rodio::source::skip_duration_length_cases" {
  assert_eq(skip_duration_samples_left(1, 44_100, 5, 3), 88_200)
  assert_eq(skip_duration_samples_left(2, 44_100, 5, 3), 176_400)
  assert_eq(skip_duration_samples_left(1, 44_100, 1, 5), 0)
  assert_eq(skip_duration_samples_left(2, 44_100, 1, 1), 0)
  assert_eq(skip_duration_samples_left(1, 96_000, 5, 0), 480_000)
}

///|
test "rodio::source::duration_filters_metadata_and_seek" {
  let td = take_duration(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    @moon_cpal.Duration::new((1 : UInt64), 500_000_000),
  )
  assert_eq(td.current_span_len(), Some(6))
  let td_total = td.total_duration().unwrap()
  assert_eq(td_total.secs, (1 : UInt64))
  assert_eq(td_total.nanos, 500_000_000)
  td.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(td.next(), Some(5.0))

  let dd = delay(
    SamplesBuffer::new(1, 2, [9.0, 8.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(dd.current_span_len(), Some(4))
  let dd_total = dd.total_duration().unwrap()
  assert_eq(dd_total.secs, (2 : UInt64))
  assert_eq(dd_total.nanos, 0)
  dd.try_seek(@moon_cpal.Duration::new((0 : UInt64), 500_000_000))
  assert_eq(dd.next(), Some(0.0))
  assert_eq(dd.next(), Some(9.0))
  dd.try_seek(@moon_cpal.Duration::new((1 : UInt64), 500_000_000))
  assert_eq(dd.next(), Some(8.0))

  let sd = skip_duration(
    SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  let sd_total = sd.total_duration().unwrap()
  assert_eq(sd_total.secs, (1 : UInt64))
  assert_eq(sd_total.nanos, 0)
}

///|
test "rodio::source::amplify_db_and_normalized" {
  let a = SamplesBuffer::new(1, 44_100, [1.0])
  let db = amplify_decibel(a, 6.0206)
  let dbv = db.next().unwrap()
  assert_true(dbv > 1.99 && dbv < 2.01)

  let b = SamplesBuffer::new(1, 44_100, [1.0])
  let n0 = amplify_normalized(b, 0.0)
  assert_eq(n0.next(), Some(0.0))

  let c = SamplesBuffer::new(1, 44_100, [1.0])
  let n1 = amplify_normalized(c, 1.0)
  assert_true(n1.next().unwrap() > 0.99)
}

///|
test "rodio::source::track_position" {
  let t = track_position(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0]))
  assert_eq(t.inner().channels(), 1)
  assert_eq(t.inner_mut().sample_rate(), 2)
  assert_eq(t.into_inner().channels(), 1)
  assert_eq(t.get_pos().secs, (0 : UInt64))
  ignore(t.next())
  ignore(t.next())
  assert_eq(t.get_pos().secs, (1 : UInt64))
  t.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(t.get_pos().secs, (1 : UInt64))
}

///|
test "rodio::source::track_position_subsecond" {
  let t = track_position(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0]))
  ignore(t.next())
  let pos = t.get_pos()
  assert_eq(pos.secs, (0 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
}

///|
test "rodio::source::track_position_in_presence_of_speedup" {
  let t = track_position(
    speed(
      SamplesBuffer::new(1, 1, [10.0, -10.0, 10.0, -10.0, 20.0, -20.0]),
      2.0,
    ),
  )
  assert_eq(t.get_pos().secs, (0 : UInt64))
  ignore(t.next())
  let pos = t.get_pos()
  assert_eq(pos.secs, (0 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
  ignore(t.next())
  assert_eq(t.get_pos().secs, (1 : UInt64))
  t.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(t.get_pos().secs, (1 : UInt64))
}

///|
test "rodio::source::track_position_across_spans" {
  let idx = @ref.new(0)
  let t = track_position(
    from_factory(fn() {
      let current = idx.val
      idx.val += 1
      if current == 0 {
        Some(SamplesBuffer::new(1, 1, [1.0, 2.0]))
      } else if current == 1 {
        Some(SamplesBuffer::new(1, 2, [3.0, 4.0]))
      } else {
        None
      }
    }),
  )
  ignore(t.next())
  ignore(t.next())
  ignore(t.next())
  assert_eq(t.sample_rate(), 2)
  let pos = t.get_pos()
  assert_eq(pos.secs, (2 : UInt64))
  assert_eq(pos.nanos, 500_000_000)
}

///|
test "rodio::source::periodic_access" {
  let call_count = @ref.new(0)
  let p = periodic_access(
    SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0, 4.0, 5.0]),
    2,
    fn() { call_count.val += 1 },
  )
  assert_eq(p.inner().channels(), 1)
  assert_eq(p.inner_mut().sample_rate(), 44_100)
  assert_eq(p.into_inner().channels(), 1)
  assert_eq(collect_n(p, 10), [1.0, 2.0, 3.0, 4.0, 5.0])
  assert_eq(call_count.val, 3)
}

///|
test "rodio::source::periodic_alias" {
  let calls = @ref.new(0)
  let p = periodic(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    fn() { calls.val += 1 },
  )
  assert_eq(collect_n(p, 10), [1.0, 2.0, 3.0, 4.0])
  assert_eq(calls.val, 2)
}

///|
test "rodio::source::periodic_access_with_source" {
  let p = periodic_access_with_source(
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0]),
    2,
    fn(src) {
      ignore(
        try {
          src.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
          Ok(())
        } catch {
          _ => Err(())
        },
      )
    },
  )
  assert_eq(collect_n(p, 8), [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0])
}

///|
test "rodio::source::channel_volume" {
  let s = SamplesBuffer::new(2, 44_100, [2.0, 6.0, 4.0, 8.0])
  let out = channel_volume(s, [1.0, 0.5, 2.0])
  assert_eq(out.channels(), 3)
  assert_eq(collect_n(out, 10), [4.0, 2.0, 8.0, 6.0, 3.0, 12.0])
}

///|
test "rodio::source::linear_ramp_and_fades" {
  let s = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0])
  let ramp = linear_gain_ramp(
    s,
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  let rv = collect_n(ramp, 10)
  assert_eq(rv[0], 0.0)
  assert_true(rv[1] > 0.49 && rv[1] < 0.51)
  assert_eq(rv[2], 1.0)

  let s2 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0])
  let fin = fade_in(s2, @moon_cpal.Duration::from_secs((2 : UInt64)))
  let fv = collect_n(fin, 10)
  assert_eq(fv[0], 0.0)
  assert_true(fv[1] > 0.49 && fv[1] < 0.51)
  assert_eq(fv[2], 1.0)

  let s3 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0, 1.0])
  let fout = fade_out(s3, @moon_cpal.Duration::from_secs((2 : UInt64)))
  assert_eq(collect_n(fout, 10), [1.0, 1.0, 0.5, 0.0])

  let s4 = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0, 1.0])
  let unclamped = linear_gain_ramp_with_clamp(
    s4,
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((2 : UInt64)),
    false,
  )
  assert_eq(collect_n(unclamped, 10), [0.0, 0.5, 1.0, 1.0])

  let s5 = SamplesBuffer::new(1, 1, [1.0, 1.0])
  assert_eq(
    collect_n(fadein(s5, @moon_cpal.Duration::from_secs((1 : UInt64))), 10),
    [0.0, 1.0],
  )

  let s6 = SamplesBuffer::new(1, 1, [1.0, 1.0])
  assert_eq(
    collect_n(fadeout(s6, @moon_cpal.Duration::from_secs((1 : UInt64))), 10),
    [1.0, 0.0],
  )

  let seek_ramp = linear_gain_ramp(
    SamplesBuffer::new(1, 1, [
      0.0, 0.4, 0.8, 0.0, 0.4, 0.8, 0.0, 0.4, 0.8, 0.0, 0.4, 0.8,
    ]),
    0.0,
    1.0,
    @moon_cpal.Duration::from_secs((10 : UInt64)),
  )
  assert_eq(seek_ramp.next(), Some(0.0))
  let a1 = seek_ramp.next().unwrap()
  let a2 = seek_ramp.next().unwrap()
  assert_true(a1 > 0.039 && a1 < 0.041)
  assert_true(a2 > 0.159 && a2 < 0.161)

  seek_ramp.try_seek(@moon_cpal.Duration::from_secs((5 : UInt64)))
  let b0 = seek_ramp.next().unwrap()
  assert_true(b0 > 0.39 && b0 < 0.41)
  assert_eq(seek_ramp.next(), Some(0.0))
  let b2 = seek_ramp.next().unwrap()
  assert_true(b2 > 0.27 && b2 < 0.29)

  seek_ramp.try_seek(@moon_cpal.Duration::from_secs((10 : UInt64)))
  let c0 = seek_ramp.next().unwrap()
  assert_true(c0 > 0.39 && c0 < 0.41)
}

///|
test "rodio::source::limit_and_distortion" {
  let a = SamplesBuffer::new(1, 44_100, [-2.0, -0.5, 0.2, 3.0])
  let l = limit(a, -1.0, 1.0)
  assert_eq(collect_n(l, 10), [-1.0, -0.5, 0.2, 1.0])

  let b = SamplesBuffer::new(1, 44_100, [-2.0, -0.5, 0.2, 3.0])
  let d = distortion(b, 0.4)
  assert_eq(collect_n(d, 10), [-0.4, -0.4, 0.2, 0.4])
}

///|
test "rodio::source::crossfade" {
  let a = SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
  let b = zero(1, 1)
  let x = crossfade(a, b, @moon_cpal.Duration::new((5 : UInt64), 1))
  let v = collect_n(x, 10)
  assert_eq(v.length(), 5)
  assert_eq(v[0], 1.0)
  assert_true(v[1] > 1.59 && v[1] < 1.61)
  assert_true(v[2] > 1.79 && v[2] < 1.81)
  assert_true(v[3] > 1.59 && v[3] < 1.61)
  assert_true(v[4] > 0.99 && v[4] < 1.01)

  let y = take_crossfade_with(
    SamplesBuffer::new(1, 1, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
    zero(1, 1),
    @moon_cpal.Duration::new((5 : UInt64), 1),
  )
  assert_eq(collect_n(y, 10).length(), 5)
}

///|
test "rodio::source::chirp" {
  let c = chirp(10, 10.0, 20.0, @moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(c.channels(), 1)
  assert_eq(c.sample_rate(), 10)
  let out = collect_n(c, 20)
  assert_eq(out.length(), 10)
}

///|
test "rodio::source::from_factory" {
  let idx = @ref.new(0)
  let src = from_factory(fn() {
    let current = idx.val
    idx.val += 1
    if current == 0 {
      Some(SamplesBuffer::new(1, 44_100, [1.0, 2.0]))
    } else if current == 1 {
      Some(SamplesBuffer::new(1, 44_100, [3.0]))
    } else {
      None
    }
  })

  assert_eq(src.channels(), 1)
  assert_eq(src.sample_rate(), 44_100)
  assert_eq(src.current_span_len(), Some(2))
  assert_eq(collect_n(src, 10), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::from_factory_metadata_and_seek" {
  let idx = @ref.new(0)
  let src = from_factory(fn() {
    let current = idx.val
    idx.val += 1
    if current == 0 {
      Some(SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]))
    } else if current == 1 {
      Some(SamplesBuffer::new(1, 2, [5.0]))
    } else {
      None
    }
  })

  assert_eq(src.current_span_len(), Some(4))
  src.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(src.next(), Some(3.0))
  assert_eq(collect_n(src, 10), [4.0, 5.0])
}

///|
test "rodio::source::done" {
  let signal = @ref.new(2)
  let d = Done::new(SamplesBuffer::new(1, 44_100, [1.0]), signal)
  assert_eq(d.inner().channels(), 1)
  assert_eq(d.inner_mut().sample_rate(), 44_100)
  assert_eq(d.into_inner().channels(), 1)
  assert_eq(d.next(), Some(1.0))
  assert_eq(signal.val, 2)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
}

///|
test "rodio::source::done_metadata_and_seek_forwarding" {
  let d = Done::new(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]), @ref.new(1))
  assert_eq(d.current_span_len(), Some(4))
  let total = d.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  d.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(d.next(), None)
}

///|
test "rodio::source::empty_callback" {
  let calls = @ref.new(0)
  let e = EmptyCallback::new(fn() { calls.val += 1 })
  assert_eq(e.next(), None)
  assert_eq(e.next(), None)
  assert_eq(calls.val, 1)
}

///|
test "rodio::source::uniform_source_iterator" {
  let s = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let u = UniformSourceIterator::new(s, 2, 4)
  assert_eq(u.inner_mut().channels(), 2)
  assert_eq(u.channels(), 2)
  assert_eq(u.sample_rate(), 4)
  assert_eq(u.current_span_len(), None)
  let total = u.total_duration().unwrap()
  assert_eq(total.secs, (1 : UInt64))
  let vals = collect_n(u, 10)
  assert_eq(vals[0], 0.0)
  assert_eq(vals[1], 0.0)
  assert_true(vals[2] > 0.99 && vals[2] < 1.01)
}

///|
test "rodio::source::from_iter_sources" {
  let a = to_dyn(SamplesBuffer::new(1, 44_100, [1.0, 2.0]))
  let b = to_dyn(SamplesBuffer::new(1, 44_100, [3.0]))
  let it = from_iter([a, b])
  assert_eq(it.channels(), 1)
  assert_eq(it.sample_rate(), 44_100)
  assert_eq(collect_n(it, 10), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::from_iter_generic_sources" {
  let it = from_iter([
    SamplesBuffer::new(1, 44_100, [0.25, 0.5]),
    SamplesBuffer::new(1, 44_100, [0.75]),
  ])
  assert_eq(it.channels(), 1)
  assert_eq(it.sample_rate(), 44_100)
  assert_eq(collect_n(it, 10), [0.25, 0.5, 0.75])
}

///|
test "rodio::source::from_iter_metadata_and_seek" {
  let it = from_iter([SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0])])
  assert_eq(it.current_span_len(), Some(4))
  it.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(it.next(), None)
}

///|
test "rodio::queue::current_span_len_behavior" {
  let (tx, rx) = queue(true)
  assert_eq(rx.current_span_len(), Some(512))

  tx.append(SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0]))
  let span = rx.current_span_len().unwrap()
  assert_true(span > 0)
  assert_eq(span, 3)
}

///|
test "rodio::source::function_chain" {
  let src = SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0])
  let out = take_duration(
    delay(amplify(src, 2.0), @moon_cpal.Duration::from_secs((1 : UInt64))),
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  assert_eq(collect_n(out, 10), [0.0, 0.0, 2.0, 4.0])
}

///|
test "rodio::source::named_wrappers_basic" {
  let a = Amplify::new(SamplesBuffer::new(1, 1, [1.0, 2.0]), 0.5)
  assert_eq(a.inner().channels(), 1)
  a.set_factor(2.0)
  assert_eq(a.next(), Some(2.0))
  a.set_log_factor(6.0206)
  let next_amp = a.next().unwrap()
  assert_true(next_amp > 3.98 && next_amp < 4.02)
  assert_eq(a.next(), None)

  let a2 = Amplify::new(SamplesBuffer::new(1, 1, [1.0, 2.0]), 0.5)
  assert_eq(collect_n(a2, 10), [0.5, 1.0])

  let z = Zero::new(1, 44_100)
  assert_eq(z.inner_mut().sample_rate(), 44_100)
  assert_eq(collect_n(z, 3), [0.0, 0.0, 0.0])
  let zf = Zero::new_samples(1, 44_100, 2)
  assert_eq(collect_n(zf, 10), [0.0, 0.0])

  let l = Limit::new(
    SamplesBuffer::new(1, 1, [-2.0, 0.5, 3.0]),
    LimitSettings::default(),
  )
  let lv0 = collect_n(l, 10)
  assert_true(lv0[0] > -0.95 && lv0[0] < -0.85)
  assert_true(lv0[1] > 0.49 && lv0[1] <= 0.5)
  assert_true(lv0[2] > 0.85 && lv0[2] < 0.95)

  let set = LimitSettings::new().with_threshold(-6.0)
  let l2 = Limit::new(SamplesBuffer::new(1, 1, [-1.0, -0.5, 0.5, 1.0]), set)
  let lv = collect_n(l2, 10)
  assert_true(lv[0] <= -0.49 && lv[0] >= -0.51)
  assert_true(lv[3] >= 0.49 && lv[3] <= 0.51)

  let hard = Limit::new(
    SamplesBuffer::new(1, 1_000, [0.9]),
    LimitSettings::new()
    .with_threshold(-1.0)
    .with_knee_width(0.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let soft = Limit::new(
    SamplesBuffer::new(1, 1_000, [0.9]),
    LimitSettings::new()
    .with_threshold(-1.0)
    .with_knee_width(8.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let hard_v = collect_n(hard, 10)
  let soft_v = collect_n(soft, 10)
  assert_true(hard_v[0] > soft_v[0])

  let fast_attack = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let slow_attack = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::new((1 : UInt64), 0))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let fast_attack_v = collect_n(fast_attack, 10)
  let slow_attack_v = collect_n(slow_attack, 10)
  assert_true(slow_attack_v[0] > fast_attack_v[0])

  let fast_release = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0, 0.2]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::from_secs((0 : UInt64))),
  )
  let slow_release = Limit::new(
    SamplesBuffer::new(1, 1_000, [1.0, 0.2]),
    LimitSettings::new()
    .with_threshold(-12.0)
    .with_attack(@moon_cpal.Duration::from_secs((0 : UInt64)))
    .with_release(@moon_cpal.Duration::new((2 : UInt64), 0)),
  )
  let fast_release_v = collect_n(fast_release, 10)
  let slow_release_v = collect_n(slow_release, 10)
  assert_true(slow_release_v[1] < fast_release_v[1])

  ignore(LimitSettings::dynamic_content())
  ignore(LimitSettings::broadcast())
  ignore(LimitSettings::mastering())
  ignore(LimitSettings::gaming())
  ignore(LimitSettings::live_performance())

  let dg = Distortion::with_gain(
    SamplesBuffer::new(1, 1, [0.5, -0.75]),
    2.0,
    0.8,
  )
  dg.set_threshold(0.7)
  dg.set_gain(1.0)
  assert_eq(collect_n(dg, 10), [0.5, -0.7])

  let cv = ChannelVolume::new(
    SamplesBuffer::new(2, 44_100, [2.0, 6.0, 4.0, 8.0]),
    [1.0, 1.0, 1.0],
  )
  cv.set_volume(1, 0.5)
  cv.set_volume(2, 2.0)
  assert_eq(cv.channels(), 3)
  assert_eq(collect_n(cv, 10), [4.0, 2.0, 8.0, 6.0, 3.0, 12.0])

  let sp = Speed::new(
    SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]),
    2.0,
  )
  assert_eq(sp.sample_rate(), 8)
  let total_sp = sp.total_duration().unwrap()
  assert_eq(total_sp.secs, (1 : UInt64))
  sp.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(sp.next(), None)
  sp.set_factor(0.5)
  assert_eq(sp.sample_rate(), 2)
}

///|
test "rodio::source::named_wrappers_signal_and_spatial" {
  let g = SignalGenerator::from_function(48_000, 440.0, Function::sine())
  assert_eq(g.channels(), 1)
  let g2 = SignalGenerator::with_function(48_000, 440.0, Function::triangle())
  assert_eq(g2.sample_rate(), 48_000)

  let custom = SignalGenerator::with_generator(
    48_000,
    440.0,
    GeneratorFunction::new(fn(_phase) { 0.25 }),
  )
  assert_eq(custom.next(), Some(0.25))

  let s = Spatial::new(
    SamplesBuffer::new(1, 44_100, [1.0, 1.0]),
    [0.0, 0.0, 0.0],
    [-1.0, 0.0, 0.0],
    [1.0, 0.0, 0.0],
  )
  assert_eq(s.inner().sample_rate(), 44_100)
  assert_eq(s.inner_mut().channels(), 2)
  assert_eq(s.into_inner().sample_rate(), 44_100)
  assert_eq(s.channels(), 2)
  assert_eq(s.sample_rate(), 44_100)
}

///|
test "rodio::source::named_wrappers_inner_accessors" {
  let d = Delay::new(
    SamplesBuffer::new(1, 1, [1.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(d.inner().channels(), 1)
  assert_eq(d.inner_mut().sample_rate(), 1)
  assert_eq(d.into_inner().channels(), 1)

  let r = Repeat::new(SamplesBuffer::new(1, 1, [1.0]))
  assert_eq(r.inner().channels(), 1)
  assert_eq(r.inner_mut().sample_rate(), 1)
  assert_eq(r.into_inner().channels(), 1)

  let td = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 2.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  td.set_filter_fadeout()
  td.clear_filter()
  assert_eq(td.inner().channels(), 1)
  assert_eq(td.inner_mut().sample_rate(), 1)
  assert_eq(td.into_inner().channels(), 1)

  let m = Mix::new(
    SamplesBuffer::new(1, 1, [1.0]),
    SamplesBuffer::new(1, 1, [2.0]),
  )
  assert_eq(m.inner().channels(), 1)
  assert_eq(m.inner_mut().sample_rate(), 1)
  assert_eq(m.into_inner().channels(), 1)

  let c = Crossfade::new(
    SamplesBuffer::new(1, 1, [1.0]),
    SamplesBuffer::new(1, 1, [2.0]),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
  )
  assert_eq(c.inner().channels(), 1)
  assert_eq(c.inner_mut().sample_rate(), 1)
  assert_eq(c.into_inner().channels(), 1)
}

///|
test "rodio::source::named_takeduration_filter_and_seek" {
  let td = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0]),
    @moon_cpal.Duration::from_secs((3 : UInt64)),
  )
  td.set_filter_fadeout()
  let vals = collect_n(td, 10)
  assert_eq(vals.length(), 3)
  assert_eq(vals[0], 1.0)
  assert_true(vals[1] > 0.66 && vals[1] < 0.67)
  assert_true(vals[2] > 0.33 && vals[2] < 0.34)

  let td2 = TakeDuration::new(
    SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0]),
    @moon_cpal.Duration::from_secs((3 : UInt64)),
  )
  td2.set_filter_fadeout()
  td2.clear_filter()
  assert_eq(collect_n(td2, 10), [1.0, 1.0, 1.0])

  let td3 = TakeDuration::new(
    SamplesBuffer::new(1, 2, [1.0, 2.0, 3.0, 4.0]),
    @moon_cpal.Duration::from_secs((2 : UInt64)),
  )
  td3.try_seek(@moon_cpal.Duration::from_secs((1 : UInt64)))
  assert_eq(collect_n(td3, 10), [3.0, 4.0])
}

///|
test "rodio::source::agc" {
  let src = SamplesBuffer::new(1, 10, [0.1, 0.1, 0.1, 0.1])
  let agc = AutomaticGainControl::new(
    src,
    1.0,
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    10.0,
  )
  let v = collect_n(agc, 4)
  assert_true(v[0] > 0.1)
  assert_true(v[3] > v[0])
}

///|
test "rodio::source::agc_controls" {
  let src = SamplesBuffer::new(1, 10, [0.1, 0.1, 0.1, 0.1])
  let agc = automatic_gain_control(
    src,
    1.0,
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    10.0,
  )
  let ctrl = agc.get_agc_control()
  assert_true(ctrl.val)
  agc.set_enabled(false)
  assert_true(!ctrl.val)
  assert_eq(agc.next(), Some(0.1))
  agc.set_enabled(true)
  assert_true(agc.next().unwrap() > 0.1)
  assert_true(agc.get_target_level().val > 0.9)
  assert_true(agc.get_absolute_max_gain().val > 9.9)
  assert_eq(agc.inner().channels(), 1)
  assert_eq(agc.inner_mut().sample_rate(), 10)
}

///|
test "rodio::source::blt_filter_smoke" {
  let lp = low_pass_with_q(
    SamplesBuffer::new(1, 48_000, [1.0, 0.0, 0.0, 0.0]),
    1_000,
    0.7,
  )
  let hp = high_pass(SamplesBuffer::new(1, 48_000, [1.0, 0.0, 0.0, 0.0]), 1_000)
  assert_eq(lp.channels(), 1)
  assert_eq(hp.sample_rate(), 48_000)
  assert_eq(lp.inner().channels(), 1)
  assert_eq(hp.inner_mut().sample_rate(), 48_000)
  assert_true(lp.next() is Some(_))
  assert_true(hp.next() is Some(_))
}

///|
test "rodio::source::noise_white_and_pink" {
  let w = WhiteUniform::new(44_100)
  let p = Pink::new(44_100)

  let wv = collect_n(w, 8)
  let pv = collect_n(p, 8)
  assert_eq(wv.length(), 8)
  assert_eq(pv.length(), 8)
  for x in wv {
    assert_true(x >= -1.0 && x <= 1.0)
  }
}

///|
test "rodio::source::distortion_with_gain" {
  let s = SamplesBuffer::new(1, 44_100, [0.25, 0.6, -0.8])
  let d = distortion_with_gain(s, 2.0, 0.9)
  assert_eq(collect_n(d, 10), [0.5, 0.9, -0.9])
}

///|
test "rodio::source::reverb" {
  let src = SamplesBuffer::new(1, 1, [1.0, 0.0, 0.0, 0.0])
  let out = reverb(src, @moon_cpal.Duration::from_secs((1 : UInt64)), 0.5)
  assert_eq(collect_n(out, 10), [1.0, 0.5, 0.0, 0.0, 0.0])
}

///|
test "rodio::source::noise_extended" {
  let tri = WhiteTriangular::new(44_100)
  let gauss = WhiteGaussian::new(44_100)
  let velvet = Velvet::new(44_100)
  let blue = Blue::new(44_100)
  let violet = Violet::new(44_100)
  let brown = Brownian::new(44_100)

  let tri_v = collect_n(tri, 64)
  let gauss_v = collect_n(gauss, 64)
  let velvet_v = collect_n(velvet, 64)
  let blue_v = collect_n(blue, 64)
  let violet_v = collect_n(violet, 64)
  let brown_v = collect_n(brown, 64)

  assert_eq(tri_v.length(), 64)
  assert_eq(gauss_v.length(), 64)
  assert_eq(velvet_v.length(), 64)
  assert_eq(blue_v.length(), 64)
  assert_eq(violet_v.length(), 64)
  assert_eq(brown_v.length(), 64)

  for x in tri_v {
    assert_true(x >= -1.0 && x <= 1.0)
  }
  for x in velvet_v {
    assert_true(x == -1.0 || x == 0.0 || x == 1.0)
  }
  for x in gauss_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in blue_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in violet_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }
  for x in brown_v {
    assert_true(x == x)
    assert_true(x.abs() < 1.0e308)
  }

  let old_white = white(44_100)
  let old_pink = pink(44_100)
  assert_eq(old_white.sample_rate(), 44_100)
  assert_eq(old_pink.sample_rate(), 44_100)
}
