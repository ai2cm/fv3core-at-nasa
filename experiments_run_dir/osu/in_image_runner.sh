#!/bin/sh

set -e
set -x

entrypoint.sh

echo "osu_bw D D"
/osu/get_local_rank /osu/mpi/pt2pt/osu_bw D D
echo "osu_bw H H"
/osu/get_local_rank /osu/mpi/pt2pt/osu_bw H H
echo "osu_bw H D"
/osu/get_local_rank /osu/mpi/pt2pt/osu_bw H D