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
pub fn lerp(
  first : Double,
  second : Double,
  numerator : Int,
  denominator : Int,
) -> Double {
  @Milky2018/moon_rodio.lerp(first, second, numerator, denominator)
}

///|
pub fn db_to_linear(decibels : Double) -> Double {
  @Milky2018/moon_rodio.db_to_linear(decibels)
}

///|
pub fn linear_to_db(linear : Double) -> Double {
  @Milky2018/moon_rodio.linear_to_db(linear)
}
