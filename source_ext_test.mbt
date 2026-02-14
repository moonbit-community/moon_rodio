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
  assert_eq(s.next(), Some(-1.0))
  assert_true(s.next().unwrap() > -1.0)
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
  assert_eq(t.get_pos().secs, (0 : UInt64))
  ignore(t.next())
  ignore(t.next())
  assert_eq(t.get_pos().secs, (1 : UInt64))
}

///|
test "rodio::source::periodic_access" {
  let call_count = @ref.new(0)
  let p = periodic_access(
    SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0, 4.0, 5.0]),
    2,
    fn() { call_count.val += 1 },
  )
  assert_eq(collect_n(p, 10), [1.0, 2.0, 3.0, 4.0, 5.0])
  assert_eq(call_count.val, 2)
}

///|
test "rodio::source::channel_volume" {
  let s = SamplesBuffer::new(2, 44_100, [2.0, 2.0, 4.0, 4.0])
  let out = channel_volume(s, [1.0, 0.5])
  assert_eq(collect_n(out, 10), [2.0, 1.0, 4.0, 2.0])
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
  let a = SamplesBuffer::new(1, 1, [1.0, 1.0, 1.0])
  let b = SamplesBuffer::new(1, 1, [0.0, 2.0, 2.0])
  let x = crossfade(a, b, @moon_cpal.Duration::from_secs((2 : UInt64)))
  let v = collect_n(x, 10)
  assert_eq(v[0], 1.0)
  assert_true(v[1] > 1.49 && v[1] < 1.51)
  assert_eq(v[2], 2.0)
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
  assert_eq(collect_n(src, 10), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::done" {
  let signal = @ref.new(2)
  let d = Done::new(SamplesBuffer::new(1, 44_100, [1.0]), signal)
  assert_eq(d.next(), Some(1.0))
  assert_eq(signal.val, 2)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
  assert_eq(d.next(), None)
  assert_eq(signal.val, 1)
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
  assert_eq(u.channels(), 2)
  assert_eq(u.sample_rate(), 4)
  let vals = collect_n(u, 10)
  assert_eq(vals[0], 0.0)
  assert_eq(vals[1], 0.0)
  assert_true(vals[2] > 0.99 && vals[2] < 1.01)
}

///|
test "rodio::source::from_iter_sources" {
  let a = to_dyn(SamplesBuffer::new(1, 44_100, [1.0, 2.0]))
  let b = to_dyn(SamplesBuffer::new(1, 44_100, [3.0]))
  let it = from_source_iter([a, b])
  assert_eq(it.channels(), 1)
  assert_eq(it.sample_rate(), 44_100)
  assert_eq(collect_n(it, 10), [1.0, 2.0, 3.0])
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
