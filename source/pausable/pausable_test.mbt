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
test "rodio::source::pausable::aliases" {
  let p = pausable(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [1.0, 2.0]),
    true,
  )
  assert_eq(p.channels(), 1)
  assert_eq(p.sample_rate(), 8)
  let paused = p.next()
  assert_true(paused == None || paused == Some(0.0))
  p.set_paused(false)
  assert_true(p.next() != None)
}
