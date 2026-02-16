///|
fn read_u16_le(bytes : Bytes, offset : Int) -> Int {
  bytes[offset].to_int() | (bytes[offset + 1].to_int() << 8)
}

///|
fn read_u32_le(bytes : Bytes, offset : Int) -> Int {
  bytes[offset].to_int() |
  (bytes[offset + 1].to_int() << 8) |
  (bytes[offset + 2].to_int() << 16) |
  (bytes[offset + 3].to_int() << 24)
}

///|
fn read_i16_le(bytes : Bytes, offset : Int) -> Int {
  let u = read_u16_le(bytes, offset)
  if u >= 0x8000 {
    u - 0x10000
  } else {
    u
  }
}

///|
fn read_i24_le(bytes : Bytes, offset : Int) -> Int {
  let u = bytes[offset].to_int() |
    (bytes[offset + 1].to_int() << 8) |
    (bytes[offset + 2].to_int() << 16)
  if u >= 0x800000 {
    u - 0x1000000
  } else {
    u
  }
}

///|
fn read_i32_le(bytes : Bytes, offset : Int) -> Int {
  read_u32_le(bytes, offset)
}

///|
fn pow2(exp : Int) -> Double {
  if exp >= 0 {
    let mut v = 1.0
    for _ in 0..<exp {
      v *= 2.0
    }
    v
  } else {
    let mut v = 1.0
    for _ in 0..<-exp {
      v *= 0.5
    }
    v
  }
}

///|
fn decode_f32_bits(bits : Int) -> Double {
  let sign = if bits < 0 { -1.0 } else { 1.0 }
  let exponent = (bits >> 23) & 0xff
  let fraction = bits & 0x7fffff
  if exponent == 255 {
    if fraction == 0 {
      if sign > 0.0 {
        1.0 / 0.0
      } else {
        -1.0 / 0.0
      }
    } else {
      0.0 / 0.0
    }
  } else if exponent == 0 {
    if fraction == 0 {
      if sign > 0.0 {
        0.0
      } else {
        -0.0
      }
    } else {
      sign * pow2(-126) * (Double::from_int(fraction) / 8_388_608.0)
    }
  } else {
    sign *
    pow2(exponent - 127) *
    (1.0 + Double::from_int(fraction) / 8_388_608.0)
  }
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
pub fn decode_wav_bytes(bytes : Bytes) -> DecodedSamples raise DecoderError {
  guard bytes.length() >= 12 else {
    raise DecoderError::InvalidFormat("wav header too short")
  }

  guard bytes_eq4(bytes, 0, 0x52, 0x49, 0x46, 0x46) else {
    raise DecoderError::InvalidFormat("missing RIFF")
  }
  guard bytes_eq4(bytes, 8, 0x57, 0x41, 0x56, 0x45) else {
    raise DecoderError::InvalidFormat("missing WAVE")
  }

  let mut audio_format = -1
  let mut channels = -1
  let mut sample_rate = -1
  let mut block_align = -1
  let mut bits_per_sample = -1
  let mut valid_bits_per_sample = -1
  let mut data_offset = -1
  let mut data_len = 0

  let mut offset = 12
  while offset + 8 <= bytes.length() {
    let chunk_len = read_u32_le(bytes, offset + 4)
    let chunk_data = offset + 8
    guard chunk_len >= 0 && chunk_data + chunk_len <= bytes.length() else {
      raise DecoderError::InvalidFormat("chunk length out of bounds")
    }

    if bytes_eq4(bytes, offset, 0x66, 0x6d, 0x74, 0x20) {
      guard chunk_len >= 16 else {
        raise DecoderError::InvalidFormat("fmt chunk too short")
      }
      audio_format = read_u16_le(bytes, chunk_data)
      channels = read_u16_le(bytes, chunk_data + 2)
      sample_rate = read_u32_le(bytes, chunk_data + 4)
      block_align = read_u16_le(bytes, chunk_data + 12)
      bits_per_sample = read_u16_le(bytes, chunk_data + 14)
      if chunk_len >= 18 {
        let cb_size = read_u16_le(bytes, chunk_data + 16)
        if audio_format == 0xfffe && cb_size >= 22 && chunk_len >= 40 {
          valid_bits_per_sample = read_u16_le(bytes, chunk_data + 18)
          audio_format = read_u16_le(bytes, chunk_data + 24)
        }
      }
    } else if bytes_eq4(bytes, offset, 0x64, 0x61, 0x74, 0x61) {
      data_offset = chunk_data
      data_len = chunk_len
    }

    offset = chunk_data + chunk_len
    if offset % 2 == 1 {
      offset += 1
    }
  }

  guard audio_format != -1 &&
    channels != -1 &&
    sample_rate != -1 &&
    data_offset != -1 else {
    raise DecoderError::InvalidFormat("missing fmt or data chunk")
  }

  guard channels > 0 && sample_rate > 0 else {
    raise DecoderError::InvalidFormat("invalid channel count or sample rate")
  }

  let effective_bits = if valid_bits_per_sample > 0 {
    valid_bits_per_sample
  } else {
    bits_per_sample
  }
  let bytes_per_sample = if effective_bits <= 8 {
    1
  } else if effective_bits <= 16 {
    2
  } else if effective_bits <= 24 {
    3
  } else if effective_bits <= 32 {
    4
  } else {
    raise DecoderError::Unsupported("unsupported bits per sample")
  }
  let expected_block_align = channels * bytes_per_sample
  guard block_align == expected_block_align else {
    raise DecoderError::InvalidFormat("invalid block align")
  }
  guard data_len % bytes_per_sample == 0 else {
    raise DecoderError::InvalidFormat("data chunk alignment is invalid")
  }

  let sample_count = data_len / bytes_per_sample
  let samples : Array[Double] = []
  if audio_format == 1 {
    match effective_bits {
      8 =>
        for i in 0..<sample_count {
          let s = bytes[data_offset + i].to_int() - 128
          samples.push(Double::from_int(s) / 128.0)
        }
      16 =>
        for i in 0..<sample_count {
          let s = read_i16_le(bytes, data_offset + i * 2)
          samples.push(Double::from_int(s) / 32768.0)
        }
      24 =>
        for i in 0..<sample_count {
          let s = read_i24_le(bytes, data_offset + i * 3)
          samples.push(Double::from_int(s) / 8_388_608.0)
        }
      32 =>
        for i in 0..<sample_count {
          let s = read_i32_le(bytes, data_offset + i * 4)
          samples.push(Double::from_int(s) / 2_147_483_648.0)
        }
      _ => raise DecoderError::Unsupported("unsupported PCM bit depth")
    }
  } else if audio_format == 3 {
    guard effective_bits == 32 else {
      raise DecoderError::Unsupported("only 32-bit IEEE float is supported")
    }
    for i in 0..<sample_count {
      let bits = read_u32_le(bytes, data_offset + i * 4)
      samples.push(decode_f32_bits(bits))
    }
  } else {
    raise DecoderError::Unsupported("unsupported WAV format")
  }

  DecodedSamples::new(channels, sample_rate, samples)
}
