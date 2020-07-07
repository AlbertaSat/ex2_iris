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

from util import *


if __name__ == '__main__':
    np.random.seed(0)

    READOUT_TIME = 10
    LVDS_WIDTH = 16
    BITS = 10

    data_idle = np.random.randint(0, 2**BITS, LVDS_WIDTH)
    print(f'constant data_idle : lvds_data_t := {logic_vector2d_to_vhdl(data_idle, BITS)};')

    data_readout = np.random.randint(0, 2**BITS, (READOUT_TIME, LVDS_WIDTH))
    print(f'constant data_transmit : lvds_data_vector_t := {logic_vector3d_to_vhdl(data_readout, BITS)};')
