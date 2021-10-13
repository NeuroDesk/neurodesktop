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

open_guacmole_conf () {
echo \
"<user-mapping>
<authorize username=\"user\" password=\"password\">"  > /etc/guacamole/user-mapping.xml
}

close_guacmole_conf () {
echo \
"</authorize>
</user-mapping>" >> /etc/guacamole/user-mapping.xml
}

ssh () {
echo "\
==================================================================
Starting SSH server"
service ssh restart
echo \
"<connection name=\"Command Line (SSH)\">
<protocol>ssh</protocol>
<param name=\"hostname\">localhost</param>
<param name=\"username\">user</param>
<param name=\"password\">password</param>
<param name=\"port\">22</param>
<param name=\"enable-sftp\">true</param>
<param name=\"sftp-root-directory\">/home/user</param>
</connection>" >> /etc/guacamole/user-mapping.xml
}

vnc () {
echo "\
==================================================================
Starting VNC server"
su user -c "USER=user vncserver -kill :1"
su user -c "USER=user vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1"
echo \
"<connection name=\"Desktop Fixed-Resolution (VNC)\">
<protocol>vnc</protocol>
<param name=\"hostname\">localhost</param>
<param name=\"username\">user</param>
<param name=\"password\">password</param>
<param name=\"port\">5901</param>
<param name=\"enable-sftp\">true</param>
<param name=\"sftp-username\">user</param>
<param name=\"sftp-password\">password</param>
<param name=\"sftp-directory\">/home/user</param>
<param name=\"sftp-root-directory\">/home/user</param>
<param name=\"enable-audio\">true</param>
<param name=\"audio-servername\">127.0.0.1</param>
</connection>" >> /etc/guacamole/user-mapping.xml
}

rdp () {
echo "\
==================================================================
Starting RDP server"
service xrdp restart
echo \
"<connection name=\"Desktop Auto-Resolution (RDP)\">
<protocol>rdp</protocol>
<param name=\"hostname\">localhost</param>
<param name=\"username\">user</param>
<param name=\"password\">password</param>
<param name=\"port\">3389</param>
<param name=\"security\">any</param>
<param name=\"ignore-cert\">true</param>
<param name=\"resize-method\">reconnect</param>
</connection>" >> /etc/guacamole/user-mapping.xml
}

default () {
    ssh
    vnc
    rdp
}

HOST_UID=${HOST_UID:-9001}
HOST_GID=${HOST_GID:-9001}
# echo "Starting with UID:GID $HOST_UID:$HOST_GID"
usermod -u $HOST_UID user
groupmod -g $HOST_GID user
cd /home/user
chgrp +$HOST_GID /home/user

# Create vscode config on persistant storage
mkdir -p /neurodesktop-storage/.config/Code
chown -R user:user /neurodesktop-storage/.config
mkdir -p /neurodesktop-storage/.vscode
chown -R user:user /neurodesktop-storage/.vscode

open_guacmole_conf
default
close_guacmole_conf

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
su user -c "guacd -L debug -f"

