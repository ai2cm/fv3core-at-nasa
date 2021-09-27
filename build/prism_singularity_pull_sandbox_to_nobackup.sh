#/!bin/sh

module load singularity

echo "Building sandbox on /lscratch"
mkdir -p /lscratch/$USER/singularity_cache
export SINGULARITY_TMPDIR=/lscratch/$USER/singularity_cache
export SINGULARITY_CACHEDIR=/lscratch/$USER/singularity_cache
singularity build -F --sandbox /lscratch/$USER/prism_fv3core_sandbox docker://gitlab.nccs.nasa.gov:5050/fgdeconi/fv3core-at-nasa/fv3core_ubuntu18

echo "Copying the sandbox to the working dir"
mv /lscratch/$USER/prism_fv3core_sandbox .