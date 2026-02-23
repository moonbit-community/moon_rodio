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
test "rodio::source::signal_generator::aliases" {
  let sg = with_function(8, 1.0, Function::sine())
  assert_eq(sg.channels(), 1)
  assert_eq(sg.sample_rate(), 8)
  assert_true(sg.next() != None)

  let custom = with_generator(
    8,
    1.0,
    GeneratorFunction::new(fn(_phase : Double) { 0.25 }),
  )
  assert_eq(custom.channels(), 1)
  assert_eq(custom.sample_rate(), 8)
  assert_eq(custom.next(), Some(0.25))

  let sine = SineWave::new(440.0)
  let square = SquareWave::new(440.0)
  let saw = SawtoothWave::new(440.0)
  let tri = TriangleWave::new(440.0)
  assert_eq(sine.channels(), 1)
  assert_eq(square.channels(), 1)
  assert_eq(saw.channels(), 1)
  assert_eq(tri.channels(), 1)
}
