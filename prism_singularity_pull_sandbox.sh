#/!bin/sh

module load singularity

# Make a TMP folder required as a mnt to allow
# for compilation from with the image
if [[ ! -e nobackup_tmp ]]; then
    mkdir nobackup_tmp
    chmod 777 nobackup_tmp
fi

cd $NOBACKUP
singularity build --sandbox ./prism_fv3core_sandbox docker://gitlab.nccs.nasa.gov:5050/fgdeconi/fv3core-at-nasa/fv3core_ubuntu18
