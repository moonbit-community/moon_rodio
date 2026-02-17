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
test "rodio::math::lerp" {
  assert_eq(lerp(0.0, 10.0, 0, 10), 0.0)
  assert_eq(lerp(0.0, 10.0, 5, 10), 5.0)
  assert_eq(lerp(0.0, 10.0, 10, 10), 10.0)
}

///|
test "rodio::math::db_to_linear" {
  let a = db_to_linear(0.0)
  assert_true(a > 0.999999 && a < 1.000001)

  let b = db_to_linear(20.0)
  assert_true(b > 9.999 && b < 10.001)

  let c = db_to_linear(-20.0)
  assert_true(c > 0.0999 && c < 0.1001)
}

///|
test "rodio::math::linear_to_db" {
  let a = linear_to_db(1.0)
  assert_true(a > -0.000001 && a < 0.000001)

  let b = linear_to_db(10.0)
  assert_true(b > 19.999 && b < 20.001)

  let c = linear_to_db(0.1)
  assert_true(c > -20.001 && c < -19.999)
}

///|
test "rodio::math::round_trip" {
  let xs = [-60.0, -20.0, -6.0, 0.0, 6.0, 20.0, 40.0]
  for x in xs {
    let y = linear_to_db(db_to_linear(x))
    assert_true((y - x).abs() < 0.000001)
  }
}
