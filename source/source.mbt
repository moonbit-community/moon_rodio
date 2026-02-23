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
pub type AutomaticGainControl = @Milky2018/moon_rodio.AutomaticGainControl

///|
pub type AutomaticGainControlSettings = @Milky2018/moon_rodio.AutomaticGainControlSettings

///|
pub type Amplify = @Milky2018/moon_rodio.Amplify

///|
pub type BltFilter = @Milky2018/moon_rodio.BltFilter

///|
pub type Buffered = @Milky2018/moon_rodio.Buffered

///|
pub type ChannelVolume = @Milky2018/moon_rodio.ChannelVolume

///|
pub type Chirp = @Milky2018/moon_rodio.Chirp

///|
pub type Crossfade = @Milky2018/moon_rodio.Crossfade

///|
pub type Delay = @Milky2018/moon_rodio.Delay

///|
pub type Distortion = @Milky2018/moon_rodio.Distortion

///|
pub type Done = @Milky2018/moon_rodio.Done

///|
pub type Empty = @Milky2018/moon_rodio.Empty

///|
pub type EmptyCallback = @Milky2018/moon_rodio.EmptyCallback

///|
pub type FadeIn = @Milky2018/moon_rodio.FadeIn

///|
pub type FadeOut = @Milky2018/moon_rodio.FadeOut

///|
pub type FromFactoryIter[S] = @Milky2018/moon_rodio.FromFactoryIter[S]

///|
pub type FromIter = @Milky2018/moon_rodio.FromIter

///|
pub type Limit = @Milky2018/moon_rodio.Limit

///|
pub type LimitSettings = @Milky2018/moon_rodio.LimitSettings

///|
pub type LinearGainRamp = @Milky2018/moon_rodio.LinearGainRamp

///|
pub type Mix = @Milky2018/moon_rodio.Mix

///|
pub type Pausable = @Milky2018/moon_rodio.Pausable

///|
pub type PeriodicAccess = @Milky2018/moon_rodio.PeriodicAccess

///|
pub type TrackPosition = @Milky2018/moon_rodio.TrackPosition

///|
pub type Repeat = @Milky2018/moon_rodio.Repeat

///|
pub type SawtoothWave = @Milky2018/moon_rodio.SawtoothWave

///|
pub type Function = @Milky2018/moon_rodio.Function

///|
pub type GeneratorFunction = @Milky2018/moon_rodio.GeneratorFunction

///|
pub type SignalGenerator = @Milky2018/moon_rodio.SignalGenerator

///|
pub type SineWave = @Milky2018/moon_rodio.SineWave

///|
pub type SkipDuration = @Milky2018/moon_rodio.SkipDuration

///|
pub type Skippable = @Milky2018/moon_rodio.Skippable

///|
pub type Spatial = @Milky2018/moon_rodio.Spatial

///|
pub type Speed = @Milky2018/moon_rodio.Speed

///|
pub type SquareWave = @Milky2018/moon_rodio.SquareWave

///|
pub type Stoppable = @Milky2018/moon_rodio.Stoppable

///|
pub type TakeDuration = @Milky2018/moon_rodio.TakeDuration

///|
pub type TriangleWave = @Milky2018/moon_rodio.TriangleWave

///|
pub type UniformSourceIterator = @Milky2018/moon_rodio.UniformSourceIterator

///|
pub type Zero = @Milky2018/moon_rodio.Zero

///|
pub type DitherAlgorithm = @Milky2018/moon_rodio.DitherAlgorithm

///|
pub type Dither = @Milky2018/moon_rodio.Dither

///|
pub type Pink = @Milky2018/moon_rodio.Pink

///|
pub type WhiteUniform = @Milky2018/moon_rodio.WhiteUniform

///|
pub fn chirp(
  sample_rate : Int,
  start_frequency : Double,
  end_frequency : Double,
  duration : @moon_cpal.Duration,
) -> Chirp {
  @Milky2018/moon_rodio.chirp(
    sample_rate, start_frequency, end_frequency, duration,
  )
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] from_factory(
  factory : () -> S?,
) -> FromFactoryIter[S] {
  @Milky2018/moon_rodio.from_factory(factory)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] from_iter(
  sources : Array[S],
) -> FromIter {
  @Milky2018/moon_rodio.from_iter(sources)
}
