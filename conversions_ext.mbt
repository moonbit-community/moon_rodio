///|
pub fn[S : Source] convert_channels(
  source : S,
  target_channels : ChannelCount,
) -> DynSource {
  guard target_channels > 0 else { panic() }
  channel_convert(to_dyn(source), target_channels)
}

///|
pub fn[S : Source] convert_sample_rate(
  source : S,
  target_sample_rate : SampleRate,
) -> DynSource {
  guard target_sample_rate > 0 else { panic() }
  sample_rate_convert(to_dyn(source), target_sample_rate)
}

///|
pub fn[S : Source] uniform(
  source : S,
  target_channels : ChannelCount,
  target_sample_rate : SampleRate,
) -> DynSource {
  guard target_channels > 0 else { panic() }
  guard target_sample_rate > 0 else { panic() }
  uniform_source(to_dyn(source), target_channels, target_sample_rate)
}
