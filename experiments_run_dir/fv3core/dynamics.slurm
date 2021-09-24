#!/bin/sh
#SBATCH -J fv3_dynamics
#SBATCH --ntasks=6
#SBATCH --nodes=2
#SBATCH -o run.out

echo ">>>>>>>>>>>>>>>>>> FV3 DYNAMICS <<<<<<<<<<<<<<<<<<"

export MV2_USE_CUDA=1
export MV2_USE_GPUDIRECT=1

export UCX_POSIX_USE_PROC_LINK=n
export UCX_MEMTYPE_CACHE=n
export UCX_TLS=mm,rc_x,cuda_copy,gdr_copy,cuda_ipc

srun --mpi=pmi2 ../run_dgx_4gpus.sh