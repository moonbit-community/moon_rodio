///|
pub suberror DecoderError {
  InvalidFormat(String)
  Unsupported(String)
} derive(Show, Eq)

///|
pub struct DecodedSamples {
  channels : Int
  sample_rate : Int
  samples : Array[Double]
  cursor : Ref[Int]
}

///|
pub fn DecodedSamples::new(
  channels : Int,
  sample_rate : Int,
  samples : Array[Double],
) -> DecodedSamples {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channels, sample_rate, samples, cursor: @ref.new(0) }
}

///|
pub fn DecodedSamples::channels(self : DecodedSamples) -> Int {
  self.channels
}

///|
pub fn DecodedSamples::sample_rate(self : DecodedSamples) -> Int {
  self.sample_rate
}

///|
pub fn DecodedSamples::next(self : DecodedSamples) -> Double? {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let value = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(value)
  }
}

///|
pub fn DecodedSamples::len(self : DecodedSamples) -> Int {
  self.samples.length()
}

///|
pub fn DecodedSamples::position(self : DecodedSamples) -> Int {
  self.cursor.val
}

///|
pub fn DecodedSamples::seek_to(
  self : DecodedSamples,
  sample_index : Int,
) -> Unit {
  if sample_index <= 0 {
    self.cursor.val = 0
  } else if sample_index >= self.samples.length() {
    self.cursor.val = self.samples.length()
  } else {
    self.cursor.val = sample_index
  }
}
