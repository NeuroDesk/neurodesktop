#!/bin/bash

# This script runs globally (e.g. Docker, Neurodeskapp, JupyterHub, BinderHub)
# For local Jupyterlab only, see ./config/jupyter/before_notebook.sh

# Copy homedirectory files if they don't exist yet
# Check for missing conda-readme.md in persisting homedir
if [ ! -f "/home/${NB_USER}/conda-readme.md" ] 
then
    mkdir -p /home/${NB_USER}
    chown ${NB_UID}:${NB_GID} -R /home/${NB_USER}
    chmod g+rwxs /home/${NB_USER}
    setfacl -dRm u::rwX,g::rwX,o::0 /home/${NB_USER}

    sudo cp -rpn /tmp/${NB_USER}/ /home/
    sudo chown ${NB_UID}:${NB_GID} -R /home/${NB_USER}
fi

# Set .ssh directory permissions
chmod -R 700 /home/${NB_USER}/.ssh
chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.ssh
setfacl -dRm u::rwx,g::0,o::0 /home/${NB_USER}/.ssh

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
if ! grep "guacamole@sftp-server" /home/${NB_USER}/.ssh/authorized_keys
then
    cat /home/${NB_USER}/.ssh/guacamole_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
fi
if ! grep "${NB_USER}@${HOSTNAME}" /home/${NB_USER}/.ssh/authorized_keys
then
    cat /home/${NB_USER}/.ssh/id_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
fi


# Insert guacamole private key into user-mapping for ssh/sftp support

if ! grep 'BEGIN RSA PRIVATE KEY' /etc/guacamole/user-mapping.xml
then
    sudo sed -i "/private-key/ r /home/${NB_USER}/.ssh/guacamole_rsa" /etc/guacamole/user-mapping.xml
fi

# Create a symlink in home if /data is mounted
if mountpoint -q /data; then
    if [ ! -L "/home/${NB_USER}/data" ]; then
        ln -s /data /home/${NB_USER}/
    fi
fi

# Create a symlink to /neurodesktop-storage in home if it is mounted
if mountpoint -q /neurodesktop-storage/; then
    if [ ! -L "/home/${NB_USER}/neurodesktop-storage" ]; then
        ln -s /neurodesktop-storage/ /home/${NB_USER}/
    fi
else
    if [ ! -L "/neurodesktop-storage" ]; then
        if [ ! -d "/home/${NB_USER}/neurodesktop-storage/" ]; then
            mkdir -p /home/${NB_USER}/neurodesktop-storage/containers
        fi
        if [ ! -L "/neurodesktop-storage" ]; then
            sudo ln -s /home/${NB_USER}/neurodesktop-storage/ /neurodesktop-storage
        fi
    fi
fi

# Create a symlink to the neurodesktop-storage directory if it doesn't exist yet:
if [ ! -L "/neurocommand/local/containers" ]; then
  ln -s "/home/${NB_USER}/neurodesktop-storage/containers" "/neurocommand/local/containers"
fi

# Create a cpufino file with a valid CPU Mhz entry for ARM cpus
if ! grep -iq 'cpu.*hz' /proc/cpuinfo; then
    cpuinfo_file=/home/${NB_USER}/.local/cpuinfo_with_ARM_MHz_fix
    cp /proc/cpuinfo $cpuinfo_file
    chmod u+rw $cpuinfo_file
    sed -i '/^$/c\cpu MHz         : 2245.778\n' $cpuinfo_file
    sudo mount --bind $cpuinfo_file /proc/cpuinfo
fi

# Start and stop SSH server to initialize host
sudo service ssh restart
sudo service ssh stop


source /opt/neurodesktop/environment_variables.sh


conda init bash
mamba init bash


# update example directory
git config --global --add safe.directory /home/${NB_USER}/example-notebooks
if [ -d "/home/${NB_USER}/example-notebooks" ]
then
    cd /home/${NB_USER}/example-notebooks
    git pull
else
    git clone https://github.com/NeuroDesk/example-notebooks /home/${NB_USER}/example-notebooks
fi