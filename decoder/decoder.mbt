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
pub suberror DecoderError {
  InvalidFormat(String)
  Unsupported(String)
} derive(Show, Eq)

///|
pub struct DecodedSamples {
  channels : Int
  sample_rate : Int
  samples : Array[Double]
  cursor : Ref[Int]
}

///|
pub fn DecodedSamples::new(
  channels : Int,
  sample_rate : Int,
  samples : Array[Double],
) -> DecodedSamples {
  guard channels > 0 else { panic() }
  guard sample_rate > 0 else { panic() }
  { channels, sample_rate, samples, cursor: @ref.new(0) }
}

///|
pub fn DecodedSamples::channels(self : DecodedSamples) -> Int {
  self.channels
}

///|
pub fn DecodedSamples::sample_rate(self : DecodedSamples) -> Int {
  self.sample_rate
}

///|
pub fn DecodedSamples::next(self : DecodedSamples) -> Double? {
  if self.cursor.val >= self.samples.length() {
    None
  } else {
    let value = self.samples[self.cursor.val]
    self.cursor.val += 1
    Some(value)
  }
}

///|
pub fn DecodedSamples::len(self : DecodedSamples) -> Int {
  self.samples.length()
}

///|
pub fn DecodedSamples::position(self : DecodedSamples) -> Int {
  self.cursor.val
}

///|
pub fn DecodedSamples::seek_to(
  self : DecodedSamples,
  sample_index : Int,
) -> Unit {
  if sample_index <= 0 {
    self.cursor.val = 0
  } else if sample_index >= self.samples.length() {
    self.cursor.val = self.samples.length()
  } else {
    self.cursor.val = sample_index
  }
}

///|
pub struct WavDecoder {
  inner : DecodedSamples
}

///|
pub fn WavDecoder::new(bytes : Bytes) -> WavDecoder raise DecoderError {
  { inner: decode_wav_bytes(bytes) }
}

///|
pub fn WavDecoder::into_inner(self : WavDecoder) -> DecodedSamples {
  self.inner
}

///|
pub fn WavDecoder::channels(self : WavDecoder) -> Int {
  self.inner.channels()
}

///|
pub fn WavDecoder::sample_rate(self : WavDecoder) -> Int {
  self.inner.sample_rate()
}

///|
pub fn WavDecoder::next(self : WavDecoder) -> Double? {
  self.inner.next()
}

///|
pub fn WavDecoder::len(self : WavDecoder) -> Int {
  self.inner.len()
}

///|
pub fn WavDecoder::position(self : WavDecoder) -> Int {
  self.inner.position()
}

///|
pub fn WavDecoder::seek_to(self : WavDecoder, sample_index : Int) -> Unit {
  self.inner.seek_to(sample_index)
}

///|
pub struct Mp3Decoder {
  inner : DecodedSamples
}

///|
pub fn Mp3Decoder::new(bytes : Bytes) -> Mp3Decoder raise DecoderError {
  { inner: decode_mp3_bytes(bytes) }
}

///|
pub fn Mp3Decoder::into_inner(self : Mp3Decoder) -> DecodedSamples {
  self.inner
}

///|
pub fn Mp3Decoder::channels(self : Mp3Decoder) -> Int {
  self.inner.channels()
}

///|
pub fn Mp3Decoder::sample_rate(self : Mp3Decoder) -> Int {
  self.inner.sample_rate()
}

///|
pub fn Mp3Decoder::next(self : Mp3Decoder) -> Double? {
  self.inner.next()
}

///|
pub fn Mp3Decoder::len(self : Mp3Decoder) -> Int {
  self.inner.len()
}

///|
pub fn Mp3Decoder::position(self : Mp3Decoder) -> Int {
  self.inner.position()
}

///|
pub fn Mp3Decoder::seek_to(self : Mp3Decoder, sample_index : Int) -> Unit {
  self.inner.seek_to(sample_index)
}

///|
pub struct FlacDecoder {
  inner : DecodedSamples
}

///|
pub fn FlacDecoder::new(bytes : Bytes) -> FlacDecoder raise DecoderError {
  { inner: decode_flac_bytes(bytes) }
}

///|
pub fn FlacDecoder::into_inner(self : FlacDecoder) -> DecodedSamples {
  self.inner
}

///|
pub fn FlacDecoder::channels(self : FlacDecoder) -> Int {
  self.inner.channels()
}

///|
pub fn FlacDecoder::sample_rate(self : FlacDecoder) -> Int {
  self.inner.sample_rate()
}

///|
pub fn FlacDecoder::next(self : FlacDecoder) -> Double? {
  self.inner.next()
}

///|
pub fn FlacDecoder::len(self : FlacDecoder) -> Int {
  self.inner.len()
}

///|
pub fn FlacDecoder::position(self : FlacDecoder) -> Int {
  self.inner.position()
}

///|
pub fn FlacDecoder::seek_to(self : FlacDecoder, sample_index : Int) -> Unit {
  self.inner.seek_to(sample_index)
}

///|
pub struct VorbisDecoder {
  inner : DecodedSamples
}

///|
pub fn VorbisDecoder::new(bytes : Bytes) -> VorbisDecoder raise DecoderError {
  { inner: decode_vorbis_bytes(bytes) }
}

///|
pub fn VorbisDecoder::from_stream_reader(
  bytes : Bytes,
) -> VorbisDecoder raise DecoderError {
  VorbisDecoder::new(bytes)
}

///|
pub fn VorbisDecoder::into_inner(self : VorbisDecoder) -> DecodedSamples {
  self.inner
}

///|
pub fn VorbisDecoder::channels(self : VorbisDecoder) -> Int {
  self.inner.channels()
}

///|
pub fn VorbisDecoder::sample_rate(self : VorbisDecoder) -> Int {
  self.inner.sample_rate()
}

///|
pub fn VorbisDecoder::next(self : VorbisDecoder) -> Double? {
  self.inner.next()
}

///|
pub fn VorbisDecoder::len(self : VorbisDecoder) -> Int {
  self.inner.len()
}

///|
pub fn VorbisDecoder::position(self : VorbisDecoder) -> Int {
  self.inner.position()
}

///|
pub fn VorbisDecoder::seek_to(self : VorbisDecoder, sample_index : Int) -> Unit {
  self.inner.seek_to(sample_index)
}

///|
pub struct ReadSeekSource {
  inner : Bytes
  byte_len : Int?
  is_seekable : Bool
}

///|
pub fn ReadSeekSource::new(
  bytes : Bytes,
  byte_len? : Int? = None,
  is_seekable? : Bool = true,
) -> ReadSeekSource {
  ReadSeekSource::from_bytes(bytes, byte_len~, is_seekable~)
}

///|
pub fn ReadSeekSource::from_bytes(
  bytes : Bytes,
  byte_len? : Int? = None,
  is_seekable? : Bool = true,
) -> ReadSeekSource {
  let effective_len = match byte_len {
    Some(v) => Some(v)
    None => Some(bytes.length())
  }
  { inner: bytes, byte_len: effective_len, is_seekable }
}

///|
pub fn ReadSeekSource::byte_len(self : ReadSeekSource) -> Int? {
  self.byte_len
}

///|
pub fn ReadSeekSource::is_seekable(self : ReadSeekSource) -> Bool {
  self.is_seekable
}

///|
pub fn ReadSeekSource::into_inner(self : ReadSeekSource) -> Bytes {
  self.inner
}
