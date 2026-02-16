# Milky2018/moon_rodio

Native-only MoonBit port of `rodio` (`preferred-target: native`).

## Decoder backends

- WAV: native parser
- MP3: `minimp3` (vendored C backend)
- FLAC: `dr_flac` (vendored C backend)
- Vorbis: `stb_vorbis` (vendored C backend)
- MP4A/AAC:
  - macOS: AudioToolbox backend
  - Linux/Windows: optional FFmpeg backend

## FFmpeg backend (Linux/Windows MP4A)

`build.js` enables FFmpeg MP4A decode when FFmpeg flags are available.

- Linux: auto-detected via `pkg-config` for
  `libavformat`, `libavcodec`, `libavutil`, `libswresample`
- Any platform: manual override with environment variables
  - `MOON_RODIO_FFMPEG_CFLAGS`
  - `MOON_RODIO_FFMPEG_LIBS`

Example:

```bash
MOON_RODIO_FFMPEG_CFLAGS="-I/path/to/include" \
MOON_RODIO_FFMPEG_LIBS="-L/path/to/lib -lavformat -lavcodec -lavutil -lswresample" \
moon test --target native
```
