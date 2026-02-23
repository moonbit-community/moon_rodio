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
test "rodio::source::noise::aliases" {
  let w = white(8)
  let p = pink(8)
  let b = Blue::new(8)
  let v = Violet::new(8)
  let br = Brownian::new(8)
  let r = Red::new(8)
  let ve = Velvet::new(8)
  let wt = WhiteTriangular::new(8)
  let wg = WhiteGaussian::new(8)

  assert_eq(w.sample_rate(), 8)
  assert_eq(p.sample_rate(), 8)
  assert_eq(b.sample_rate(), 8)
  assert_eq(v.sample_rate(), 8)
  assert_eq(br.sample_rate(), 8)
  assert_eq(r.sample_rate(), 8)
  assert_eq(ve.sample_rate(), 8)
  assert_eq(wt.sample_rate(), 8)
  assert_eq(wg.sample_rate(), 8)

  assert_true(w.next() != None)
  assert_true(p.next() != None)
  assert_true(b.next() != None)
}
