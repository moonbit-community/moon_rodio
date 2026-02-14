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
