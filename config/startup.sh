#!/bin/bash

# clean up old session files (they prevent the start of the next session):
echo "starting cleanup before if"
if [ -f "/home/jovyan/.ssh/id_rsa" ]
then
    echo "starting cleanup"
    rm /home/jovyan/.ssh/id_rsa
    rm /home/jovyan/.ssh/authorized_keys
    rm /home/jovyan/.ssh/id_rsa.pub
    rm /home/jovyan/.ssh/ssh_host_rsa_key
    rm /home/jovyan/.ssh/ssh_host_rsa_key.pub 
    rm /home/jovyan/.ssh/sshd.pid
    rm /home/jovyan/.Xauthority
    rm -rf /home/jovyan/.dbus/session-bus
    rm -rf /home/jovyan/.vnc
    cp -r /tmp/jovyan/.vnc /home/jovyan/
fi

# update example directory
if [ -d "/home/jovyan/example-notebooks" ]
then
    cd /home/jovyan/example-notebooks
    git pull
else
    git clone https://github.com/NeuroDesk/example-notebooks /home/jovyan/example-notebooks
fi

# cvmfs2 -o config=/cvmfs/neurodesk.ardc.edu.au.conf neurodesk.ardc.edu.au /cvmfs/neurodesk.ardc.edu.au
# ssh-keygen -t rsa -f /home/jovyan/.ssh/id_rsa -b 4096 -m PEM -N '' <<< n
# ssh-keygen -t rsa -f /home/jovyan/.ssh/ssh_host_rsa_key -N '' <<< n
# cat /home/jovyan/.ssh/id_rsa.pub >> /home/jovyan/.ssh/authorized_keys

open_guacmole_conf () {
echo \
"<user-mapping>
<authorize username=\"jovyan\" password=\"password\">"  > /etc/guacamole/user-mapping.xml
}

close_guacmole_conf () {
echo \
"</authorize>
</user-mapping>" >> /etc/guacamole/user-mapping.xml
}

vnc () {
echo "\
==================================================================
Starting VNC server"
# su user -c "USER=user vncserver -kill :1"
# su user -c "USER=user vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" -localhost :1"
USER=jovyan vncserver -kill :1
USER=jovyan vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
xset -display :1 s off
echo \
"<connection name=\"Desktop Fixed-Resolution (VNC)\">
<protocol>vnc</protocol>
<param name=\"hostname\">localhost</param>
<param name=\"username\">jovyan</param>
<param name=\"password\">password</param>
<param name=\"port\">5901</param>
<param name=\"enable-sftp\">true</param>
<param name=\"sftp-port\">2222</param>
<param name=\"sftp-username\">jovyan</param>" >> /etc/guacamole/user-mapping.xml

echo "<param name=\"sftp-private-key\">$(cat /home/jovyan/.ssh/id_rsa)" >> /etc/guacamole/user-mapping.xml

echo \
"</param>
<param name=\"sftp-directory\">/home/jovyan/Desktop</param>
<param name=\"sftp-root-directory\">/home/jovyan/Desktop</param>
<param name=\"enable-audio\">false</param>
<param name=\"audio-servername\">127.0.0.1</param>
</connection>" >> /etc/guacamole/user-mapping.xml
}

rdp () {
echo "\
==================================================================
Starting RDP server"
sudo service xrdp restart
echo \
"<connection name=\"Desktop Auto-Resolution (RDP)\">
<protocol>rdp</protocol>
<param name=\"hostname\">localhost</param>
<param name=\"username\">jovyan</param>
<param name=\"password\">password</param>
<param name=\"port\">3389</param>
<param name=\"security\">any</param>
<param name=\"ignore-cert\">true</param>
<param name=\"resize-method\">reconnect</param>
<param name=\"enable-drive\">true</param>
<param name=\"drive-path\">/home/jovyan/Desktop</param>
</connection>" >> /etc/guacamole/user-mapping.xml
}

default=true
open_guacmole_conf
if [ "$rdp" = true ]; then
    rdp
    default=""
fi
if [ "$vnc" = true ]; then
    vnc
    default=""
fi
if [ "$default" = true ]; then
    # vnc
    rdp
fi
close_guacmole_conf

export JAVA_OPTS="-Xms512M -Xmx1024M"
export CATALINA_OPTS="-Xms512M -Xmx1024M"

# cd /neurocommand
# git fetch
# git pull
# bash build.sh
# cd /home/jovyan

# /usr/sbin/sshd -f /home/jovyan/.ssh/sshd_config
# USER=jovyan vncserver -kill :1
# USER=jovyan vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
# xset -display :1 s off

/usr/local/tomcat/bin/startup.sh
guacd -b 127.0.0.1
echo "===========================================================" 