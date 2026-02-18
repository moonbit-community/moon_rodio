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
fn clamp_sample(value : Sample) -> Sample {
  if value < -1.0 {
    -1.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn[S : Source] source_to_wav_bytes(source : S) -> Bytes {
  let channels = source.channels()
  let sample_rate = source.sample_rate()
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }

  let samples : Array[Sample] = []
  while true {
    match source.next() {
      None => break
      Some(v) => samples.push(clamp_sample(v))
    }
  }

  let data_size = samples.length() * 4
  let riff_size = 36 + data_size
  let byte_rate = sample_rate * channels * 4
  let block_align = channels * 4

  let buf = @buffer.new(size_hint=44 + data_size)
  buf.write_bytes(b"RIFF")
  buf.write_uint_le(riff_size.reinterpret_as_uint())
  buf.write_bytes(b"WAVE")
  buf.write_bytes(b"fmt ")
  buf.write_uint_le((16 : UInt))
  buf.write_uint16_le((3 : UInt16))
  buf.write_uint16_le(channels.to_uint16())
  buf.write_uint_le(sample_rate.reinterpret_as_uint())
  buf.write_uint_le(byte_rate.reinterpret_as_uint())
  buf.write_uint16_le(block_align.to_uint16())
  buf.write_uint16_le((32 : UInt16))
  buf.write_bytes(b"data")
  buf.write_uint_le(data_size.reinterpret_as_uint())

  for sample in samples {
    buf.write_float_le(Float::from_double(sample))
  }

  buf.to_bytes()
}

///|
pub trait WavWriter {
  write_all(Self, bytes : Bytes) -> Unit
}

///|
pub impl WavWriter for @buffer.Buffer with write_all(
  self : @buffer.Buffer,
  bytes : Bytes,
) {
  self.write_bytes(bytes)
}

///|
pub struct WavBytesCollector {
  out : Ref[Bytes]
}

///|
pub fn WavBytesCollector::new() -> WavBytesCollector {
  { out: @ref.new(b"") }
}

///|
pub fn WavBytesCollector::to_bytes(self : WavBytesCollector) -> Bytes {
  self.out.val
}

///|
pub impl WavWriter for WavBytesCollector with write_all(
  self : WavBytesCollector,
  bytes : Bytes,
) {
  self.out.val = bytes
}

///|
pub fn[S : Source, W : WavWriter] wav_to_writer(source : S, writer : W) -> Unit {
  writer.write_all(source_to_wav_bytes(source))
}

///|
pub fn[S : Source] wav_to_file(source : S, wav_file : StringView) -> Unit {
  let wav_bytes = source_to_wav_bytes(source)
  @fs.write_bytes_to_file(wav_file.to_string(), wav_bytes) catch {
    _ => panic()
  }
}

///|
pub fn[S : Source] output_to_wav(source : S, wav_file : StringView) -> Unit {
  wav_to_file(source, wav_file)
}
