#things in .bashrc get executed for every subshell
if [ -f '/usr/share/module.sh' ]; then source /usr/share/module.sh; fi

alias ll='ls -la'

if [ -f '/usr/share/module.sh' ]; then
        if [ -d /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules ]; then
                #WARNING: HARDCODED HERE AND IN DOCKER RECIPE AND IN GOOGLE COLAB example
                export MODULEPATH="/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/molecular_biology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/workflows:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/visualization:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/structural_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/statistics:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spine:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spectroscopy:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/shape_analysis:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/rodent_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quantitative_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quality_control:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/programming:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/phase_processing:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/machine_learning:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_registration:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_reconstruction:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/hippocampus:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/functional_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/electrophysiology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/diffusion_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/data_organisation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/body"
                # module use /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/*
        else
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

# this mounts the homedirecotry to the matlab license directories so that the activation via the GUI works
export neurodesk_singularity_opts="${neurodesk_singularity_opts} --bind /neurodesktop-storage,/home/${USER}:/home/matlab/.matlab/R2022a_licenses,/home/${USER}:/opt/matlab/R2022a/licenses "


# this adds --nv to the singularity calls -> but only if a GPU is present
if [ "`lspci | grep -i nvidia`" ]
then
        export neurodesk_singularity_opts="${neurodesk_singularity_opts} --nv "
fi

PS1='\u@neurodesktop:\w$ '

export SINGULARITYENV_SUBJECTS_DIR=~/freesurfer-subjects-dir
export SINGULARITY_BINDPATH=/data,/cvmfs
export MPLCONFIGDIR=/home/${USER}/.config/matplotlib-mpldir
