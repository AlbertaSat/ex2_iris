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
from typing import Tuple


class Window:
    def __init__(self, lo: int, hi: int):
        self.lo, self.hi = lo, hi

    @property
    def size(self):
        return self.hi - self.lo + 1


WINDOWS = [Window(0, 0), Window(1, 1), Window(2, 2)]
# WINDOWS = [Window(0, 1), Window(2, 3), Window(4, 5)]
# WINDOWS = [Window(10, 15), Window(24, 35), Window(36, 37)]
ROW_WIDTH = 2048
BITS = 10
IMAGE_LENGTH = 2
N_FRAMES = IMAGE_LENGTH + WINDOWS[-1].hi
ROWS_PER_FRAME = sum(w.size for w in WINDOWS)

OUT_DIR = Path('../../out/vnir_subsystem/')


def get_row_window(row: int) -> Tuple[int, Window]:
    sizes = 0
    for i, w in enumerate(WINDOWS):
        row_relative = row - sizes
        if row_relative in range(w.size):
            return i, w
        sizes += w.size
    raise ValueError('Invalid row index')


def get_real_offset(row: int) -> int:
    sizes = 0
    for w in WINDOWS:
        row_relative = row - sizes
        if row_relative in range(w.size):
            return row_relative + w.lo
        sizes += w.size
    raise ValueError('Invalid row index')


def calc_averages(frames: np.ndarray) -> np.ndarray:
    sums = np.zeros((IMAGE_LENGTH, len(WINDOWS), ROW_WIDTH))
    for i_frame, frame in enumerate(frames):
        for i_row, row in enumerate(frame):
            i_window, _ = get_row_window(i_row)
            x_row = i_frame - get_real_offset(i_row)
            # print(i_window, x_row)
            if 0 <= x_row < IMAGE_LENGTH:
                print('*', i_window, x_row)
                sums[x_row][i_window] += row
            else:
                print(i_window, x_row)

    # averages = np.zeros_like(sums, dtype=int)
    # for i, w in enumerate(WINDOWS):
    #     averages[:, i, :] = sums[:, i, :] // w.size
    #
    # return averages

    return sums.astype(int)


if __name__ == '__main__':
    np.random.seed(0)

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    frames = np.random.randint(0, 2**BITS, (N_FRAMES, ROWS_PER_FRAME, ROW_WIDTH))
    rows_file = open(OUT_DIR / 'rows.out', 'w')
    for frame in frames:
        for row in frame:
            rows_file.write(' '.join(str(p) for p in row) + '\n')

    averages = calc_averages(frames)

    nir_file = open(OUT_DIR / 'red.out', 'w')
    for row in averages[:, 0, :]:
        nir_file.write(' '.join(str(p) for p in row) + '\n')

    nir_file = open(OUT_DIR / 'nir.out', 'w')
    for row in averages[:, 1, :]:
        nir_file.write(' '.join(str(p) for p in row) + '\n')

    nir_file = open(OUT_DIR / 'blue.out', 'w')
    for row in averages[:, 2, :]:
        nir_file.write(' '.join(str(p) for p in row) + '\n')

    windows_file = open(OUT_DIR / 'config.out', 'w')
    for w in WINDOWS:
        windows_file.write(f'{w.lo} {w.hi}\n')

    n_frames_file = open(OUT_DIR / 'image_length.out', 'w')
    n_frames_file.write(f'{IMAGE_LENGTH}\n')
