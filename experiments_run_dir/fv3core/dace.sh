#!/bin/sh

set -e
set -x

export CUDA_VISIBLE_DEVICES=$SLURM_LOCALID

export DACE_compiler_cuda_max_concurrent_streams=-1
export PYTHONUNBUFFERED=1
export FV3_DACEMODE=True
export FV3_STENCIL_REBUILD_FLAG=False

export CFLAGS=-march=native
export CPPFLAGS=-march=native
export CXXFLAGS=-march=native

export CUDA_AUTO_BOOST=0
export GCLOCK=1328
export OMP_NUM_THREADS=24
export MPICH_RDMA_ENABLED_CUDA=1

echo "DaCe acoustics"
entrypoint.sh python /fv3core/examples/standalone/runfile/acoustics.py \
        /mnt/data/c128_6ranks_baroclinic_acoustics/ 10 gtc:dace:gpu

echo "DaCe parallel test"
#entrypoint.sh python -m pytest --data_path=/mnt/data/c12_6ranks_standard -v -s -rsx --disable-warnings --backend='gtc:dace:gpu' -m parallel /fv3core/tests/ --which_modules=DynCore --print_failures --threshold_overrides_file=/fv3core/tests/translate/overrides/standard.yaml