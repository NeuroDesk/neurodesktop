#things in .bashrc get executed for every subshell
if [ -f '/usr/share/module.sh' ]; then source /usr/share/module.sh; fi

alias ll='ls -la'

if [ -z "$CVMFS_DISABLE" ] 
then
        export MODULEPATH="/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules"
        module use $MODULEPATH
else
        export MODULEPATH="/neurodesktop/containers/modules"              
        module use $MODULEPATH
fi


if [ -f '/usr/share/module.sh' ]; then
        if [ -d $MODULEPATH ]; then
                echo 'These tools are currently installed - use "ml load <tool>" to use them in this shell:'
        module avail
        else
                echo 'Neurodesk tools not yet downloaded. Choose tools to install from the Application menu.'
        fi
fi

export PATH="/usr/local/singularity/bin:${PATH}"
