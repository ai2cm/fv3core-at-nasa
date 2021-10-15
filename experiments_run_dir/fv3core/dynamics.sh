#!/bin/sh

set -e
set -x

TIMESTEPS=$1
BACKEND=$2

entrypoint.sh python /fv3core/examples/standalone/runfile/dynamics.py \
       /mnt/data/c128_6ranks_baroclinic/ $TIMESTEPS $BACKEND fv3core_dyn
