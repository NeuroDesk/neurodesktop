#!/bin/bash
# Credits to https://github.com/cyverse/ubuntu-desktop-docker

# help (){
# echo "USAGE:
# docker run -it -p 8080:8080 neuromachine:<tag> <option>
# OPTIONS:
# -v, --vnc  add VNC connection to Guacamole
# -r, --rdp  add RDP connection to Guacamole
# -s, --ssh  add SSH connection to Guacamole
# -h, --help      print out this help
# For more information see: https://github.com/NeuroDesk/neuromachine"
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
service ssh start
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
su user -c "USER=user vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1"
echo \
"<connection name=\"Desktop (VNC)\">
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
service xrdp start
echo \
"<connection name=\"Desktop (RDP)\">
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

# Update neurodesk
cd /neurodesk
sudo git pull
sudo bash build.sh --lxde --edit \
sudo bash install.sh
cd /home/user

open_guacmole_conf
default
close_guacmole_conf

# mount cvmfs
echo "\
==================================================================
Mounting CVMFS"
sudo mount -t cvmfs neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au

echo "\
==================================================================
Testing which CVMFS server is fastest for me"
sudo cvmfs_talk -i neurodesk.ardc.edu.au host probe
sudo cvmfs_talk -i neurodesk.ardc.edu.au host info

echo "\
==================================================================
Starting tomcat server"
/usr/local/tomcat/bin/startup.sh

echo "\
==================================================================
Starting Guacamole Daemon
------------------------------------------------------------------
  Use this link for direct NeuroDesk Desktop:
  http://localhost:8080/#/?username=user&password=password
  Once connected to the session, your user info is:
      Username: \"user\"
      Password: \"password\"
------------------------------------------------------------------"
su user -c "guacd -L debug -f"

