#!/bin/sh

set -e
set -x

export DACE_compiler_cuda_max_concurrent_streams=-1
export PYTHONUNBUFFERED=1
export FV3_STENCIL_REBUILD_FLAG=False
export DACE_compiler_cpu_openmp_sections=0

export CFLAGS=-march=native
export CPPFLAGS=-march=native
export CXXFLAGS=-march=native

export CUDA_AUTO_BOOST=0
export OMP_NUM_THREADS=24
export MPICH_RDMA_ENABLED_CUDA=1


# Required for the Halo Exchange callback system
export DACE_execution_general_check_args=0
export DACE_frontend_dont_fuse_callbacks=1

# Faster codegen
export DACE_compiler_unique_functions=none 

# Opt
export DACE_frontend_unroll_threshold=0
#export DACE_frontend_unroll_threshold=-1

# Debug verbosity
export DACE_frontend_verbose_errors=0

export DACE_compiler_allow_view_arguments=1

NAMELIST="${NAMELIST:-/c192_6ranks_baroclinic/}"
TIMESTEPS="${TIMESTEPS:-10}"

# Build the caches
export FV3_DACEMODE="${FV3_DACEMODE:-Build}"
python /fv3core/examples/standalone/runfile/dynamics.py \
    $NAMELIST 0 gtc:dace:gpu build_run

# Run performance simulation on warm caches
export FV3_DACEMODE="${FV3_DACEMODE:-Run}"
python /fv3core/examples/standalone/runfile/dynamics.py \
    $NAMELIST $TIMESTEPS gtc:dace:gpu performance_run
