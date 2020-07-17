# ---------------------------------------------------------------
# Copyright 2020 University of Alberta
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------


import numpy as np
from pathlib import Path


if __name__ == '__main__':
    np.random.seed(0)

    READOUT_TIME = 10
    LVDS_WIDTH = 16
    BITS = 10
    OUT_DIR = Path('../../out/lvds_decoder/')
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    data_idle = np.random.randint(0, 2**BITS, LVDS_WIDTH)
    data_idle_file = open(OUT_DIR / 'data_idle.out', 'w')
    data_idle_file.write(' '.join(bin(word)[2:].zfill(BITS)
                                  for word in data_idle) + '\n')

    data_transmit = np.random.randint(0, 2**BITS, (READOUT_TIME, LVDS_WIDTH))
    data_transmit_file = open(OUT_DIR / 'data_transmit.out', 'w')
    for data in data_transmit:
        data_transmit_file.write(' '.join(bin(word)[2:].zfill(BITS)
                                          for word in data) + '\n')
