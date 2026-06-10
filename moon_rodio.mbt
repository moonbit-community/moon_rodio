// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// MoonBit port (MVP slice) of RustAudio/rodio.
///
/// Current focus:
/// - native backend (`preferred-target: native`)
/// - broad `source::*` parity (filters, wrappers, controls, noise generators)
/// - `queue`/`mixer`/`sink`/`stream` playback chain via `Milky2018/moon_cpal`
/// - decoder/play path for WAV/MP3/FLAC/Vorbis bytes input
///
/// Known gaps versus upstream rodio:
/// - no automatic drop-hook parity (MoonBit currently lacks Rust-style `Drop`)
/// - some APIs are compatibility aliases over simplified internals
/// - non-Apple MP4A decode requires FFmpeg dev toolchain at build time
