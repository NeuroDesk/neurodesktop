#!/bin/bash

sudo /usr/local/tomcat/bin/startup.sh
sudo service guacd start
sudo service xrdp start
vncserver -kill :1
vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
xset -display :1 s off
