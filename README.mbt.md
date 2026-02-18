# Milky2018/moon_rodio

[![Native CI](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml/badge.svg)](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml)

Native-only MoonBit port of Rust `rodio` with `preferred-target: native`.

This package focuses on `Stream`/`Sink` style playback composition while aligning API
surface and behavior to the upstream project as far as MoonBit allows.

## Supported Targets

- Preferred target: `native`
- Native output is powered by `Milky2018/moon_cpal`
- Lifecycle-drop semantics are intentionally simplified (MoonBit does not expose the same
  Rust lifetime/drop model)

## Modules

- `Milky2018/moon_rodio`
  - Playback pipeline (`Stream`, `Sink`, `Mixer`, `Source`, helpers)
  - Audio effects and transforms (speed, gain, filters, controls, spatial helpers, queue, etc.)
  - Built-in WAV decoding bridge
  - Native input/output builders: `MicrophoneBuilder`, `SpeakersBuilder`
  - Compatibility slices: `StaticSamplesBuffer`, `FixedSource`, `FixedSamplesBuffer`, `FixedSourceAdapter`
  - Naming-compat wrappers: `Player`, `SpatialPlayer`, `DeviceSinkBuilder`, `MixerDeviceSink`
  - Convenience helpers: `play(...)`, `play_reader(...)`, `play_file(...)`, `wav_to_file(...)`, `wav_to_writer(...)`
  - Dither API slice: `BitDepth`, `DitherAlgorithm`, `dither(...)`
- `Milky2018/moon_rodio/decoder`
  - Generic decoder builder and `LoopedDecoder`
  - Format detection via hints, MIME, and data heuristics

## Decoder backends

- WAV: native parser (always available)
- MP3: vendored `minimp3`
- FLAC: vendored `dr_flac`
- Vorbis: vendored `stb_vorbis`
- MP4A/AAC:
  - macOS: AudioToolbox backend
  - Linux/Windows: FFmpeg backend (optional)

## Quick start

```moonbit nocheck
import "Milky2018/moon_rodio"
import "Milky2018/moon_rodio/decoder"
import "moonbitlang/core/array"

fn example() {
  // open a native output stream from the default device
  let stream = try {
    OutputStreamBuilder::open_default_stream()
  } catch err {
    // handle StreamError
    return
  }

  // connect a sink to the stream mixer
  let sink = Sink::connect_new(stream.mixer())

  // play synthetic samples
  sink.append(SamplesBuffer::new(1, 44_100, [0.0, 0.0, 0.0]))

  // optionally block until playback is finished
  sink.sleep_until_end()
}
```

Decoder usage:

```moonbit nocheck
import "Milky2018/moon_rodio/decoder"
import "moonbitlang/x/fs"

fn decode_file(path : String) {
  let bytes = try fs.read_file_to_bytes(path) catch {
    _ => return
  } noraise {
    bs => bs
  }
  let decoded = DecoderBuilder::new()
    .with_data(bytes)
    .with_mime_type("audio/mpeg")
    .build()
}
```

The returned decoder implements `Source`, so you can append it to `Sink` directly.

## FFmpeg backend (Linux / Windows MP4A)

`build.js` enables MP4A/AAC decoding via FFmpeg when link flags are available.

### Linux auto-detect
- `pkg-config` is used to discover:
  - `libavformat`
  - `libavcodec`
  - `libavutil`
  - `libswresample`

### Windows notes
- CI downloads a pinned prebuilt FFmpeg package from `GyanD/codexffmpeg` and verifies
  the SHA256 digest before extraction
- `Milky2018/moon_cpal@0.11.3` removed the previous `strings.h` MSVC blocker in ALSA stub
- CI Windows lane uses MSVC (`cl`/`lib`) for compatibility with `moonbitlang/async` on Windows
- CI validates FFmpeg on Windows strictly (checksum + required headers/libs + prebuild detection + native tests)

### Manual override (any platform)
- `MOON_RODIO_FFMPEG_CFLAGS`
- `MOON_RODIO_FFMPEG_LIBS`
- `MOON_RODIO_ENABLE_FFMPEG=1` (forced enable by environment)

Example:

```bash
MOON_RODIO_FFMPEG_CFLAGS="-I/path/to/include" \
MOON_RODIO_FFMPEG_LIBS="-L/path/to/lib -lavformat -lavcodec -lavutil -lswresample" \
MOON_RODIO_ENABLE_FFMPEG=1 \
moon test --target native
```

## Build & test

```bash
moon test --target native
moon test --target native --update   # refresh snapshot tests if needed
```

For publish/update metadata:

```bash
moon info && moon fmt
```

## Test assets

Reference fixtures required by native decoder tests are vendored in:

- `test_assets/rodio`

This avoids CI depending on a local ignored `rodio-reference` checkout.

## Links

- `Milky2018/moon_rodio` (this package)
- `Milky2018/moon_cpal`
- `Milky2018/moon_rodio/decoder`
