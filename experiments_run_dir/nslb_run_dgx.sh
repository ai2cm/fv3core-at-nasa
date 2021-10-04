#!/bin/sh

export UCX_TLS=mm,rc_x,cuda_copy,gdr_copy,cuda_ipc
export LOCAL_RANK=$MV2_COMM_WORLD_LOCAL_RANK
export MV2_USE_CUDA=1
export CUDA_DEVICE_MAX_CONNECTIONS=1

export MV2_IBA_HCA=$MV2_COMM_WORLD_LOCAL_RANK

export OMP_NUM_THREADS=4

export UCX_POSIX_USE_PROC_LINK=n
export UCX_MEMTYPE_CACHE=n

singularity exec --nv --bind ./experiments:/mnt/work/ \
                      --bind ./tmp:/mnt/tmp/ \
                      --bind ./data:/mnt/data \
                      ./fv3core-hpc.sif /mnt/work/in_image_runner.sh
