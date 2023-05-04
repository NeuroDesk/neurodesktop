# This script does NOT run in singleuser mode (e.g. kubernetes)
# This runs for Notebook mode. Dockerfile changes to NB_USER are overridden in notebook mode

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
