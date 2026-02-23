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
test "rodio::stream::builder_aliases" {
  let builder = DeviceSinkBuilder::default()
    .with_channels(1)
    .with_sample_rate(22_050)
  let cfg = builder.config()
  let _ : DeviceSinkConfig = cfg
  let _ : @Milky2018/moon_rodio.OutputStreamConfig = cfg
  assert_eq(cfg.channel_count, 1)
  assert_eq(cfg.sample_rate, 22_050)
}

///|
test "rodio::stream::play_reader_alias" {
  let (mix, _out) = @Milky2018/moon_rodio.mixer(1, 44_100)
  let failed = try {
    ignore(play_reader(mix, Reader::from_bytes(b"not-audio")))
    false
  } catch {
    _ => true
  }
  assert_true(failed)
}
