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

///|
// Keep the async package as an explicit dependency for `async test` support.
let _async_now_ref : () -> Int64 = @async.now
