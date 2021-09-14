#!/bin/sh

module load singularity

export MV2_USE_CUDA=1
export CUDA_DEVICE_MAX_CONNECTIONS=1

# this is the list of GPUs we have
GPUS=(0 1 2 3)

# This is the list of NICs we should use for each GPU
# e.g., associate GPU0,1 with MLX0, GPU2,3 with MLX1, GPU4,5 with MLX2 and GPU6,7 with MLX3
NICS=(mlx5_0 mlx5_1 mlx5_2 mlx5_3)

# This is the list of CPU cores we should use for each GPU
# e.g., 2x20 core CPUs split into 4 threads per process with correct NUMA assignment
CPUS=(1-4 5-8 10-13 15-18)

# Number of physical CPU cores per GPU
export OMP_NUM_THREADS=4

# this is the order we want the GPUs to be assigned in (e.g. for NVLink connectivity)
REORDER=(0 1 2 3)

# now given the REORDER array, we set CUDA_VISIBLE_DEVICES, NIC_REORDER and CPU_REORDER to for this m$
#export CUDA_VISIBLE_DEVICES="${GPUS[${REORDER[0]}]},${GPUS[${REORDER[1]}]},${GPUS[${REORDER[2]}]},${GPUS[${REORDER[3]}]},${GPUS[${REORDER[4]}]},${GPUS[${REORDER[5]}]},${GPUS[${REORDER[6]}]},${GPUS[${REORDER[7]}]}"
export CUDA_VISIBLE_DEVICES=0,1,2,3

lrank=$MV2_COMM_WORLD_LOCAL_RANK
export MV2_IBA_HCA=${NIC_REORDER[lrank]}

echo "Running ${EXE} ${ARGS}"

singularity exec \
    --nv \
    --bind ./osu-micro-benchmarks-5.8:/mnt/osu \
    ./prism_fv3core_sandbox $EXE $ARGS
