#!/bin/bash

# order: start_notebook.sh -> ### before_notebook.sh ###-> jupyter_notebook_config.py -> jupyterlab_startup.sh

if [ "$EUID" -eq 0 ]; then
    # # Overrides Dockerfile changes to NB_USER
    /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER}
    usermod --shell /bin/bash ${NB_USER}

    # Make sure binfmt_misc is mounted in the place apptainer expects it. This is most likely a bug in apptainer and is a workaround for now on apple silicon when CVMFS is disabled.
    if [ -d "/proc/sys/fs/binfmt_misc" ]; then
        # Check if binfmt_misc is already mounted
        if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
            echo "binfmt_misc directory exists but is not mounted. Mounting now..."
            sudo mount -t binfmt_misc binfmt /proc/sys/fs/binfmt_misc
        else
            echo "binfmt_misc is already mounted."
        fi
    else
        echo "binfmt_misc directory does not exist in /proc/sys/fs."
    fi

    if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
        # the cvmfs directory is not yet mounted

        # check if we have internet connectivity:
        if ping -q -c 1 -W 1 google.com >/dev/null; then
            echo "Internet is up"
        else
            export CVMFS_DISABLE=true
            echo "No internet connection. Disabling CVMFS."
        fi

        # This is to capture legacy use. If CVMFS_DISABLE is not set, we assume it is false, which was the legacy behaviour.
        if [ -z "$CVMFS_DISABLE" ]; then
            export CVMFS_DISABLE="false"
        fi


        if [[ "$CVMFS_DISABLE" == "false" ]]; then
            # CVMFS_DISABLE is false and CVMFS should be enabled.

            # try to list the directory in case it's autofs mounted outside
            ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready" || echo "CVMFS directory not there. Trying internal fuse mount next."

            if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
                # it is not available outside, so try mounting with fuse inside container

                echo "probing if the latency of direct connection or the latency of a CDN is better"
                DIRECT=cvmfs-geoproximity.neurodesk.org
                DIRECT_url="http://${DIRECT}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished" 
                CDN=cvmfs.neurodesk.org
                CDN_url="http://${CDN}/cvmfs/neurodesk.ardc.edu.au/.cvmfspublished"

                echo testing $CDN_url
                echo "Resolving DNS name"
                resolved_dns=$(dig +short $CDN)
                echo "[DEBUG]: Resolved DNS for $CDN: $resolved_dns"
                CDN_url_latency=$(curl -s -w %{time_total}\\n -o /dev/null "$CDN_url")
                echo $CDN_url_latency
                
                echo testing $DIRECT_url
                echo "Resolving DNS name"
                resolved_dns=$(dig +short $DIRECT)
                echo "[DEBUG]: Resolved DNS for $DIRECT: $resolved_dns"
                DIRECT_url_latency=$(curl -s -w %{time_total}\\n -o /dev/null "$DIRECT_url")
                echo $DIRECT_url_latency

                if (( $(echo "$DIRECT_url_latency < $CDN_url_latency" |bc -l) )); then
                    echo "Direct connection is faster"
                    cp /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf.direct /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf
                else
                    echo "CDN is faster"
                    cp /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf.cdn /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf
                fi

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
                    CVMFS servers:"
                    cvmfs_talk -i neurodesk.ardc.edu.au host info
                fi
            fi
        fi
    fi
fi

source /opt/neurodesktop/environment_variables.sh
