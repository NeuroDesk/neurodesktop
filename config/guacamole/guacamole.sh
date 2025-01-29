#!/bin/bash

# -XX:UseSVE=0 only exists on aarch64 so only add it if it exists. Check using `uname -m`
if [ "$(uname -m)" == "aarch64" ]; then
    export JAVA_TOOL_OPTIONS="-XX:UseSVE=0"
fi

# Tomcat
sudo --preserve-env=JAVA_TOOL_OPTIONS /usr/local/tomcat/bin/startup.sh


# RDP
sudo service xrdp start

# SSH/SFTP
/usr/sbin/sshd -f /home/${NB_USER}/.ssh/sshd_config

# VNC
vncserver -kill :1
vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
xset -display :1 s off

# Guacamole
# sudo service guacd start
guacd -b 127.0.0.1
echo "    Running guacamole"