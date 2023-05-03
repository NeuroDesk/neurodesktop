
# # clean up old session files (they prevent the start of the next session):
# echo "starting cleanup before if"
# if [ -f "/home/${NB_USER}/.ssh/id_rsa" ]
# then
#     echo "starting cleanup"
#     rm /home/${NB_USER}/.ssh/id_rsa
#     rm /home/${NB_USER}/.ssh/authorized_keys
#     rm /home/${NB_USER}/.ssh/id_rsa.pub
#     rm /home/${NB_USER}/.ssh/ssh_host_rsa_key
#     rm /home/${NB_USER}/.ssh/ssh_host_rsa_key.pub 
#     rm /home/${NB_USER}/.ssh/sshd.pid
#     rm /home/${NB_USER}/.Xauthority
#     rm -rf /home/${NB_USER}/.dbus/session-bus
#     rm -rf /home/${NB_USER}/.vnc
#     cp -r /tmp/${NB_USER}/.vnc /home/${NB_USER}/
# fi

# # update example directory
# if [ -d "/home/${NB_USER}/example-notebooks" ]
# then
#     cd /home/${NB_USER}/example-notebooks
#     git pull
# else
#     git clone https://github.com/NeuroDesk/example-notebooks /home/${NB_USER}/example-notebooks
# fi

# cvmfs2 -o config=/cvmfs/neurodesk.ardc.edu.au.conf neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au
# ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
# ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/ssh_host_rsa_key -N '' <<< n
# cat /home/${NB_USER}/.ssh/id_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys

# This runs for Notebook mode. Dockerfile changes to NB_USER are overridden in notebook mode
/usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER}
usermod --shell /bin/bash ${NB_USER}

if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/containers/" ]; then
    if [ -z "$CVMFS_DISABLE" ]; then
    echo "\
    ==================================================================
    Mounting CVMFS"
    sudo mkdir -p /cvmfs/neurodesk.ardc.edu.au
    sudo mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

    echo "\
    ==================================================================
    Testing which CVMFS server is fastest"
    sudo cvmfs_talk -i neurodesk.ardc.edu.au host probe
    sudo cvmfs_talk -i neurodesk.ardc.edu.au host info
    fi
fi

