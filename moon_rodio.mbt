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
/// - decoder sample-format and seek semantics are still a native-slice subset
