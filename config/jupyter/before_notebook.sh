# This script runs in local Jupyterlab only (e.g. Docker, Neurodeskapp)
# This script does NOT run on stock JupterHub/BinderHub instances (e.g. kubernetes)
# For global startup script, see ./config/jupyter/jupterlab_startup.sh

# Overrides Dockerfile changes to NB_USER
/usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER}
usermod --shell /bin/bash ${NB_USER}

if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
    # the cvmfs directory is not yet mounted
    if [ -z "$CVMFS_DISABLE" ]; then
        # CVMFS is not disabled

        # try to list the directory in case it's autofs mounted outside
        ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready" || echo "CVMFS directory not there. Trying internal fuse mount next."

        if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
            # it is not available outside, so try mounting with fuse inside container

            echo "\
            ==================================================================
            Mounting CVMFS"
            if ( service autofs status > /dev/null ); then
                 echo "autofs is running - not attempting to mount manually:"
                 ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after autofs mount" || echo "AutoFS not working!"
            else
                echo "autofs is NOT running - attempting to mount manually:"
                mkdir -p /cvmfs/neurodesk.ardc.edu.au
                mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

                ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after manual mount" || echo "Manual CVMFS mount not successful"

                echo "\
                ==================================================================
                Testing which CVMFS server is fastest"
                cvmfs_talk -i neurodesk.ardc.edu.au host probe
                cvmfs_talk -i neurodesk.ardc.edu.au host info
            fi
        fi
    fi
fi