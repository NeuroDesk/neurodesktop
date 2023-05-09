#!/bin/bash

# Tomcat
sudo /usr/local/tomcat/bin/startup.sh

# Guacamole
sudo service guacd start

# RDP
sudo service xrdp start

# SSH/SFTP
/usr/sbin/sshd -f /home/jovyan/.ssh/sshd_config

# VNC
vncserver -kill :1
vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
xset -display :1 s off
