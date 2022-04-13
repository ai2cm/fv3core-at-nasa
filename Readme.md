WIP: DO NOT USE IF YOU DON'T ALREADY KNOW WHY YOU ARE HERE
==========================================================

FV3Core Images for HPCs
=======================

Piz Daint (SC22)
---------

Image is in build folder `SC22_Artefact.Dockerfile`.

NSLB
----

Form: launcher path_to_experiment.sh options_for_experiment

`nslb_run_dgx.sh fv3core/dynamics.sh 3 gtc:gt:gpu`

PRISM
-----

Image is in build folder `PRISM.Dockerfile`.
Pull actions are in `build`.

Experiments are in `experiment_run_dir`
 - fv3core run
 - osu benchmark
