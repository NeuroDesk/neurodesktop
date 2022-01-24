#!/bin/bash
# Credits to https://github.com/cyverse/ubuntu-desktop-docker

# help (){
# echo "USAGE:
# docker run -it -p 8080:8080 neurodesktop:<tag> <option>
# OPTIONS:
# -v, --vnc  add VNC connection to Guacamole
# -r, --rdp  add RDP connection to Guacamole
# -s, --ssh  add SSH connection to Guacamole
# -h, --help      print out this help
# For more information see: https://github.com/NeuroDesk/neurodesktop"
# }

ssh () {
echo "\
==================================================================
Starting SSH server"
service ssh restart
}

vnc () {
ln -s /etc/guacamole/user-mapping-vnc.xml /etc/guacamole/user-mapping.xml 
echo "\
==================================================================
Starting VNC server"
su user -c "USER=user vncserver -kill :1"
su user -c "USER=user vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1"
}

rdp () {
ln -s /etc/guacamole/user-mapping-rdp.xml /etc/guacamole/user-mapping.xml 
echo "\
==================================================================
Starting RDP server"
service xrdp restart
}

default () {
    ssh
    rdp
}

export JAVA_OPTS="-Xms512M -Xmx1024M"
export CATALINA_OPTS="-Xms512M -Xmx1024M"

if [ -n "$HOST_UID" ]; then
    echo "Setting UID to $HOST_UID"
    usermod -u $HOST_UID user
fi
if [ -n "$HOST_GID" ]; then
    echo "Setting GID to $HOST_GID"
    groupmod -g $HOST_GID user
    chgrp +$HOST_GID /home/user
fi
cd /home/user

# Create vscode config on persistant storage
mkdir -p /neurodesktop-storage/.config/Code
chown -R user:user /neurodesktop-storage/.config
mkdir -p /neurodesktop-storage/.vscode
chown -R user:user /neurodesktop-storage/.vscode

DEFAULT_ENABLE="true"
if [ -n "$VNC_ENABLE" ]; then
    vnc
    DEFAULT_ENABLE=""
fi
if [ -n "$RDP_ENABLE" ]; then
    rdp
    DEFAULT_ENABLE=""
fi
if [ -n "$SSH_ENABLE" ]; then
    ssh
    DEFAULT_ENABLE=""
fi
if [ -n "$DEFAULT_ENABLE" ]; then
    default
fi

if [ -z "$CVMFS_DISABLE" ]; then
    echo "\
    ==================================================================
    Mounting CVMFS"
    sudo mkdir /cvmfs/neurodesk.ardc.edu.au
    sudo mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

    echo "\
    ==================================================================
    Testing which CVMFS server is fastest"
    sudo cvmfs_talk -i neurodesk.ardc.edu.au host probe
    sudo cvmfs_talk -i neurodesk.ardc.edu.au host info
fi


echo "\
==================================================================
Starting tomcat server"
/usr/local/tomcat/bin/startup.sh

echo "\
==================================================================
Starting Guacamole Daemon
------------------------------------------------------------------
    Use this link for direct Neurodesktop:
!!! http://localhost:8080/#/?username=user&password=password !!!
    Once connected to the session, your user info is:
    Username: \"user\"
    Password: \"password\"
------------------------------------------------------------------"
# su user -c "guacd -f -L debug && echo"
su user -c "guacd -f && echo"
