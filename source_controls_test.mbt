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
fn[S : Source] collect_n_controls(source : S, n : Int) -> Array[Sample] {
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
test "rodio::source::pausable" {
  let p = pausable(SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0]), true)
  assert_true(p.is_paused())
  assert_eq(p.inner().channels(), 1)
  assert_eq(p.inner_mut().sample_rate(), 44_100)
  assert_eq(p.into_inner().channels(), 1)
  assert_eq(p.next(), Some(0.0))
  assert_eq(p.next(), Some(0.0))

  p.set_paused(false)
  assert_true(!p.is_paused())
  assert_eq(collect_n_controls(p, 4), [1.0, 2.0, 3.0])
}

///|
test "rodio::source::stoppable" {
  let s = stoppable(SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0]))
  assert_eq(s.inner().channels(), 1)
  assert_eq(s.inner_mut().sample_rate(), 44_100)
  assert_eq(s.into_inner().channels(), 1)
  assert_eq(s.next(), Some(1.0))
  s.stop()
  assert_eq(s.next(), None)
}

///|
test "rodio::source::skippable" {
  let s = skippable(SamplesBuffer::new(1, 44_100, [1.0, 2.0, 3.0]))
  assert_eq(s.inner().channels(), 1)
  assert_eq(s.inner_mut().sample_rate(), 44_100)
  assert_eq(s.into_inner().channels(), 1)
  assert_eq(s.next(), Some(1.0))
  s.skip()
  assert_eq(s.next(), None)
}
