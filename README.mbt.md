# Milky2018/moon_rodio

[![Native CI](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml/badge.svg)](https://github.com/moonbit-community/moon_rodio/actions/workflows/ci-native.yml)

`moon_rodio` is a native-only MoonBit audio playback library modeled after Rust `rodio`.
It provides stream/sink-based playback, source transforms, and built-in decoding for
common audio formats.

## Target and scope

- Preferred target: `native`
- Output/input backend: `Milky2018/moon_cpal`
- API alignment follows Rust `rodio` where it makes sense in MoonBit
- Rust-specific lifetime/drop semantics are intentionally simplified

## Installation

Add the dependency to `moon.mod.json`:

```json
{
  "deps": {
    "Milky2018/moon_rodio": "0.1.2"
  },
  "preferred-target": "native"
}
```

## What is included

### `Milky2018/moon_rodio`

The main package includes:

- playback primitives such as `OutputStreamBuilder`, `Mixer`, `Sink`, and `Player`
- `Source` helpers and effects such as speed, gain, delay, fades, filters, queueing,
  repetition, spatial helpers, and WAV output helpers
- high-level decoding through `Decoder` and `DecoderBuilder`
- convenience helpers such as `play_file`, `play_bytes`, and `play_reader`

### `Milky2018/moon_rodio/decoder`

The decoder subpackage exposes lower-level decoding helpers such as:

- `decode_wav_bytes`
- `decode_mp3_bytes`
- `decode_flac_bytes`
- `decode_vorbis_bytes`
- `decode_mp4a_bytes`

Most users should start with `Milky2018/moon_rodio` and use `Decoder`.

## Supported formats

- WAV
- MP3
- FLAC
- Ogg Vorbis
- MP4A / AAC

Backend notes:

- WAV uses a native parser
- MP3 uses vendored `minimp3`
- FLAC uses vendored `dr_flac`
- Vorbis uses vendored `stb_vorbis`
- MP4A / AAC:
  - macOS: AudioToolbox
  - Linux / Windows: FFmpeg

## Platform notes for MP4A / AAC

On macOS, MP4A works through the system AudioToolbox framework.

On Linux and Windows, MP4A requires FFmpeg development libraries to be available to
native builds. `build.js` tries to discover them automatically, and you can also
provide them explicitly:

- `MOON_RODIO_FFMPEG_CFLAGS`
- `MOON_RODIO_FFMPEG_LIBS`
- `MOON_RODIO_ENABLE_FFMPEG=1`

Example:

```bash
MOON_RODIO_FFMPEG_CFLAGS="-I/path/to/include" \
MOON_RODIO_FFMPEG_LIBS="-L/path/to/lib -lavformat -lavcodec -lavutil -lswresample" \
MOON_RODIO_ENABLE_FFMPEG=1 \
moon run cmd/main --target native
```

## Quick start

Play a file from disk:

```moonbit nocheck
import "Milky2018/moon_rodio"

fn play_file_example(path : String) -> Unit {
  let stream = try {
    OutputStreamBuilder::open_default_stream()
  } catch {
    _ => return
  } noraise {
    stream => stream
  }

  let player = try {
    play_file(stream.mixer(), path)
  } catch {
    _ => return
  } noraise {
    player => player
  }

  player.sleep_until_end()
}
```

Decode audio from bytes:

```moonbit nocheck
import "Milky2018/moon_rodio"

fn decode_bytes_example(bytes : Bytes) -> Unit {
  let decoder = try {
    Decoder::builder()
      .with_data(bytes)
      .with_hint("mp3")
      .with_seekable(true)
      .build()
  } catch {
    _ => return
  } noraise {
    decoder => decoder
  }

  println(decoder.channels().to_string())
  println(decoder.sample_rate().to_string())
}
```

Play generated samples:

```moonbit nocheck
import "Milky2018/moon_rodio"

fn play_sine_like_example() -> Unit {
  let stream = try {
    OutputStreamBuilder::open_default_stream()
  } catch {
    _ => return
  } noraise {
    stream => stream
  }

  let sink = Sink::connect_new(stream.mixer())
  let source = SamplesBuffer::new(1, 44_100, [0.0, 0.2, 0.0, -0.2])
  sink.append(source.repeat_infinite())
}
```
