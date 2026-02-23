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
pub type PeriodicAccess = @Milky2018/moon_rodio.PeriodicAccess

///|
pub type DynSource = @Milky2018/moon_rodio.DynSource

///|
pub fn[S : @Milky2018/moon_rodio.Source] periodic_access(
  source : S,
  every_samples : Int,
  callback : () -> Unit,
) -> PeriodicAccess {
  @Milky2018/moon_rodio.periodic_access(source, every_samples, callback)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] periodic_access_with_source(
  source : S,
  every_samples : Int,
  callback : (DynSource) -> Unit,
) -> PeriodicAccess {
  @Milky2018/moon_rodio.periodic_access_with_source(
    source, every_samples, callback,
  )
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] periodic(
  source : S,
  period : @moon_cpal.Duration,
  callback : () -> Unit,
) -> PeriodicAccess {
  @Milky2018/moon_rodio.periodic(source, period, callback)
}

///|
pub fn[S : @Milky2018/moon_rodio.Source] periodic_with_source(
  source : S,
  period : @moon_cpal.Duration,
  callback : (DynSource) -> Unit,
) -> PeriodicAccess {
  @Milky2018/moon_rodio.periodic_with_source(source, period, callback)
}
