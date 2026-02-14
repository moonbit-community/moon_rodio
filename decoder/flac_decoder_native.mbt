///|
#borrow(input, out_meta)
extern "C" fn flac_decode_all_i16le(
  input : Bytes,
  input_len : Int,
  out_meta : FixedArray[UInt],
  out_meta_len : Int,
) -> Bytes = "moon_rodio_flac_decode_all_i16le"

///|
fn flac_read_i16_le(bytes : Bytes, offset : Int) -> Int {
  let u = bytes[offset].to_int() | (bytes[offset + 1].to_int() << 8)
  if u >= 0x8000 {
    u - 0x10000
  } else {
    u
  }
}

///|
pub fn decode_flac_bytes(bytes : Bytes) -> DecodedSamples raise DecoderError {
  guard bytes.length() > 0 else {
    raise DecoderError::InvalidFormat("flac bytes are empty")
  }

  let out_meta = FixedArray::make(3, (0 : UInt))
  let pcm = flac_decode_all_i16le(
    bytes,
    bytes.length(),
    out_meta,
    out_meta.length(),
  )

  let status = out_meta[0].reinterpret_as_int()
  guard status == 0 else {
    raise DecoderError::InvalidFormat(
      "flac decode failed (dr_flac status \{status})",
    )
  }

  let channels = out_meta[1].reinterpret_as_int()
  let sample_rate = out_meta[2].reinterpret_as_int()
  guard channels > 0 && sample_rate > 0 else {
    raise DecoderError::InvalidFormat("invalid decoded flac stream metadata")
  }

  guard pcm.length() % 2 == 0 else {
    raise DecoderError::InvalidFormat(
      "decoded flac pcm bytes must be i16-aligned",
    )
  }

  let sample_count = pcm.length() / 2
  let samples : Array[Double] = []
  for i in 0..<sample_count {
    let s = flac_read_i16_le(pcm, i * 2)
    samples.push(Double::from_int(s) / 32768.0)
  }

  DecodedSamples::new(channels, sample_rate, samples)
}
