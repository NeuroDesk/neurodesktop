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
