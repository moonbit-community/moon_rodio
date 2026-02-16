///|
pub suberror DecoderError {
  Backend(@decoder.DecoderError)
  UnknownFormat
} derive(Show, Eq)

///|
pub suberror PlayError {
  DecoderError(DecoderError)
} derive(Show, Eq)

///|
pub struct Decoder {
  inner : @decoder.DecodedSamples
  seekable : Bool
}

///|
pub struct Settings {
  byte_len : Int?
  coarse_seek : Bool
  gapless : Bool
  hint : String?
  mime_type : String?
  is_seekable : Bool
} derive(Show, Eq)

///|
pub fn Settings::default() -> Settings {
  {
    byte_len: None,
    coarse_seek: false,
    gapless: true,
    hint: None,
    mime_type: None,
    is_seekable: false,
  }
}

///|
pub struct DecoderBuilder {
  data : Bytes?
  settings : Settings
}

///|
pub fn DecoderBuilder::new() -> DecoderBuilder {
  { data: None, settings: Settings::default() }
}

///|
pub fn DecoderBuilder::with_data(
  self : DecoderBuilder,
  data : Bytes,
) -> DecoderBuilder {
  { ..self, data: Some(data) }
}

///|
pub fn DecoderBuilder::with_byte_len(
  self : DecoderBuilder,
  byte_len : Int,
) -> DecoderBuilder {
  guard byte_len >= 0 else { panic() }
  {
    ..self,
    settings: { ..self.settings, byte_len: Some(byte_len), is_seekable: true },
  }
}

///|
pub fn DecoderBuilder::with_coarse_seek(
  self : DecoderBuilder,
  coarse_seek : Bool,
) -> DecoderBuilder {
  { ..self, settings: { ..self.settings, coarse_seek, } }
}

///|
pub fn DecoderBuilder::with_gapless(
  self : DecoderBuilder,
  gapless : Bool,
) -> DecoderBuilder {
  { ..self, settings: { ..self.settings, gapless, } }
}

///|
pub fn DecoderBuilder::with_hint(
  self : DecoderBuilder,
  hint : StringView,
) -> DecoderBuilder {
  { ..self, settings: { ..self.settings, hint: Some(hint.to_string()) } }
}

///|
pub fn DecoderBuilder::with_mime_type(
  self : DecoderBuilder,
  mime_type : StringView,
) -> DecoderBuilder {
  {
    ..self,
    settings: { ..self.settings, mime_type: Some(mime_type.to_string()) },
  }
}

///|
pub fn DecoderBuilder::with_seekable(
  self : DecoderBuilder,
  is_seekable : Bool,
) -> DecoderBuilder {
  { ..self, settings: { ..self.settings, is_seekable, } }
}

///|
pub struct LoopedDecoder {
  channels : ChannelCount
  sample_rate : SampleRate
  samples : Array[Sample]
  cursor : Ref[Int]
  seekable : Bool
}

///|
fn hinted_decode(bytes : Bytes, hint : String) -> Decoder? {
  if hint.contains("wav") || hint.contains("WAV") {
    return Some(decode_wav_or_raise(bytes)) catch { _ => None }
  }
  if hint.contains("flac") || hint.contains("FLAC") {
    return Some(decode_flac_or_raise(bytes)) catch { _ => None }
  }
  if hint.contains("ogg") ||
    hint.contains("OGG") ||
    hint.contains("vorbis") ||
    hint.contains("VORBIS") {
    return Some(decode_vorbis_or_raise(bytes)) catch { _ => None }
  }
  if hint.contains("mp3") ||
    hint.contains("MP3") ||
    hint.contains("mpeg") ||
    hint.contains("MPEG") {
    return Some(decode_mp3_or_raise(bytes)) catch { _ => None }
  }
  None
}

///|
fn DecoderBuilder::decoder_builder_build(
  self : DecoderBuilder,
) -> Decoder raise DecoderError {
  let data = match self.data {
    None => raise DecoderError::UnknownFormat
    Some(data) => data
  }

  let hinted = match self.settings.hint {
    None => None
    Some(hint) => hinted_decode(data, hint)
  }
  let decoded = match hinted {
    Some(decoder) => decoder
    None => {
      let mime_hint = match self.settings.mime_type {
        None => None
        Some(hint) => hinted_decode(data, hint)
      }
      match mime_hint {
        Some(decoder) => decoder
        None => Decoder::new(data)
      }
    }
  }

  { ..decoded, seekable: self.settings.is_seekable }
}

///|
pub fn DecoderBuilder::build(
  self : DecoderBuilder,
) -> Decoder raise DecoderError {
  self.decoder_builder_build()
}

///|
fn to_looped_decoder(decoder : Decoder) -> LoopedDecoder {
  let channels = decoder.channels()
  let sample_rate = decoder.sample_rate()
  let seekable = decoder.seekable
  let samples : Array[Sample] = []
  while true {
    match decoder.next() {
      None => break
      Some(s) => samples.push(s)
    }
  }
  { channels, sample_rate, samples, cursor: @ref.new(0), seekable }
}

///|
pub fn DecoderBuilder::build_looped(
  self : DecoderBuilder,
) -> LoopedDecoder raise DecoderError {
  to_looped_decoder(self.decoder_builder_build())
}

///|
pub fn LoopedDecoder::next(self : LoopedDecoder) -> Sample? {
  if self.samples.is_empty() {
    None
  } else {
    let idx = self.cursor.val
    let value = self.samples[idx]
    self.cursor.val = (idx + 1) % self.samples.length()
    Some(value)
  }
}

///|
pub fn LoopedDecoder::channels(self : LoopedDecoder) -> ChannelCount {
  self.channels
}

///|
pub fn LoopedDecoder::sample_rate(self : LoopedDecoder) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for LoopedDecoder with next(self : LoopedDecoder) {
  self.next()
}

///|
pub impl Source for LoopedDecoder with channels(self : LoopedDecoder) {
  self.channels()
}

///|
pub impl Source for LoopedDecoder with sample_rate(self : LoopedDecoder) {
  self.sample_rate()
}

///|
pub impl Source for LoopedDecoder with current_span_len(self : LoopedDecoder) {
  if self.samples.is_empty() {
    None
  } else {
    Some(self.samples.length() - self.cursor.val)
  }
}

///|
pub impl Source for LoopedDecoder with total_duration(self : LoopedDecoder) {
  ignore(self)
  None
}

///|
pub impl Source for LoopedDecoder with try_seek(
  self : LoopedDecoder,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  if !self.seekable {
    raise SeekError::NotSupported
  }
  if self.samples.is_empty() {
    raise SeekError::NotSupported
  }
  let max_index = self.samples.length() - 1
  let target = sample_index_from_duration(
    pos,
    self.channels(),
    self.sample_rate(),
  )
  let clamped = if target < 0 {
    0
  } else if target > max_index {
    max_index
  } else {
    target
  }
  self.cursor.val = clamped
}

///|
fn bytes_eq4(
  bytes : Bytes,
  offset : Int,
  b0 : Int,
  b1 : Int,
  b2 : Int,
  b3 : Int,
) -> Bool {
  offset + 4 <= bytes.length() &&
  bytes[offset].to_int() == b0 &&
  bytes[offset + 1].to_int() == b1 &&
  bytes[offset + 2].to_int() == b2 &&
  bytes[offset + 3].to_int() == b3
}

///|
fn looks_like_wav(bytes : Bytes) -> Bool {
  bytes.length() >= 12 &&
  bytes_eq4(bytes, 0, 0x52, 0x49, 0x46, 0x46) &&
  bytes_eq4(bytes, 8, 0x57, 0x41, 0x56, 0x45)
}

///|
fn looks_like_flac(bytes : Bytes) -> Bool {
  bytes_eq4(bytes, 0, 0x66, 0x4c, 0x61, 0x43)
}

///|
fn looks_like_ogg(bytes : Bytes) -> Bool {
  bytes_eq4(bytes, 0, 0x4f, 0x67, 0x67, 0x53)
}

///|
fn looks_like_mp3(bytes : Bytes) -> Bool {
  if bytes.length() >= 3 &&
    bytes[0].to_int() == 0x49 &&
    bytes[1].to_int() == 0x44 &&
    bytes[2].to_int() == 0x33 {
    return true
  }

  if bytes.length() >= 2 {
    let b0 = bytes[0].to_int()
    let b1 = bytes[1].to_int()
    return b0 == 0xff && (b1 & 0xe0) == 0xe0
  }

  false
}

///|
fn decode_wav_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_wav_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded, seekable: true }
}

///|
fn decode_flac_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_flac_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded, seekable: true }
}

///|
fn decode_vorbis_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_vorbis_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded, seekable: true }
}

///|
fn decode_mp3_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_mp3_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded, seekable: true }
}

///|
pub fn Decoder::new(bytes : Bytes) -> Decoder raise DecoderError {
  guard bytes.length() > 0 else { raise DecoderError::UnknownFormat }

  if looks_like_wav(bytes) {
    return decode_wav_or_raise(bytes)
  }
  if looks_like_flac(bytes) {
    return decode_flac_or_raise(bytes)
  }
  if looks_like_ogg(bytes) {
    return decode_vorbis_or_raise(bytes)
  }
  if looks_like_mp3(bytes) {
    return decode_mp3_or_raise(bytes)
  }

  let try_wav = Some(decode_wav_or_raise(bytes)) catch { _ => None }
  match try_wav {
    Some(decoder) => return decoder
    None => ()
  }

  let try_flac = Some(decode_flac_or_raise(bytes)) catch { _ => None }
  match try_flac {
    Some(decoder) => return decoder
    None => ()
  }

  let try_vorbis = Some(decode_vorbis_or_raise(bytes)) catch { _ => None }
  match try_vorbis {
    Some(decoder) => return decoder
    None => ()
  }

  let try_mp3 = Some(decode_mp3_or_raise(bytes)) catch { _ => None }
  match try_mp3 {
    Some(decoder) => return decoder
    None => raise DecoderError::UnknownFormat
  }
}

///|
pub fn Decoder::builder() -> DecoderBuilder {
  DecoderBuilder::new()
}

///|
pub fn Decoder::new_looped(bytes : Bytes) -> LoopedDecoder raise DecoderError {
  Decoder::builder().with_data(bytes).build_looped()
}

///|
pub async fn Decoder::try_from_file(
  path : StringView,
) -> Decoder raise DecoderError {
  let bytes = try @fs.read_file(path).binary() catch {
    _ => raise DecoderError::UnknownFormat
  } noraise {
    bs => bs
  }
  Decoder::new(bytes)
}

///|
pub async fn Decoder::try_from_file_looped(
  path : StringView,
) -> LoopedDecoder raise DecoderError {
  let bytes = try @fs.read_file(path).binary() catch {
    _ => raise DecoderError::UnknownFormat
  } noraise {
    bs => bs
  }
  Decoder::new_looped(bytes)
}

///|
pub fn Decoder::new_wav(bytes : Bytes) -> Decoder raise DecoderError {
  decode_wav_or_raise(bytes)
}

///|
pub fn Decoder::new_flac(bytes : Bytes) -> Decoder raise DecoderError {
  decode_flac_or_raise(bytes)
}

///|
pub fn Decoder::new_vorbis(bytes : Bytes) -> Decoder raise DecoderError {
  decode_vorbis_or_raise(bytes)
}

///|
pub fn Decoder::new_mp3(bytes : Bytes) -> Decoder raise DecoderError {
  decode_mp3_or_raise(bytes)
}

///|
pub fn Decoder::next(self : Decoder) -> Sample? {
  self.inner.next()
}

///|
pub fn Decoder::channels(self : Decoder) -> ChannelCount {
  self.inner.channels()
}

///|
pub fn Decoder::sample_rate(self : Decoder) -> SampleRate {
  self.inner.sample_rate()
}

///|
pub impl Source for Decoder with next(self : Decoder) {
  self.next()
}

///|
pub impl Source for Decoder with channels(self : Decoder) {
  self.channels()
}

///|
pub impl Source for Decoder with sample_rate(self : Decoder) {
  self.sample_rate()
}

///|
pub impl Source for Decoder with current_span_len(self : Decoder) {
  let remaining = self.inner.len() - self.inner.position()
  if remaining <= 0 {
    Some(0)
  } else {
    Some(remaining)
  }
}

///|
pub impl Source for Decoder with total_duration(self : Decoder) {
  duration_from_sample_count(
    self.inner.len(),
    self.channels(),
    self.sample_rate(),
  )
}

///|
pub impl Source for Decoder with try_seek(
  self : Decoder,
  pos : @moon_cpal.Duration,
) -> Unit raise SeekError {
  if !self.seekable {
    raise SeekError::NotSupported
  }
  let target = sample_index_from_duration(
    pos,
    self.channels(),
    self.sample_rate(),
  )
  self.inner.seek_to(target)
}

///|
pub fn play(mixer : Mixer, bytes : Bytes) -> Sink raise PlayError {
  let source = try Decoder::new(bytes) catch {
    err => raise PlayError::DecoderError(err)
  } noraise {
    src => src
  }
  let sink = Sink::connect_new(mixer)
  sink.append(source)
  sink
}
