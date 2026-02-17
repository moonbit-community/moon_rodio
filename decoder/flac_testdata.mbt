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
pub fn flac_pop_bytes() -> Bytes {
  let xs = [
    102, 76, 97, 67, 128, 0, 0, 34, 16, 0, 16, 0, 0, 0, 63, 0, 0, 63, 10, 196, 64,
    240, 0, 0, 0, 100, 104, 70, 66, 136, 250, 94, 25, 131, 85, 22, 151, 45, 207,
    71, 34, 60, 255, 248, 105, 8, 0, 99, 51, 24, 0, 0, 8, 4, 16, 1, 23, 238, 0, 163,
    46, 78, 138, 101, 218, 106, 149, 46, 98, 137, 233, 47, 50, 164, 215, 39, 73,
    204, 86, 222, 55, 237, 102, 115, 20, 142, 203, 174, 242, 89, 20, 135, 49, 83,
    163, 178, 205, 228, 138, 71, 219, 205, 96, 181, 117,
  ]
  Bytes::makei(xs.length(), fn(i) { xs[i].to_byte() })
}
