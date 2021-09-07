#/!bin/sh

module load singularity

# Will execute from ADAPT, NOBACKUP
cd $NOBACKUP

# Check pull has been ran
if [[ ! -e nobackup_tmp ]]; then
    echo "No backup_tmp folder, did you run prism_singularity_pull?"
    exit -1
fi
if [[ ! -f prism_fv3core_sandbox ]]; then
    echo "No prism_fv3core_sandbox singularity image, did you run prism_singularity_pull?"
    exit -1
fi

# Shell in the docker
srun singularity shell --bind ./data:/mnt/data --bind ./nobackup_tmp:/mnt/tmp --nv ./prism_fv3core_sandbox
