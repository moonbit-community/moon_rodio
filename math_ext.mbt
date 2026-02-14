///|
let log2_10 : Double = 3.3219280948873626

///|
let log10_2 : Double = 0.3010299956639812

///|
pub fn lerp(
  first : Sample,
  second : Sample,
  numerator : Int,
  denominator : Int,
) -> Sample {
  guard denominator > 0 else { panic() }
  first +
  (second - first) * Double::from_int(numerator) / Double::from_int(denominator)
}

///|
pub fn db_to_linear(decibels : Sample) -> Sample {
  @math.pow(2.0, decibels * 0.05 * log2_10)
}

///|
pub fn linear_to_db(linear : Sample) -> Sample {
  @math.log2(linear) * log10_2 * 20.0
}
