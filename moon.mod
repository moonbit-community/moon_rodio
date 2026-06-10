name = "Milky2018/moon_rodio"

version = "0.3.2"

import {
  "moonbitlang/x@0.4.40",
  "Milky2018/moon_cpal@0.11.7",
}

readme = "README.mbt.md"

repository = "https://github.com/moonbit-community/moon_rodio"

license = "Apache-2.0"

keywords = [ "audio" ]

description = "Native-only MoonBit port of Rust rodio with playback pipeline, source effects, and WAV/MP3/FLAC/Vorbis/MP4A decoding."

preferred_target = "native"

options(
  exclude: [ "test_assets" ],
  "--moonbit-unstable-prebuild": "build.js",
)
