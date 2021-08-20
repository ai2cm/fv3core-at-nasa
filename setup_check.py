import gt4py
import gt4py.gtscript as gtscript
from gt4py.gtscript import Field, computation, interval, PARALLEL
import numpy as np

try:
    import cupy as cp
except ImportError:
    cp = None

import os

dtype = np.float64

np_a = gt4py.storage.ones(
    shape=(10, 10, 10), default_origin=(1, 1, 1), dtype=dtype, backend="numpy"
)
x86_a = gt4py.storage.ones(
    shape=(10, 10, 10), default_origin=(1, 1, 1), dtype=dtype, backend="gtx86"
)
if cp is not None:
    cu_a = gt4py.storage.ones(
        shape=(10, 10, 10), default_origin=(1, 1, 1), dtype=dtype, backend="gtcuda"
    )


def lap(in_field: Field[np.float64], out_field: Field[np.float64]):  # noqa
    with computation(PARALLEL), interval(1, -1):
        out_field = (  # noqa
            in_field[-1, 0, 0]
            + in_field[1, 0, 0]
            - 2.0 * in_field[0, 0, 0]
            + in_field[0, -1, 0]
            + in_field[0, 1, 0]
            - 2.0 * in_field[0, 0, 0]
            + in_field[0, 0, -1]
            + in_field[0, 0, 1]
            - 2.0 * in_field[0, 0, 0]
        )


lap_numpy = gtscript.stencil(backend="numpy", definition=lap)  # noqa
lap_gtx86 = gtscript.stencil(backend="gtx86", definition=lap)  # noqa
if cp is not None:
    lap_gtcuda = gtscript.stencil(backend="gtcuda", definition=lap)  # noqa
