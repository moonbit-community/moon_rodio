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
test "rodio::speakers::config::default_alias" {
  let cfg0 = default()
  let cfg1 : OutputConfig = cfg0
  let cfg2 : @Milky2018/moon_rodio.OutputConfig = cfg1
  assert_eq(cfg2.channel_count, 1)
  assert_eq(cfg2.sample_rate, 44_100)
  let cfg3 = cfg2.with_channel_count(2).with_sample_rate(48_000)
  assert_eq(cfg3.channel_count, 2)
  assert_eq(cfg3.sample_rate, 48_000)
}
