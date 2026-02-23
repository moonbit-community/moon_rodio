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
pub type Function = @Milky2018/moon_rodio.Function

///|
pub type GeneratorFunction = @Milky2018/moon_rodio.GeneratorFunction

///|
pub type SignalGenerator = @Milky2018/moon_rodio.SignalGenerator

///|
pub type SineWave = @Milky2018/moon_rodio.SineWave

///|
pub type SquareWave = @Milky2018/moon_rodio.SquareWave

///|
pub type SawtoothWave = @Milky2018/moon_rodio.SawtoothWave

///|
pub type TriangleWave = @Milky2018/moon_rodio.TriangleWave

///|
pub fn with_function(
  sample_rate : Int,
  frequency : Double,
  function : Function,
) -> SignalGenerator {
  SignalGenerator::with_function(sample_rate, frequency, function)
}

///|
pub fn with_generator(
  sample_rate : Int,
  frequency : Double,
  function : GeneratorFunction,
) -> @Milky2018/moon_rodio.DynSource {
  SignalGenerator::with_generator(sample_rate, frequency, function)
}
