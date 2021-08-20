FV3Core @ NASA
==============

PRISM Docker
------------

Package `fv3core` and minimum dependencies. Taylored for run on PRISM. To run an interactive shell
* Log on PRISM
* `salloc` to get a box
* `module load singularity`
* `singularity shell --nv docker://gitlab.nccs.nasa.gov:5050/fgdeconi/fv3core-at-nasa/fv3core_ubuntu18`

Tech details
* `TMPDIR` is forwarded to `/local_tmp` for in image compilation success
* `nano` is present for shell