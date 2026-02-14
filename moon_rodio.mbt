///|
/// MoonBit port (MVP slice) of RustAudio/rodio.
///
/// Implemented in this milestone:
/// - `Source` / `SamplesBuffer`
/// - source generators and filters: `SineWave`/`SquareWave`/`SawtoothWave`/`TriangleWave`,
///   `empty`/`zero`/`amplify`/`take`/`mix`/`speed`/`repeat_infinite`,
///   `pausable`/`stoppable`/`skippable`
/// - `SpatialSource` and `SpatialSink`
/// - `queue` and `mixer` with upstream-parity tests
/// - `Sink` and `OutputStreamBuilder` backed by `Milky2018/moon_cpal`
/// - `Decoder` and `play` (WAV/MP3/FLAC/Vorbis bytes input)
///
/// Not implemented yet:
/// - most `source::*` filters
/// - full sample-format parity with upstream rodio decoders
/// - blocking controls such as `sleep_until_end`
