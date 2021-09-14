#!/bin/sh
#SBATCH -J osu_bench
#SBATCH -t 180:00
#SBATCH --ntasks=2
#SBATCH --nodes=2
#SBATCH -o osu_bench.out

echo ">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<"

export MV2_USE_CUDA=1

export MV2_USE_GPUDIRECT=1

export EXE="/mnt/osu/get_local_rank /mnt/osu/mpi/pt2pt/osu_bw"
export ARGS="H H"

srun --mpi=pmi2 ./run.sh
