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
pub async fn[S : Source] output_to_wav(
  source : S,
  wav_file : StringView,
) -> Unit {
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

  @fs.write_file(wav_file, buf.to_bytes(), create=0o644, truncate=true)
}
