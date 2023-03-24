#!/bin/bash

xpra start \
    --html=on \
    --bind-tcp=0.0.0.0:9090 \
    --start=xterm \
    --no-daemon \
    --clipboard-direction=both \
    --keyboard-sync=no \
    --no-mdns \
    --no-bell \
    --no-speaker \
    --no-printing \
    --no-microphone \
    --no-notifications \
    --no-systemd-run