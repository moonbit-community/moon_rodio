# Milky2018/moon_rodio

[![Native CI](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml/badge.svg)](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml)

`moon_rodio` is a native-only MoonBit audio playback library.
It provides in-memory playback composition through `Mixer`, `Sink`, `Player`, and
`Source`, plus built-in decoders for common audio formats.

## Scope

- Preferred target: `native`
- Output and input are built on `Milky2018/moon_cpal`
- The main package is `Milky2018/moon_rodio`
- The lower-level decoder package is `Milky2018/moon_rodio/decoder`

## Installation

- Add `"Milky2018/moon_rodio": "0.2.0"` to `deps` in `moon.mod.json`
- Set `"preferred-target": "native"` in `moon.mod.json`

## Packages

### `Milky2018/moon_rodio`

Use this package for the normal playback API:

- `OutputStreamBuilder`
- `Mixer`
- `Sink`
- `Player`
- `Decoder` and `Decoder::builder()`
- source helpers such as gain, speed, delay, fades, filters, spatial helpers, and WAV output helpers

### `Milky2018/moon_rodio/decoder`

Use this package when you want lower-level byte-to-sample decoding helpers directly:

- `decode_wav_bytes`
- `decode_mp3_bytes`
- `decode_flac_bytes`
- `decode_vorbis_bytes`
- `decode_mp4a_bytes`

## Supported formats

- WAV
- MP3
- FLAC
- Ogg Vorbis
- MP4A / AAC

Backend notes:

- WAV: native parser
- MP3: vendored `minimp3`
- FLAC: vendored `dr_flac`
- Vorbis: vendored `stb_vorbis`
- MP4A / AAC:
  - macOS: AudioToolbox
  - Linux / Windows: FFmpeg

## MP4A / AAC on Linux and Windows

MP4A on Linux and Windows depends on FFmpeg development libraries being available to
native builds.

`build.js` will try to discover them automatically. If auto-detection does not fit
your environment, set these variables explicitly before building or testing:

- `MOON_RODIO_FFMPEG_CFLAGS`
- `MOON_RODIO_FFMPEG_LIBS`
- `MOON_RODIO_ENABLE_FFMPEG=1`

## Quick start

Create an in-memory playback chain:

```mbt check
///|
test "readme: in-memory playback chain" {
  let (tx, rx) = mixer(1, 44_100)
  let sink = Sink::connect_new(tx)
  let source = SamplesBuffer::new(1, 44_100, [0.0, 0.25, 0.0, -0.25])

  sink.append(source)
  assert_eq(rx.next(), Some(0.0))
}
```

Decode audio bytes with the high-level decoder API:

```mbt check
///|
test "readme: decoder builder" {
  let decoder = Decoder::builder()
    .with_data(@decoder.mp3_ill2_mono_bytes())
    .with_hint("mp3")
    .with_seekable(true)
    .build()

  assert_eq(decoder.channels(), 1)
  assert_eq(decoder.sample_rate(), 48_000)
}
```

Play embedded bytes through a mixer:

```mbt check
///|
test "readme: play bytes through mixer" {
  let (tx, _rx) = mixer(1, 44_100)
  let player = play_bytes(tx, @decoder.flac_pop_bytes())

  player.pause()
  player.play()
}
```

For files on disk, use `play_file(...)`, `Reader::from_file(...)`, or
`Decoder::try_from_file(...)`.
