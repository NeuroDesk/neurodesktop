# This script runs in local Jupyterlab only (e.g. Docker, Neurodeskapp)
# This script does NOT run on stock JupterHub/BinderHub instances (e.g. kubernetes)
# For global startup script, see ./config/jupyter/jupterlab_startup.sh

if [ -z "$GRANT_SUDO" ]; then
export GRANT_SUDO='yes'
fi
if [ -z "$RESTARTABLE" ]; then
export RESTARTABLE='yes'
fi

if [[ "$NB_UID" != "1000" || "$NB_GID" != "1000" ]]; then
    if [ -z "$CHOWN_HOME" ]; then
    export CHOWN_HOME='yes'
    fi
    if [ -z "$CHOWN_HOME_OPTS" ]; then
    export CHOWN_HOME_OPTS='-R'
    fi
fi