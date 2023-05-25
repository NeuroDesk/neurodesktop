#things in .bashrc get executed for every subshell
if [ -f '/usr/share/module.sh' ]; then source /usr/share/module.sh; fi

alias ll='ls -la'

if [ -f '/usr/share/module.sh' ]; then
        if [ ! -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
                export MODULEPATH="/neurodesktop-storage/containers/modules"              
                module use $MODULEPATH
                export CVMFS_DISABLE=true
        fi

        echo 'Neuroimaging tools are accessible via the Applications menu and running them through the menu will provide help and setup instructions. If you are familiar with the tools and you want to combine multiple tools in one script, you can run "ml av" to see which tools are available and then use "ml <tool>/<version>" to load them. '
        if [ -v "$CVMFS_DISABLE" ]; then
                if [ ! -d $MODULEPATH ]; then
                        echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Application menu.'
                fi
        fi
fi

# this adds --nv to the singularity calls -> but only if a GPU is present
if [ "`lspci | grep -i nvidia`" ]
then
        export neurodesk_singularity_opts="${neurodesk_singularity_opts} --nv "
fi

PS1='\u@neurodesktop:\w$ '

export SINGULARITYENV_SUBJECTS_DIR=~/freesurfer-subjects-dir
export MPLCONFIGDIR=/home/${USER}/.config/matplotlib-mpldir
