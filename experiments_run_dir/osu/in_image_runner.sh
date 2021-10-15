#!/bin/sh

set -e
set -x

echo "osu_bw H H"
entrypoint.sh get_local_rank osu_bw H H
echo "osu_bw D D"
entrypoint.sh get_local_rank osu_bw D D
echo "osu_bw H D"
entrypoint.sh get_local_rank osu_bw H D