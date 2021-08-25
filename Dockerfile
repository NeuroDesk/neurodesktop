ARG GO_VERSION="1.14.12"
ARG SINGULARITY_VERSION="3.8.2"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.52"
ARG GUACAMOLE_VERSION="1.3.0"

# Create final image.
FROM ubuntu:20.04

# Install locale and set
RUN apt-get update &&            \
    apt-get install -y           \
    --no-install-recommends      \
      locales &&                 \
    apt-get clean &&             \
    rm -rf /var/lib/apt/lists/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Apache Tomcat dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    sudo \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Apache Tomcat
ARG TOMCAT_REL
ARG TOMCAT_VERSION
RUN wget https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp && \
    tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp && \
    mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat && \
    mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist && \
    mkdir /usr/local/tomcat/webapps && \
    sh -c 'chmod +x /usr/local/tomcat/bin/*.sh'

# Install Guacamole dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    make \
    gcc \
    g++ \
    openjdk-11-jre \
    libpng-dev \
    libjpeg-turbo8-dev \
    libcairo2-dev \
    libtool-bin \
    libossp-uuid-dev \
    libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# Install LXDE
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    lxde \
    # lxde-core \
    && rm -rf /var/lib/apt/lists/*

# Install SSH dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    openssh-server \
    libpango1.0-dev \
    libssh2-1-dev \
    libssl-dev \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install VNC dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    libvncserver-dev \
    libxt6 \
    xauth \
    xorg \
    && rm -rf /var/lib/apt/lists/*

# Install RDP dependancies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    freerdp2-dev \
    xrdp \
    xauth \
    xorg \
    xorgxrdp \
    && rm -rf /var/lib/apt/lists/*

# Install Apache Guacamole
ARG GUACAMOLE_VERSION
WORKDIR /etc/guacamole
RUN wget "https://www.strategylions.com.au/mirror/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-1.3.0.war" -O /usr/local/tomcat/webapps/ROOT.war && \
    wget "https://www.strategylions.com.au/mirror/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-1.3.0.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz && \
    tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz && \
    cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} && \
   ./configure --with-init-dir=/etc/init.d &&   \
    make &&                            \
    make install &&                             \
    ldconfig &&                                 \
    rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}*

# Create Guacamole configurations
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties && \
    touch /etc/guacamole/user-mapping.xml

# Remove unused dependancies
RUN apt-get purge -y \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install TigerVNC
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    tigervnc-standalone-server tigervnc-common \
    && rm -rf /var/lib/apt/lists/*


# Install basic tools
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    lxterminal \
    lxrandr \
    curl \
    gpg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# # Install singularity into the final image.
# COPY --from=builder /usr/local/singularity /usr/local/singularity

# This bundles all installs to get a faster container build:
# Add Visual Studio code and nextcloud client
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list \
    && add-apt-repository ppa:nextcloud-devs/client

# # Add CVMFS
# RUN wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb \
#     && dpkg -i cvmfs-release-latest_all.deb \
#     && rm cvmfs-release-latest_all.deb

# RUN apt-get update \
#     && apt-get install -y \
#     lsb-release \
#     cvmfs \
#     &&  rm -rf /var/lib/apt/lists/*

# # configure CVMFS
# RUN mkdir -p /etc/cvmfs/keys/ardc.edu.au/ \
#     && echo "-----BEGIN PUBLIC KEY-----" | sudo tee /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwUPEmxDp217SAtZxaBep" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "Bi2TQcLoh5AJ//HSIz68ypjOGFjwExGlHb95Frhu1SpcH5OASbV+jJ60oEBLi3sD" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "qA6rGYt9kVi90lWvEjQnhBkPb0uWcp1gNqQAUocybCzHvoiG3fUzAe259CrK09qR" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "pX8sZhgK3eHlfx4ycyMiIQeg66AHlgVCJ2fKa6fl1vnh6adJEPULmn6vZnevvUke" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "I6U1VcYTKm5dPMrOlY/fGimKlyWvivzVv1laa5TAR2Dt4CfdQncOz+rkXmWjLjkD" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "87WMiTgtKybsmMLb2yCGSgLSArlSWhbMA0MaZSzAwE9PJKCCMvTANo5644zc8jBe" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "NQIDAQAB" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "-----END PUBLIC KEY-----" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
#     && echo "CVMFS_USE_GEOAPI=yes" | sudo tee /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
#     && echo 'CVMFS_SERVER_URL="http://140.238.213.184/cvmfs/@fqrn@;http://132.145.179.103/cvmfs/@fqrn@;http://152.67.101.67/cvmfs/@fqrn@"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
#     && echo 'CVMFS_KEYS_DIR="/etc/cvmfs/keys/ardc.edu.au/"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
#     && echo "CVMFS_HTTP_PROXY=DIRECT" | sudo tee  /etc/cvmfs/default.local \
#     && echo "CVMFS_QUOTA_LIMIT=5000" | sudo tee -a  /etc/cvmfs/default.local \
#     && cvmfs_config setup 

# Install packages with --no-install-recommends to keep things slim
# 1) singularity's and lmod's runtime dependencies.
# 2) various tools
# 3) julia
# 4) nextcloud-client
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        cryptsetup \
        squashfs-tools \
        lua-bit32 \
        lua-filesystem \
        lua-json \
        lua-lpeg \
        lua-posix \
        lua-term \
        lua5.2 \
        lmod \
        git \
        aria2 \
        code \
        emacs \
        gedit \
        htop \
        imagemagick \
        less \
        nano \
        openssh-client \
        python3-pip \
        rsync \
        screen \
        tree \
        vim \
        gcc \
        python3-dev \
        graphviz \
        libzstd1 \
        libgfortran5 \
        zlib1g-dev \
        zip \
        unzip \
        nextcloud-client \
        iputils-ping \
        sshfs \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/apt/sources.list.d/vs-code.list

# add module script
COPY ./config/module.sh /usr/share/

# install nipype
RUN pip3 install nipype \
    && rm -rf /root/.cache/pip \
    && rm -rf /home/ubuntu/.cache/

# configure tiling of windows SHIFT-ALT-CTR-{Left,right,top,Bottom} and other openbox desktop mods
COPY ./config/rc.xml /etc/xdg/openbox

# configure ITKsnap
COPY ./config/.itksnap.org /etc/skel/.itksnap.org
COPY ./config/mimeapps.list /etc/skel/.config/mimeapps.list

# Use custom bottom panel configuration
COPY ./config/panel /etc/skel/.config/lxpanel/LXDE/panels/panel

# # Allow the root user to access the sshfs mount
# # https://github.com/NeuroDesk/neurodesk/issues/47
# RUN sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# # try to start cvmfs via modified /etc/supervisor/supervisord.conf
# COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# COPY ./config/state.py /usr/local/lib/web/backend/vnc/state.py
# RUN mkdir /cvmfs/neurodesk.ardc.edu.au
# # COPY ./config/startup.sh /startup.sh
# # RUN chmod a+x /startup.sh

# # setup module system & singularitycd
# COPY ./config/.bashrc /tmp/.bashrc
# RUN cat /tmp/.bashrc >> /etc/skel/.bashrc && rm /tmp/.bashrc
# RUN directories=`curl https://raw.githubusercontent.com/NeuroDesk/caid/master/recipes/globalMountPointList.txt` \
#     && mounts=`echo $directories | sed 's/ /,/g'` \
#     && echo "export SINGULARITY_BINDPATH=${mounts}" >> /etc/skel/.bashrc

RUN mkdir -p `curl https://raw.githubusercontent.com/NeuroDesk/neurocontainers/master/recipes/globalMountPointList.txt`

RUN sudo apt-get update && sudo apt-get install -y \
    build-essential \
    uuid-dev \
    libgpgme-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup-bin

ARG GO_VERSION
ARG SINGULARITY_VERSION

RUN export VERSION=${GO_VERSION} OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz && \
    export GOPATH=${HOME}/go && \
    export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin && \
    mkdir -p $GOPATH/src/github.com/sylabs && \
    cd $GOPATH/src/github.com/sylabs && \
    wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    tar -xzvf singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    cd singularity-ce-${SINGULARITY_VERSION} && \
    ./mconfig -p /usr/local/singularity && \
    make -C builddir && \
    make -C builddir install && \
    rm -rf /usr/local/go $GOPATH 

# setup module system & singularitycd
COPY ./config/.bashrc /tmp/.bashrc
RUN cat /tmp/.bashrc >> /etc/skel/.bashrc && rm /tmp/.bashrc
RUN directories=`curl https://raw.githubusercontent.com/NeuroDesk/caid/master/recipes/globalMountPointList.txt` \
    && mounts=`echo $directories | sed 's/ /,/g'` \
    && echo "export SINGULARITY_BINDPATH=${mounts}" >> /etc/skel/.bashrc

RUN git clone -b neuromachine https://github.com/NeuroDesk/neurodesk.git /neurodesk
WORKDIR /neurodesk
RUN bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /vnm/containers /neurodesk/local/containers \
    && mkdir -p /etc/skel/Desktop/ \
    && ln -s /vnm /etc/skel/Desktop/

# Create user account with password-less sudo abilities
RUN useradd -s /bin/bash -g 100 -G sudo -m user && \
    /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set VNC password
RUN mkdir /home/user/.vnc && \
   chown user /home/user/.vnc && \
   /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su user -c vncpasswd
RUN  echo -n 'password\npassword\nn\n' | su user -c vncpasswd

# Add entrypoint script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

WORKDIR /home/user
USER 1000:100

ENTRYPOINT sudo -E /startup.sh