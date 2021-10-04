#!/bin/sh
#SBATCH -J osu_bench
#SBATCH -t 180:00
#SBATCH --ntasks=2
#SBATCH --nodes=2
#SBATCH -o osu_bench.out

echo ">>>>>>>>>>>>>>>>>> OSU BW <<<<<<<<<<<<<<<<<<"

srun --mpi=pmi2 ../run_dgx_4gpus.sh
