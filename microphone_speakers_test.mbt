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
test "rodio::microphone::input_config_supported_given" {
  let range = @moon_cpal.SupportedStreamConfigRange::new(
    1,
    16_000,
    48_000,
    @moon_cpal.SupportedBufferSize::Range(min=256, max=4096),
    @moon_cpal.SampleFormat::F32,
  )

  let ok = InputConfig::new(
    1,
    44_100,
    @moon_cpal.BufferSize::fixed(512),
    @moon_cpal.SampleFormat::F32,
  )
  assert_true(ok.supported_given(range))

  let bad_channels = ok.with_channel_count(2)
  assert_true(!bad_channels.supported_given(range))

  let bad_sample_format = ok.with_sample_format(@moon_cpal.SampleFormat::I16)
  assert_true(!bad_sample_format.supported_given(range))
}

///|
test "rodio::speakers::output_config_supported_given" {
  let range = @moon_cpal.SupportedStreamConfigRange::new(
    2,
    22_050,
    96_000,
    @moon_cpal.SupportedBufferSize::Range(min=512, max=16_384),
    @moon_cpal.SampleFormat::F32,
  )

  let ok = OutputConfig::new(
    2,
    48_000,
    @moon_cpal.BufferSize::fixed(2048),
    @moon_cpal.SampleFormat::F32,
  )
  assert_true(ok.supported_given(range))

  let bad_rate = ok.with_sample_rate(192_000)
  assert_true(!bad_rate.supported_given(range))

  let bad_buffer = ok.with_buffer_size(@moon_cpal.BufferSize::fixed(32))
  assert_true(!bad_buffer.supported_given(range))
}

///|
test "rodio::speakers::play_requires_builder_config" {
  let src = FixedSamplesBuffer::new(1, 44_100, [0.0, 0.1, -0.1, 0.0])
  let got = try {
    ignore(SpeakersBuilder::new().play(src))
    false
  } catch {
    SpeakersPlayError::BuilderError(SpeakersError::NoConfig) => true
    _ => false
  }
  assert_true(got)
}
