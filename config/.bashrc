#things in .bashrc get executed for every subshell
if [ -f '/usr/share/module.sh' ]; then source /usr/share/module.sh; fi

alias ll='ls -la'
alias install_miniconda='curl -o /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; bash /tmp/miniconda.sh -b; miniconda3/bin/conda init'


if [ -f '/usr/share/module.sh' ]; then
        if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
                # export MODULEPATH="/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules"
                module use /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
        else
                export MODULEPATH="/neurodesktop-storage/containers/modules"              
                module use $MODULEPATH
                export CVMFS_DISABLE=true
        fi
fi


if [ -f '/usr/share/module.sh' ]; then
        echo 'Run "ml av" to see which tools are available - use "ml <tool>" to use them in this shell.'
        if [ -v "$CVMFS_DISABLE" ]; then
                if [ ! -d $MODULEPATH ]; then
                        echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Application menu.'
                fi
        fi
fi

# this line add --nv to the singularity calls -> but only if a GPU is present and setup with nvidia-smi (otherwise there are errors)
if [ `which nvidia-smi` ]
then
        export neurodesk_singularity_opts="--nv"
fi

#File needs an empty line at the end because we insert things during build later:
