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
