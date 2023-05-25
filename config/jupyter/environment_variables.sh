if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
        export MODULEPATH=/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
fi

export SINGULARITY_BINDPATH=/data,/neurodesktop-storage,/tmp,/cvmfs,/home/${NB_USER}:/home/matlab/.matlab/R2022a_licenses,/home/${NB_USER}:/opt/matlab/R2022a/licenses

export SINGULARITYENV_SUBJECTS_DIR=~/freesurfer-subjects-dir
export MPLCONFIGDIR=/home/${NB_USER}/.config/matplotlib-mpldir