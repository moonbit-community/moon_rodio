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
#cfg(target="native")
async test "rodio::wav_output::output_to_wav" {
  let path = "_build/rodio_output_to_wav_test.wav"
  if @fs.exists(path) {
    @fs.remove(path)
  }

  let source = SamplesBuffer::new(1, 48_000, [0.0, 0.5, -0.5, 1.0])
  output_to_wav(source, path)

  assert_true(@fs.exists(path))
  let bytes = @fs.read_file(path).binary()
  assert_true(bytes.length() >= 44)
  assert_true(bytes_eq4(bytes, 0, 0x52, 0x49, 0x46, 0x46))
  assert_true(bytes_eq4(bytes, 8, 0x57, 0x41, 0x56, 0x45))
  assert_true(bytes_eq4(bytes, 12, 0x66, 0x6d, 0x74, 0x20))
  assert_true(bytes_eq4(bytes, 36, 0x64, 0x61, 0x74, 0x61))

  assert_eq(read_u16_le(bytes, 20), 3)
  assert_eq(read_u16_le(bytes, 22), 1)
  assert_eq(read_u32_le(bytes, 24), 48_000)
  assert_eq(read_u16_le(bytes, 34), 32)
  assert_eq(read_u32_le(bytes, 40), 16)
  assert_eq(bytes.length(), 60)

  @fs.remove(path)
}
