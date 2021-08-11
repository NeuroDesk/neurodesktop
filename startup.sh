#!/bin/bash

full () {
  echo \
"<user-mapping>
    <authorize username=\"user\" password=\"password\">
        <connection name=\"SSH\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">22</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-root-directory\">/home/user</param>
        </connection>
        <connection name=\"VNC TigerVNC\">
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
        </connection>
        <connection name=\"VNC TurboVNC\">
            <protocol>vnc</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">5902</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-username\">user</param>
            <param name=\"sftp-password\">password</param>
            <param name=\"sftp-directory\">/home/user</param>
            <param name=\"sftp-root-directory\">/home/user</param>
            <param name=\"enable-audio\">true</param>
            <param name=\"audio-servername\">127.0.0.1</param>
        </connection>
        <connection name=\"RDP Fixed-size\">
            <protocol>rdp</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">3389</param>
            <param name=\"security\">any</param>
            <param name=\"ignore-cert\">true</param>
        </connection>
        <connection name=\"RDP Auto-size\">
            <protocol>rdp</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">3389</param>
            <param name=\"security\">any</param>
            <param name=\"ignore-cert\">true</param>
            <param name=\"resize-method\">reconnect</param>
        </connection>
    </authorize>
</user-mapping>" > /etc/guacamole/user-mapping.xml
}

default () {
  echo \
"<user-mapping>
    <authorize username=\"user\" password=\"password\">
        <connection name=\"SSH\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">22</param>
            <param name=\"enable-sftp\">true</param>
            <param name=\"sftp-root-directory\">/home/user</param>
        </connection>
        <connection name=\"VNC\">
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
        </connection>
        <connection name=\"RDP\">
            <protocol>rdp</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"username\">user</param>
            <param name=\"password\">password</param>
            <param name=\"port\">3389</param>
            <param name=\"security\">any</param>
            <param name=\"ignore-cert\">true</param>
            <param name=\"resize-method\">reconnect</param>
        </connection>
    </authorize>
</user-mapping>" > /etc/guacamole/user-mapping.xml
}

# full
default
# RES="2560x1440"
RES="1920x1080"

service ssh start &&   \
service xrdp start && \
su user -c "USER=user vncserver -depth 24 -geometry $RES -name \"VNC\" :1" && \
/usr/local/tomcat/bin/startup.sh; \
su user -c "guacd -L debug -f"


# TurboVNC
# su user -c "USER=user /opt/TurboVNC/bin/vncserver -localhost -verbose -nohttpd -depth 24 -geometry $RES -securitytypes NONE -name \"VNC\" :2" && \
#su user -c "USER=user vncserver -depth 24 -geometry $RES -name \"VNC\" :1" && \
