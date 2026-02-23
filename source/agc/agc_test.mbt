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
test "rodio::source::agc::aliases" {
  let src = @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.2, 0.4, 0.8, 0.1])

  let agc = automatic_gain_control(
    src,
    AutomaticGainControlSettings::default().with_target_level(0.7),
  )
  assert_eq(agc.channels(), 1)
  assert_eq(agc.sample_rate(), 8)
  assert_true(agc.next() != None)

  let agc2 = automatic_gain_control_with_params(
    @Milky2018/moon_rodio.SamplesBuffer::new(1, 8, [0.1, 0.2]),
    0.6,
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    @moon_cpal.Duration::from_secs((1 : UInt64)),
    3.0,
  )
  assert_eq(agc2.channels(), 1)
  assert_eq(agc2.sample_rate(), 8)
  assert_true(agc2.next() != None)
}
