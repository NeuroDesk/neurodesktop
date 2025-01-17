# This file is sourced once in jupyterlab_startup.sh and once in ~/.bashrc so we get the same environment variables in the jupyter and in the desktop environment
if [[ -z "${NB_USER}" ]]; then
    export NB_USER=${USER}
fi

if [[ -z "${USER}" ]]; then
    export USER=${NB_USER}
fi

if [ -f '/usr/share/module.sh' ]; then
        if [ ! -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
                MODULEPATH=/neurodesktop-storage/containers/modules/*
                export MODULEPATH=`echo $MODULEPATH | sed 's/ /:/g'`              
                export CVMFS_DISABLE=true
        fi

        echo 'Neuroimaging tools are accessible via the Neurodesktop Applications menu and running them through the menu will provide help and setup instructions. If you are familiar with the tools and you want to combine multiple tools in one script, you can run "ml av" to see which tools are available and then use "ml <tool>/<version>" to load them. '
        if [ -v "$CVMFS_DISABLE" ]; then
                if [ ! -d $MODULEPATH ]; then
                        echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Neurodesktop Application menu.'
                fi
        fi
fi

if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
        MODULEPATH=/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
        export MODULEPATH=`echo $MODULEPATH | sed 's/ /:/g'`
fi

# This also needs to be set in the Dockerfile, so it is available in a jupyter notebook
export APPTAINER_BINDPATH=/data,/mnt,/neurodesktop-storage,/tmp,/cvmfs
# This also needs to be set in the Dockerfile, so it is available in a jupyter notebook

export APPTAINERENV_SUBJECTS_DIR=/home/${NB_USER}/freesurfer-subjects-dir
export MPLCONFIGDIR=/home/${NB_USER}/.config/matplotlib-mpldir

export PATH=$PATH:/home/${NB_USER}/.local/bin:/opt/conda/bin:/opt/conda/condabin

# workaround for docker on MacOS 
export neurodesk_singularity_opts=" -w "

# this adds --nv to the singularity calls -> but only if a GPU is present
if [ "$(lspci | grep -i nvidia)" ]
then
        export neurodesk_singularity_opts="${neurodesk_singularity_opts} --nv "
fi

export PS1='\u@neurodesktop-$NEURODESKTOP_VERSION:\w$ '

alias ll='ls -la'