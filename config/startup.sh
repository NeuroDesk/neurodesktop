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

args=""

# Arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
   do
   key="$1"

   case $key in
      --vnc)
      vnc=true
      shift # past argument
      ;;
      --rdp)
      rdp=true
      shift # past argument
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
   esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

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

default=true
open_guacmole_conf
ssh
if [ "$rdp" = true ]; then
    rdp
    default=""
fi
if [ "$vnc" = true ]; then
    vnc
    default=""
fi
if [ "$default" = true ]; then
    rdp
fi
close_guacmole_conf

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
