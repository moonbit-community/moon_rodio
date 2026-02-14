///|
pub suberror DecoderError {
  Backend(@decoder.DecoderError)
  UnknownFormat
} derive(Show, Eq)

///|
pub suberror PlayError {
  Decode(DecoderError)
} derive(Show, Eq)

///|
pub struct Decoder {
  inner : @decoder.DecodedSamples
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
  { inner: decoded }
}

///|
fn decode_flac_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_flac_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded }
}

///|
fn decode_vorbis_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_vorbis_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded }
}

///|
fn decode_mp3_or_raise(bytes : Bytes) -> Decoder raise DecoderError {
  let decoded = try @decoder.decode_mp3_bytes(bytes) catch {
    err => raise DecoderError::Backend(err)
  } noraise {
    src => src
  }
  { inner: decoded }
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
pub fn play(mixer : Mixer, bytes : Bytes) -> Sink raise PlayError {
  let source = try Decoder::new(bytes) catch {
    err => raise PlayError::Decode(err)
  } noraise {
    src => src
  }
  let sink = Sink::connect_new(mixer)
  sink.append(source)
  sink
}
