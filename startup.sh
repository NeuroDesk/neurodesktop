#!/bin/bash

service ssh start &&   \
/usr/local/tomcat/bin/startup.sh; \
su user -c "guacd -L debug -f"
#su user -c "USER=user vncserver -depth 24 -geometry $RES -name \"VNC\" :1" && \
# su user -c "USER=user /opt/TurboVNC/bin/vncserver -localhost -verbose -nohttpd -depth 24 -geometry $RES -securitytypes NONE -name \"VNC\" :1" && \
