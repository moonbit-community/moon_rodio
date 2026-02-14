///|
pub struct ChannelCountConverter {
  inner : DynSource
  to : ChannelCount
}

///|
pub fn[S : Source] ChannelCountConverter::new(
  input : S,
  from : ChannelCount,
  to : ChannelCount,
) -> ChannelCountConverter {
  guard from > 0 else { panic() }
  guard to > 0 else { panic() }
  let src = to_dyn(input)
  guard src.channels() == from else { panic() }
  { inner: channel_convert(src, to), to }
}

///|
pub fn ChannelCountConverter::inner_mut(
  self : ChannelCountConverter,
) -> DynSource {
  self.inner
}

///|
pub fn ChannelCountConverter::into_inner(
  self : ChannelCountConverter,
) -> DynSource {
  self.inner
}

///|
pub impl Source for ChannelCountConverter with next(
  self : ChannelCountConverter,
) {
  self.inner.next()
}

///|
pub impl Source for ChannelCountConverter with channels(
  self : ChannelCountConverter,
) {
  self.to
}

///|
pub impl Source for ChannelCountConverter with sample_rate(
  self : ChannelCountConverter,
) {
  self.inner.sample_rate()
}

///|
pub struct SampleRateConverter {
  inner : DynSource
  to : SampleRate
  channels : ChannelCount
}

///|
pub fn[S : Source] SampleRateConverter::new(
  input : S,
  from : SampleRate,
  to : SampleRate,
  num_channels : ChannelCount,
) -> SampleRateConverter {
  guard from > 0 else { panic() }
  guard to > 0 else { panic() }
  guard num_channels > 0 else { panic() }
  let src = to_dyn(input)
  guard src.sample_rate() == from else { panic() }
  guard src.channels() == num_channels else { panic() }
  { inner: sample_rate_convert(src, to), to, channels: num_channels }
}

///|
pub fn SampleRateConverter::inner_mut(self : SampleRateConverter) -> DynSource {
  self.inner
}

///|
pub fn SampleRateConverter::into_inner(self : SampleRateConverter) -> DynSource {
  self.inner
}

///|
pub impl Source for SampleRateConverter with next(self : SampleRateConverter) {
  self.inner.next()
}

///|
pub impl Source for SampleRateConverter with channels(
  self : SampleRateConverter,
) {
  self.channels
}

///|
pub impl Source for SampleRateConverter with sample_rate(
  self : SampleRateConverter,
) {
  self.to
}

///|
pub struct SampleTypeConverter {
  inner : DynSource
}

///|
pub fn[S : Source] SampleTypeConverter::new(input : S) -> SampleTypeConverter {
  { inner: to_dyn(input) }
}

///|
pub fn SampleTypeConverter::inner_mut(self : SampleTypeConverter) -> DynSource {
  self.inner
}

///|
pub fn SampleTypeConverter::into_inner(self : SampleTypeConverter) -> DynSource {
  self.inner
}

///|
pub impl Source for SampleTypeConverter with next(self : SampleTypeConverter) {
  self.inner.next()
}

///|
pub impl Source for SampleTypeConverter with channels(
  self : SampleTypeConverter,
) {
  self.inner.channels()
}

///|
pub impl Source for SampleTypeConverter with sample_rate(
  self : SampleTypeConverter,
) {
  self.inner.sample_rate()
}
