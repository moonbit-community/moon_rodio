///|
pub struct Chirp {
  sample_rate : SampleRate
  start_frequency : Double
  end_frequency : Double
  total_samples : Int
  elapsed_samples : Ref[Int]
  phase : Ref[Double]
}

///|
fn chirp_duration_to_samples(
  sample_rate : SampleRate,
  duration : @moon_cpal.Duration,
) -> Int {
  let secs_part = duration.secs.to_int() * sample_rate
  let nanos_part = duration.nanos * sample_rate / 1_000_000_000
  secs_part + nanos_part
}

///|
pub fn chirp(
  sample_rate : SampleRate,
  start_frequency : Double,
  end_frequency : Double,
  duration : @moon_cpal.Duration,
) -> Chirp {
  guard sample_rate > 0 else { panic() }
  guard start_frequency >= 0.0 else { panic() }
  guard end_frequency >= 0.0 else { panic() }

  {
    sample_rate,
    start_frequency,
    end_frequency,
    total_samples: chirp_duration_to_samples(sample_rate, duration),
    elapsed_samples: @ref.new(0),
    phase: @ref.new(0.0),
  }
}

///|
pub fn Chirp::next(self : Chirp) -> Sample? {
  if self.total_samples <= 0 || self.elapsed_samples.val >= self.total_samples {
    return None
  }

  let ratio = Double::from_int(self.elapsed_samples.val) /
    Double::from_int(self.total_samples)
  let freq = self.start_frequency * (1.0 - ratio) + self.end_frequency * ratio
  let out = @math.sin(2.0 * @math.PI * self.phase.val)
  self.phase.val += freq / Double::from_int(self.sample_rate)
  self.phase.val = wrap_phase(self.phase.val)
  self.elapsed_samples.val += 1
  Some(out)
}

///|
pub fn Chirp::channels(_self : Chirp) -> ChannelCount {
  1
}

///|
pub fn Chirp::sample_rate(self : Chirp) -> SampleRate {
  self.sample_rate
}

///|
pub impl Source for Chirp with next(self : Chirp) {
  self.next()
}

///|
pub impl Source for Chirp with channels(self : Chirp) {
  self.channels()
}

///|
pub impl Source for Chirp with sample_rate(self : Chirp) {
  self.sample_rate()
}

///|
pub struct FromFactoryIter[S] {
  factory : () -> S?
  current : Ref[DynSource?]
  channels : Ref[ChannelCount]
  sample_rate : Ref[SampleRate]
}

///|
pub fn[S : Source] from_factory(factory : () -> S?) -> FromFactoryIter[S] {
  let initial = factory()
  match initial {
    None =>
      {
        factory,
        current: @ref.new(None),
        channels: @ref.new(1),
        sample_rate: @ref.new(hz_44100),
      }
    Some(source) =>
      {
        factory,
        current: @ref.new(Some(to_dyn(source))),
        channels: @ref.new(source.channels()),
        sample_rate: @ref.new(source.sample_rate()),
      }
  }
}

///|
pub fn[S : Source] FromFactoryIter::next(self : FromFactoryIter[S]) -> Sample? {
  while true {
    match self.current.val {
      None => {
        let source = (self.factory)()
        match source {
          None => return None
          Some(next_source) => {
            self.channels.val = next_source.channels()
            self.sample_rate.val = next_source.sample_rate()
            self.current.val = Some(to_dyn(next_source))
          }
        }
      }
      Some(current) =>
        match current.next() {
          None => self.current.val = None
          Some(v) => return Some(v)
        }
    }
  }

  None
}

///|
pub fn[S] FromFactoryIter::channels(self : FromFactoryIter[S]) -> ChannelCount {
  self.channels.val
}

///|
pub fn[S] FromFactoryIter::sample_rate(self : FromFactoryIter[S]) -> SampleRate {
  self.sample_rate.val
}

///|
pub impl[S : Source] Source for FromFactoryIter[S] with next(
  self : FromFactoryIter[S],
) {
  self.next()
}

///|
pub impl[S : Source] Source for FromFactoryIter[S] with channels(
  self : FromFactoryIter[S],
) {
  self.channels()
}

///|
pub impl[S : Source] Source for FromFactoryIter[S] with sample_rate(
  self : FromFactoryIter[S],
) {
  self.sample_rate()
}
