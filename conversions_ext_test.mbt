///|
fn[S : Source] collect_n_conv(source : S, n : Int) -> Array[Sample] {
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
test "rodio::conversions::convert_channels" {
  let src = SamplesBuffer::new(1, 48_000, [1.0, -2.0])
  let out = convert_channels(src, 2)
  assert_eq(out.channels(), 2)
  assert_eq(collect_n_conv(out, 6), [1.0, 1.0, -2.0, -2.0])
}

///|
test "rodio::conversions::convert_sample_rate" {
  let src = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let out = convert_sample_rate(src, 4)
  assert_eq(out.sample_rate(), 4)
  // Linear interpolation at x=[0,0.5,1,1.5,2]
  let vals = collect_n_conv(out, 5)
  assert_eq(vals[0], 0.0)
  assert_true(vals[1] > 0.99 && vals[1] < 1.01)
  assert_eq(vals[2], 2.0)
  assert_true(vals[3] > 2.99 && vals[3] < 3.01)
  assert_eq(vals[4], 4.0)
}

///|
test "rodio::conversions::uniform" {
  let src = SamplesBuffer::new(1, 2, [0.0, 2.0, 4.0])
  let out = uniform(src, 2, 4)
  assert_eq(out.channels(), 2)
  assert_eq(out.sample_rate(), 4)
  let vals = collect_n_conv(out, 10)
  assert_eq(vals[0], 0.0)
  assert_eq(vals[1], 0.0)
  assert_true(vals[2] > 0.99 && vals[2] < 1.01)
  assert_true(vals[3] > 0.99 && vals[3] < 1.01)
}
