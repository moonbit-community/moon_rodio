///|
#borrow(input, out_meta)
extern "C" fn mp4a_decode_all_i16le(
  input : Bytes,
  input_len : Int,
  out_meta : FixedArray[UInt],
  out_meta_len : Int,
) -> Bytes = "moon_rodio_mp4a_decode_all_i16le"

///|
fn mp4a_read_i16_le(bytes : Bytes, offset : Int) -> Int {
  let u = bytes[offset].to_int() | (bytes[offset + 1].to_int() << 8)
  if u >= 0x8000 {
    u - 0x10000
  } else {
    u
  }
}

///|
pub fn decode_mp4a_bytes(bytes : Bytes) -> DecodedSamples raise DecoderError {
  guard bytes.length() > 0 else {
    raise DecoderError::InvalidFormat("mp4a bytes are empty")
  }

  let out_meta = FixedArray::make(3, (0 : UInt))
  let pcm = mp4a_decode_all_i16le(
    bytes,
    bytes.length(),
    out_meta,
    out_meta.length(),
  )

  let status = out_meta[0].reinterpret_as_int()
  if status == 100 {
    raise DecoderError::Unsupported(
      "mp4a decoder is only available on Apple platforms",
    )
  }
  guard status == 0 else {
    raise DecoderError::InvalidFormat(
      "mp4a decode failed (native status \{status})",
    )
  }

  let channels = out_meta[1].reinterpret_as_int()
  let sample_rate = out_meta[2].reinterpret_as_int()
  guard channels > 0 && sample_rate > 0 else {
    raise DecoderError::InvalidFormat("invalid decoded mp4a stream metadata")
  }

  guard pcm.length() % 2 == 0 else {
    raise DecoderError::InvalidFormat(
      "decoded mp4a pcm bytes must be i16-aligned",
    )
  }

  let sample_count = pcm.length() / 2
  let samples : Array[Double] = []
  for i in 0..<sample_count {
    let s = mp4a_read_i16_le(pcm, i * 2)
    samples.push(Double::from_int(s) / 32768.0)
  }

  DecodedSamples::new(channels, sample_rate, samples)
}
