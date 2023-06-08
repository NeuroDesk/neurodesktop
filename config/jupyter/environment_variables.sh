# This file is sourced once in before-notebook.sh and once in ~/.bashrc so we get the same environment variables in the jupyter and in the desktop environment
if [[ -z "$NB_USER" ]]; then
    NB_USER=$USER
fi

if [ -f '/usr/share/module.sh' ]; then
        if [ ! -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
                MODULEPATH=/neurodesktop-storage/containers/modules/*
                export MODULEPATH=`echo $MODULEPATH | sed 's/ /:/g'`              
                export CVMFS_DISABLE=true
        fi

        echo 'Neuroimaging tools are accessible via the Applications menu and running them through the menu will provide help and setup instructions. If you are familiar with the tools and you want to combine multiple tools in one script, you can run "ml av" to see which tools are available and then use "ml <tool>/<version>" to load them. '
        if [ -v "$CVMFS_DISABLE" ]; then
                if [ ! -d $MODULEPATH ]; then
                        echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Application menu.'
                fi
        fi
fi

if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
        MODULEPATH=/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
        export MODULEPATH=`echo $MODULEPATH | sed 's/ /:/g'`
fi

export SINGULARITY_BINDPATH=/data,/neurodesktop-storage,/tmp,/cvmfs,/home/${NB_USER}:/home/matlab/.matlab/R2022a_licenses,/home/${NB_USER}:/opt/matlab/R2022a/licenses

export SINGULARITYENV_SUBJECTS_DIR=/home/${NB_USER}/freesurfer-subjects-dir
export MPLCONFIGDIR=/home/${NB_USER}/.config/matplotlib-mpldir

export PATH=$PATH:/home/${NB_USER}/.local/bin

# this adds --nv to the singularity calls -> but only if a GPU is present
if [ "`lspci | grep -i nvidia`" ]
then
        export neurodesk_singularity_opts="${neurodesk_singularity_opts} --nv "
fi

export PS1='\u@neurodesktop-$NEURODESKTOP_VERSION:\w$ '

alias ll='ls -la'
