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
pub type BltFilter = @Milky2018/moon_rodio.BltFilter

///|
pub fn[S : @Milky2018/moon_rodio.Source] low_pass(
  source : S,
  freq : Int,
) -> BltFilter {
  @Milky2018/moon_rodio.low_pass(source, freq)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] high_pass(
  source : S,
  freq : Int,
) -> BltFilter {
  @Milky2018/moon_rodio.high_pass(source, freq)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] low_pass_with_q(
  source : S,
  freq : Int,
  q : Double,
) -> BltFilter {
  @Milky2018/moon_rodio.low_pass_with_q(source, freq, q)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] high_pass_with_q(
  source : S,
  freq : Int,
  q : Double,
) -> BltFilter {
  @Milky2018/moon_rodio.high_pass_with_q(source, freq, q)
}
