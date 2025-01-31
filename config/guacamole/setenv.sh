#!/usr/bin/env bash
export JAVA_OPTS="-Xms512M -Xmx1024M"
export CATALINA_OPTS="-Xms512M -Xmx1024M"
# -XX:UseSVE=0 only exists on aarch64 so only add it if it exists. Check using `uname -m`
if [ "$(uname -m)" == "aarch64" ]; then
  export JAVA_OPTS="$JAVA_OPTS -XX:UseSVE=0"
  export CATALINA_OPTS="$CATALINA_OPTS -XX:UseSVE=0"
fi
export GUACAMOLE_HOME="/etc/guacamole"