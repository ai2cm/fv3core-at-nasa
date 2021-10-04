#!/bin/sh
#SBATCH -J fv3_dynamics
#SBATCH --ntasks=6
#SBATCH -G 6
#SBATCH -o run.out

echo ">>>>>>>>>>>>>>>>>> FV3 DYNAMICS <<<<<<<<<<<<<<<<<<"

srun --mpi=pmi2 ../run_dgx_4gpus.sh