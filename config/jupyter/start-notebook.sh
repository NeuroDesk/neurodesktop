# This script runs in Notebook mode (e.g. docker run)
# This script does NOT run in singleuser mode (e.g. kubernetes)

if [ -z "$GRANT_SUDO" ]; then
export GRANT_SUDO='yes'
fi
if [ -z "$RESTARTABLE" ]; then
export RESTARTABLE='yes'
fi
if [ -z "$CHOWN_HOME" ]; then
export CHOWN_HOME='yes'
fi
if [ -z "$CHOWN_HOME_OPTS" ]; then
export CHOWN_HOME_OPTS='-R'
fi

# Generate SSH keys
if [ ! -f "/home/${NB_USER}/.ssh/guacamole_rsa" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/guacamole_rsa -b 4096 -m PEM -N '' <<< n
    cat /home/${NB_USER}/.ssh/guacamole_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
fi
if [ ! -f "/home/${NB_USER}/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
    cat /home/${NB_USER}/.ssh/id_rsa.pub >> /home/${NB_USER}/.ssh/authorized_keys
fi
if [ ! -f "/home/${NB_USER}/.ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -f /home/${NB_USER}/.ssh/ssh_host_rsa_key -N '' <<< n
fi
