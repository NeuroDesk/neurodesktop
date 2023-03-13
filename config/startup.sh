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

xset -display :1 s off
su jovyan -c "vncserver -kill :1"
su jovyan -c "vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1"
service xrdp restart

export JAVA_OPTS="-Xms512M -Xmx1024M"
export CATALINA_OPTS="-Xms512M -Xmx1024M"

/usr/local/tomcat/bin/startup.sh
guacd -b 127.0.0.1
echo "===========================================================" 