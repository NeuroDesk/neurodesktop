# Create final image
FROM ubuntu:20.04

# Install base image dependancies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        locales \
        sudo \
        wget \
        ca-certificates \
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
        dirmngr \
        gpg-agent \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Apache Tomcat
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.58"
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp \
    && tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp \
    && rm -rf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    && mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat \
    && mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist \
    && mkdir /usr/local/tomcat/webapps \
    && sh -c 'chmod +x /usr/local/tomcat/bin/*.sh'

# Install Apache Guacamole
ARG GUACAMOLE_VERSION="1.4.0"
WORKDIR /etc/guacamole
RUN wget -q "https://apache.mirror.digitalpacific.com.au/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" -O /usr/local/tomcat/webapps/ROOT.war \
    && wget -q "https://apache.mirror.digitalpacific.com.au/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && rm -rf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}*

# Create Guacamole configurations (user-mapping.xml gets filled in the startup.sh script)
RUN echo "user-mapping: /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties

# Add Visual Studio code and nextcloud client
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list \
    && add-apt-repository ppa:nextcloud-devs/client

# Add CVMFS
RUN wget -q https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -O /tmp/cvmfs-release-latest_all.deb \
    && dpkg -i /tmp/cvmfs-release-latest_all.deb \
    && rm /tmp/cvmfs-release-latest_all.deb

# Add datalad
RUN wget -q -O- http://neuro.debian.net/lists/focal.us-nh.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9

# Install basic tools
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
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
        aria2 \
        code \
        emacs \
        gedit \
        htop \
        imagemagick \
        less \
        nano \
        openssh-client \
        rsync \
        screen \
        tree \
        vim \
        gcc \
        graphviz \
        libzstd1 \
        libgfortran5 \
        zlib1g-dev \
        zip \
        unzip \
        nextcloud-client \
        iputils-ping \
        sshfs \
        build-essential \
        uuid-dev \
        libgpgme-dev \
        squashfs-tools \
        libseccomp-dev \
        pkg-config \
        git \
        cryptsetup-bin\
        lsb-release \
        cvmfs \
        rclone \
        davfs2 \
        owncloud-client \
        firefox \
        gnome-keyring \
        xdg-utils \
        libpci3 \
        tk \
        tcllib \
        datalad \
        python3-pip \
        python3 \
        lxtask \
        qdirstat \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/apt/sources.list.d/vs-code.list

# Configure CVMFS
RUN mkdir -p /etc/cvmfs/keys/ardc.edu.au/ \
    && echo "-----BEGIN PUBLIC KEY-----" | sudo tee /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwUPEmxDp217SAtZxaBep" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "Bi2TQcLoh5AJ//HSIz68ypjOGFjwExGlHb95Frhu1SpcH5OASbV+jJ60oEBLi3sD" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "qA6rGYt9kVi90lWvEjQnhBkPb0uWcp1gNqQAUocybCzHvoiG3fUzAe259CrK09qR" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "pX8sZhgK3eHlfx4ycyMiIQeg66AHlgVCJ2fKa6fl1vnh6adJEPULmn6vZnevvUke" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "I6U1VcYTKm5dPMrOlY/fGimKlyWvivzVv1laa5TAR2Dt4CfdQncOz+rkXmWjLjkD" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "87WMiTgtKybsmMLb2yCGSgLSArlSWhbMA0MaZSzAwE9PJKCCMvTANo5644zc8jBe" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "NQIDAQAB" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "-----END PUBLIC KEY-----" | sudo tee -a /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub \
    && echo "CVMFS_USE_GEOAPI=yes" | sudo tee /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
    && echo 'CVMFS_SERVER_URL="http://cvmfs.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-ashburn.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-zurich.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-toronto.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-frankfurt.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-sydney.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-brisbane.neurodesk.org/cvmfs/@fqrn@"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
    && echo 'CVMFS_KEYS_DIR="/etc/cvmfs/keys/ardc.edu.au/"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
    && echo "CVMFS_HTTP_PROXY=DIRECT" | sudo tee  /etc/cvmfs/default.local \
    && echo "CVMFS_QUOTA_LIMIT=5000" | sudo tee -a  /etc/cvmfs/default.local \
    && cvmfs_config setup 

# Add module script
COPY ./config/module.sh /usr/share/

# This should be installed in miniconda environment
# # Install nipype
# RUN pip3 install nipype \
#     && rm -rf /root/.cache/pip \
#     && rm -rf /home/ubuntu/.cache/

# Configure shortcuts for tiling of windows and other openbox desktop mods
COPY ./config/rc.xml /etc/xdg/openbox

# Configure ITKsnap
COPY ./config/.itksnap.org /etc/skel/.itksnap.org
COPY ./config/mimeapps.list /etc/skel/.config/mimeapps.list

# Apply custom bottom panel configuration
COPY ./config/panel /etc/skel/.config/lxpanel/LXDE/panels/panel

# Allow the root user to access the sshfs mount
# https://github.com/NeuroDesk/neurodesk/issues/47
RUN sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Fetch singularity bind mount list
RUN mkdir -p `curl https://raw.githubusercontent.com/NeuroDesk/neurocontainers/master/recipes/globalMountPointList.txt`

# Install singularity
ARG GO_VERSION="1.17.2"
ARG SINGULARITY_VERSION="3.9.3"
RUN export VERSION=${GO_VERSION} OS=linux ARCH=amd64 \
    && wget -q https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz \
    && sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz \
    && rm go$VERSION.$OS-$ARCH.tar.gz \
    && export GOPATH=${HOME}/go \
    && export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin \
    && mkdir -p $GOPATH/src/github.com/sylabs \
    && cd $GOPATH/src/github.com/sylabs \
    && wget -q https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && tar -xzvf singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && cd singularity-ce-${SINGULARITY_VERSION} \
    && ./mconfig --prefix=/usr/local/singularity \
    && make -C builddir \
    && make -C builddir install \
    && cd .. \
    && rm -rf singularity-ce-${SINGULARITY_VERSION} \
    && rm -rf /usr/local/go $GOPATH \
    && ln -s /usr/local/singularity/bin/singularity /bin/ 

# Setup module system & singularity
COPY ./config/.bashrc /tmp/.bashrc
RUN cat /tmp/.bashrc >> /etc/skel/.bashrc && rm /tmp/.bashrc \
    && directories=`curl https://raw.githubusercontent.com/NeuroDesk/caid/master/recipes/globalMountPointList.txt` \
    && mounts=`echo $directories | sed 's/ /,/g'` \
    && echo "export SINGULARITY_BINDPATH=${mounts},/neurodesktop-storage" >> /etc/skel/.bashrc

# add Globus client (requires tk and tcllib -> installed earlier to speed up build)
WORKDIR /opt/globusconnectpersonal
RUN wget -q https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz \
    && tar xzf globusconnectpersonal-latest.tgz \
    && rm -rf globusconnectpersonal-latest.tgz

# Desktop styling
COPY config/desktop_wallpaper.jpg /usr/share/lxde/wallpapers/desktop_wallpaper.jpg
COPY config/pcmanfm.conf /etc/xdg/pcmanfm/LXDE/pcmanfm.conf
COPY config/lxterminal.conf /usr/share/lxterminal/lxterminal.conf

# Change firefox home
RUN echo 'pref("browser.startup.homepage", "http://neurodesk.github.io", locked);' >> /etc/firefox/syspref.js \
    && echo 'pref("browser.startup.firstrunSkipsHomepage", true, locked);' >> /etc/firefox/syspref.js \
    && echo 'pref("startup.homepage_welcome_url", "http://neurodesk.github.io", locked);' >> /etc/firefox/syspref.js \
    && echo 'pref("browser.aboutwelcome.enabled", true, locked);' >> /etc/firefox/syspref.js

# Create link to persistent storage on Desktop (This needs to happen before the users gets created!)
RUN mkdir -p /etc/skel/Desktop/ \
    && ln -s /neurodesktop-storage /etc/skel/Desktop/storage \
    && ln -s /neurodesktop-storage /etc/skel/neurodesktop-storage

# Create shorter link to persistent storage /neurodesktop-storage
RUN ln -s /neurodesktop-storage /storage

# Add checkversion script
COPY ./config/checkversion.sh /usr/share/
# Add CheckVersion script
COPY ./config/CheckVersion.desktop /etc/skel/Desktop

# Create user account with password-less sudo abilities and vnc user
RUN addgroup --gid 9001 user \
    && useradd -s /bin/bash -g user -G sudo -m user \
    && /usr/bin/printf '%s\n%s\n' 'password' 'password'| passwd user \
    && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir /home/user/.vnc \
    && chown user /home/user/.vnc \
    && /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su user -c vncpasswd \
    && echo -n 'password\npassword\nn\n' | su user -c vncpasswd

# Install Julia
# WORKDIR /opt
# ARG JULIA_VERSION='1.6.1'
# ARG JULIA_MAIN_VERSION='1.6'
# RUN wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_MAIN_VERSION}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
#     && tar zxvf julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
#     && rm -rf julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
#     && ln -s /opt/julia-${JULIA_VERSION} /opt/julia-latest
# ENV PATH=$PATH:/opt/julia-${JULIA_VERSION}/bin

USER user
WORKDIR /home/user

# Install vscode extensions and configure vscode for miniconda and julia
ENV DONT_PROMPT_WSL_INSTALL=1
# RUN code --install-extension julialang.language-julia \
#     && code --install-extension ms-python.python \
#     && code --install-extension ms-python.vscode-pylance \
#     && code --install-extension ms-toolsai.jupyter \
#     && code --install-extension ms-toolsai.jupyter-keymap \
#     && code --install-extension ms-toolsai.jupyter-renderers
COPY config/vscode/settings.json /home/user/.config/Code/User/settings.json

# Add libfm script
RUN mkdir -p /home/user/.config/libfm
COPY ./config/libfm.conf /home/user/.config/libfm

RUN touch /home/user/.sudo_as_admin_successful

# This doesn't work if we install extensions - can we do this in the startup file and move the folder over once the persistent storage?
# # Link vscode config to persistant storage
# RUN mkdir -p /home/user/.config \
#     && ln -s /neurodesktop-storage/.config/Code .config/Code \
#     && ln -s /neurodesktop-storage/.vscode .vscode

# RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
#     && bash Miniconda3-latest-Linux-x86_64.sh -b \
#     && rm Miniconda3-latest-Linux-x86_64.sh \
#     && miniconda3/bin/conda init

# Add datalad-container to the conda environment
RUN pip install datalad-container

# Setup git
RUN git config --global user.email "user@neurodesk.github.io"
RUN git config --global user.name "Neurodesk User"

USER root

# make vs code settings editable for user 
RUN chown user /home/user/.config/Code/ -R

# Add entrypoint script
COPY config/startup.sh /startup.sh
RUN chmod +x /startup.sh

WORKDIR /neurodesktop-storage

# Enable entrypoint
ENTRYPOINT ["sudo", "-E", "/startup.sh"]

# Install neurocommand
ADD "http://api.github.com/repos/NeuroDesk/neurocommand/commits/main" /tmp/skipcache
RUN rm /tmp/skipcache \
    && git clone https://github.com/NeuroDesk/neurocommand.git /neurocommand \
    && cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers 
