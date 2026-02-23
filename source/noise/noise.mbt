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
pub using @Milky2018/moon_rodio {trait NoiseRng}

///|
pub type LcgNoiseRng = @Milky2018/moon_rodio.LcgNoiseRng

///|
pub type WhiteUniform = @Milky2018/moon_rodio.WhiteUniform

///|
pub type WhiteTriangular = @Milky2018/moon_rodio.WhiteTriangular

///|
pub type WhiteGaussian = @Milky2018/moon_rodio.WhiteGaussian

///|
pub type Pink = @Milky2018/moon_rodio.Pink

///|
pub type Blue = @Milky2018/moon_rodio.Blue

///|
pub type Violet = @Milky2018/moon_rodio.Violet

///|
pub type Brownian = @Milky2018/moon_rodio.Brownian

///|
pub type Red = @Milky2018/moon_rodio.Red

///|
pub type Velvet = @Milky2018/moon_rodio.Velvet

///|
pub fn white(sample_rate : Int) -> WhiteUniform {
  @Milky2018/moon_rodio.white(sample_rate)
}

///|
pub fn pink(sample_rate : Int) -> Pink {
  @Milky2018/moon_rodio.pink(sample_rate)
}
