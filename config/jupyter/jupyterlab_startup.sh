#!/bin/bash

# This script runs globally (e.g. Docker, Neurodeskapp, JupyterHub, BinderHub)
# For local Jupyterlab only, see ./config/jupyter/before_notebook.sh

# # Overrides Dockerfile changes to NB_USER
# /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER}
# usermod --shell /bin/bash ${NB_USER}

# If a home directory copy exists at /tmp/${NB_USER}, copy contents into homedir. Replaces k8s_postStart_copy_homedir
if [ -d /tmp/${NB_USER} ]; then
    # Copy homedirectory files if they don't exist yet. 
    if [ ! -f "/home/${NB_USER}/.bashrc" ] 
    then
        cp -r /tmp/${NB_USER}/ /home/ 
    fi

    cp /tmp/${NB_USER}/.jupyter/jupyter_notebook_config.py /home/${NB_USER}/.jupyter/jupyter_notebook_config.py
    cp /tmp/${NB_USER}/.bashrc /home/${NB_USER}/.bashrc
    cp /tmp/README.md /home/${NB_USER}/README.md

    # Generate SSH keys
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/guacamole_rsa -b 4096 -m PEM -N '' <<< n
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/ssh_host_rsa_key -N '' <<< n
    cat /home/${NB_USER}/.ssh/guacamole_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
    cat /home/${NB_USER}/.ssh/id_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys

    # Set .ssh directory permissions
    chmod -R 700 .ssh && chown -R ${NB_USER}:users .ssh
fi

# Generate SSH keys
if [ ! -f "/home/${NB_USER}/.ssh/guacamole_rsa" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/guacamole_rsa -b 4096 -m PEM -N '' -C guacamole@sftp-server <<< n
fi
if [ ! -f "/home/${NB_USER}/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
fi
if [ ! -f "/home/${NB_USER}/.ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/ssh_host_rsa_key -N '' <<< n
fi

cat /home/${NB_USER}/.ssh/guacamole_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
cat /home/${NB_USER}/.ssh/id_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
# Remove duplicates from authorized_keys
sort /home/${NB_USER}/.ssh/authorized_keys | uniq > /home/${NB_USER}/.ssh/authorized_keys

# # Set .ssh directory permissions
# chmod -R 700 .ssh && chown -R ${NB_USER}:users .ssh

# Insert guacamole private key into user-mapping for ssh/sftp support

if ! grep 'BEGIN RSA PRIVATE KEY' /etc/guacamole/user-mapping.xml
then
    sudo sed -i "/private-key/ r /home/${NB_USER}/.ssh/guacamole_rsa" /etc/guacamole/user-mapping.xml
fi

# Start and stop SSH server to initialize host
sudo service ssh restart
sudo service ssh stop

# Create a symlink in home if /data is mounted
if mountpoint -q /data; then
    ln -s /data /home/${NB_USER}/data
fi

# if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
#     # the cvmfs directory is not yet mounted
#     if [ -z "$CVMFS_DISABLE" ]; then
#         # CVMFS is not disabled

#         # try to list the directory in case it's autofs mounted outside
#         ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready" || echo "CVMFS directory not there. Trying internal fuse mount next."

#         if [ ! -d "/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/" ]; then
#             # it is not available outside, so try mounting with fuse inside container

#             echo "\
#             ==================================================================
#             Mounting CVMFS"
#             if ( service autofs status > /dev/null ); then
#                  echo "autofs is running - not attempting to mount manually:"
#                  ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after autofs mount" || echo "AutoFS not working!"
#             else
#                 echo "autofs is NOT running - attempting to mount manually:"
#                 mkdir -p /cvmfs/neurodesk.ardc.edu.au
#                 mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

#                 ls /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/ 2>/dev/null && echo "CVMFS is ready after manual mount" || echo "Manual CVMFS mount not successful"

#                 echo "\
#                 ==================================================================
#                 Testing which CVMFS server is fastest"
#                 cvmfs_talk -i neurodesk.ardc.edu.au host probe
#                 cvmfs_talk -i neurodesk.ardc.edu.au host info
#             fi
#         fi
#     fi
# fi

source /opt/neurodesktop/environment_variables.sh

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
