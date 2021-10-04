#!/bin/sh

set -e
set -x

entrypoint.sh python /fv3core/examples/standalone/runfile/dynamics.py \
       /mnt/data/c128_6ranks_baroclinic/ 3 gtc:gt:gpu prism_first_run
