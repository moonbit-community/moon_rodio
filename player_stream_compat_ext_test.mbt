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
test "rodio::player_compat::player_new_append_controls" {
  let (player, source) = Player::new()
  player.append(SamplesBuffer::new(1, 1, [1.0, 2.0]))
  assert_eq(player.len(), 1)
  assert_eq(source.next(), Some(1.0))
  player.pause()
  assert_true(player.is_paused())
  assert_eq(source.next(), Some(0.0))
  player.play()
  assert_true(!player.is_paused())
  assert_eq(source.next(), Some(2.0))
}

///|
test "rodio::player_compat::player_speed_volume_seek_delegation" {
  let (player, source) = Player::new()
  player.set_speed(2.0)
  player.set_volume(0.5)
  assert_eq(player.speed(), 2.0)
  assert_eq(player.volume(), 0.5)
  player.append(SamplesBuffer::new(1, 4, [1.0, 2.0, 3.0, 4.0]))
  ignore(source.next())
  player.try_seek(@moon_cpal.Duration::from_secs((0 : UInt64)))
  let pos = player.get_pos()
  assert_eq(pos.secs, (0 : UInt64))
}

///|
test "rodio::player_compat::device_sink_builder_with_config_alias" {
  let cfg = @moon_cpal.StreamConfig::new(
    1,
    22_050,
    @moon_cpal.BufferSize::fixed(512),
  )
  let builder = DeviceSinkBuilder::default().with_config(cfg)
  let out_cfg = builder.config()
  assert_eq(out_cfg.channel_count, 1)
  assert_eq(out_cfg.sample_rate, 22_050)
  assert_eq(out_cfg.buffer_size, @moon_cpal.BufferSize::fixed(512))
}
