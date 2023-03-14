#!/bin/bash

export JAVA_OPTS="-Xms512M -Xmx1024M"
export CATALINA_OPTS="-Xms512M -Xmx1024M"
sudo /usr/local/tomcat/bin/startup.sh

sudo service guacd restart
sudo service xrdp restart
vncserver -kill :1
vncserver -depth 24 -geometry 1920x1080 -name \"VNC\" :1
xset -display :1 s off
