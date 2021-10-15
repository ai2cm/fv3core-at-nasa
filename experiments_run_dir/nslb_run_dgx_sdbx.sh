#!/bin/sh

set -e
set -x

EXPERIMENT="$1"
TIMESTEPS=$2
BACKEND=$3

#export UCX_TLS=mm,rc_x,cuda_copy,gdr_copy,cuda_ipc
#export UCX_MEMTYPE_CACHE=n

#export LOCAL_RANK=$SLURM_LOCALID
export MV2_USE_CUDA=1
export CUDA_DEVICE_MAX_CONNECTIONS=1

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl="^smcuda,vader,tcp,openib,uct"

export UCX_TLS=rc_x,mm,cuda_ipc,cuda_copy,gdr_copy,self
export UCX_RNDV_THRESH=8192
export UCX_RNDV_SCHEME=put_zcopy

export OMP_NUM_THREADS=4

singularity exec --nv --bind ./data:/mnt/data \
                      --bind ./:/mnt/work/ \
                      --bind ./tmp:/mnt/tmp/ \
                      --bind ./:/mnt/gtcache \
                      ./fv3core-hpc-sanbox /mnt/work/$EXPERIMENT $TIMESTEPS $BACKEND
