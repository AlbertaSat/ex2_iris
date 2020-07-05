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


def unsigned_to_vhdl(u, width=12):
    return f'to_unsigned({u}, {width})'


def uarray_to_vhdl(uarray, width=12):
    return '(' + ', '.join(f'{i} => {unsigned_to_vhdl(u, width)}'
                           for i, u in enumerate(uarray)) + ')'


def uarray2d_to_vhdl(uarray2d, width=12, indent=''):
    indent2 = indent + '    '
    return '(\n' + ',\n'.join(f'{indent2}{i} => {uarray_to_vhdl(uarray, width)}'
                          for i, uarray in enumerate(uarray2d)) + f'\n{indent})'


def uarray3d_to_vhdl(uarray3d, width=12, indent=''):
    indent2 = indent + '    '
    return '(\n' + ',\n'.join(f'{indent2}{i} => {uarray2d_to_vhdl(uarray2d, width, indent2)}'
                              for i, uarray2d in enumerate(uarray3d)) + f'\n{indent})'


if __name__ == '__main__':
    np.random.seed(0)

    DIM = (3, 10, 2048)
    BITS = 10

    data = np.random.randint(0, 2**BITS, DIM)
    print(f'constant data : data_t := {uarray3d_to_vhdl(data, BITS)};')

    averages = np.floor(np.mean(data, axis=1)).astype(int)
    print(f'constant averages : averages_t := {uarray2d_to_vhdl(averages, BITS)};')
