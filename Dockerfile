# FROM jupyter/base-notebook:2023-02-28
FROM jupyter/base-notebook:python-3.10.9
# FROM jupyter/base-notebook:notebook-6.5.3

# FROM jupyter/base-notebook:python-3.10.4

# Parent image source
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/docker-stacks-foundation/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/base-notebook/Dockerfile

USER root

# Install base image dependancies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        make \
        dirmngr \ 
        gcc \
        g++ \
        gpg-agent \
        openjdk-11-jre \
        libpng-dev \
        libjpeg-turbo8-dev \
        libcairo2-dev \
        libtool-bin \
        libossp-uuid-dev \
        libwebp-dev \
        lxde \
        openssh-server \
        libpango1.0-dev \
        libssh2-1-dev \
        libssl-dev \
        openssh-server \
        libvncserver-dev \
        libxt6 \
        xauth \
        xorg \
        freerdp2-dev \
        xrdp \
        xauth \
        xorg \
        xorgxrdp \
        tigervnc-standalone-server \
        tigervnc-common \
        lxterminal \
        lxrandr \
        curl \
        gpg \
        software-properties-common \
        dbus-x11 \
        man-db \
        pciutils \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /home/jovyan/.cache

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        openjdk-19-jre

ARG GO_VERSION="1.20.2"
ARG SINGULARITY_VERSION="3.11.0"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.73"
ARG GUACAMOLE_VERSION="1.5.0"
ARG JULIA_VERSION="1.8.3"

ENV LANG ""
ENV LANGUAGE ""
ENV LC_ALL ""

ARG GUACAMOLE_VERSION
WORKDIR /etc/guacamole
RUN wget "https://archive.apache.org/dist/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}* \
    && rm -rf /home/jovyan/.cache

# Create Guacamole configurations
COPY --chown=root:root config/user-mapping.xml /etc/guacamole/user-mapping.xml
COPY --chown=root:root config/guacamole.properties /etc/guacamole/guacamole.properties
COPY --chown=root:root config/guacd.conf /etc/guacamole/guacd.conf
