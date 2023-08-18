FROM jupyter/base-notebook:2023-05-01
# FROM jupyter/base-notebook:python-3.10.10

ARG BUILDPLATFORM
# Parent image source
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/docker-stacks-foundation/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/base-notebook/Dockerfile

USER root

#========================================#
# Core services
#========================================#

# Install base image dependencies
RUN apt-get update --yes \
    && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends \
        # Singularity
        build-essential \
        libseccomp-dev \
        libglib2.0-dev \
        pkg-config \
        squashfs-tools \
        cryptsetup \
        runc \
        # Apache Tomcat
        openjdk-19-jre \
        # Apache Guacamole
        ## Core
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libpng-dev \
        libtool-bin \
        uuid-dev \
        ## Optionals
        freerdp2-dev \
        libvncserver-dev \
        libssl-dev \
        libwebp-dev \
        libssh2-1-dev \
        # SSH (Optional)
        libpango1.0-dev \
        ## VNC
        tigervnc-common \
        tigervnc-standalone-server \
        tigervnc-tools \
        ## RDP
        xorgxrdp \
        xrdp \
        # Desktop Env
        lxde \
        # Installer tools
        acl \
        wget \
        curl \
        dirmngr \ 
        gpg \
        gpg-agent \
        software-properties-common \
        apt-transport-https \
        && apt-get clean && rm -rf /var/lib/apt/lists/* 

ARG GO_VERSION="1.20.4"
ARG SINGULARITY_VERSION="3.11.3"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.75"
ARG GUACAMOLE_VERSION="1.5.2"

ENV LANG ""
ENV LANGUAGE ""
ENV LC_ALL ""

# Install singularity
RUN export VERSION=${GO_VERSION} OS=linux ARCH=$BUILDPLATFORM \
    && wget https://go.dev/dl/go${VERSION}.${OS}-${ARCH}.tar.gz \
    && tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz \
    && rm go$VERSION.$OS-$ARCH.tar.gz \
    && export GOPATH=/opt/go \
    && export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin \
    && mkdir -p $GOPATH/src/github.com/sylabs \
    && cd $GOPATH/src/github.com/sylabs \
    && wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && tar -xzvf singularity-ce-${SINGULARITY_VERSION}.tar.gz \
    && cd singularity-ce-${SINGULARITY_VERSION} \
    && ./mconfig --without-suid --prefix=/usr/local/singularity \
    && make -C builddir \
    && make -C builddir install \
    && rm -rf singularity-ce-${SINGULARITY_VERSION} \
    && rm -rf /usr/local/go $GOPATH \
    && ln -s /usr/local/singularity/bin/singularity /bin/ \ 
    && rm -rf /root/.cache && rm -rf /home/${NB_USER}/.cache

# Install Apache Tomcat
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp \
    && tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp \
    && rm -rf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    && mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat \
    && mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist \
    && mkdir /usr/local/tomcat/webapps \
    && chmod +x /usr/local/tomcat/bin/*.sh

# Install Apache Guacamole
RUN wget -q "https://archive.apache.org/dist/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" -O /usr/local/tomcat/webapps/ROOT.war \
    && wget -q "https://archive.apache.org/dist/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -P /tmp \
    && tar xvf /tmp/guacamole-server-${GUACAMOLE_VERSION}.tar.gz -C /tmp \
    && rm /tmp/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /tmp/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /tmp/guacamole-server-${GUACAMOLE_VERSION}

# Set home directory default acls
RUN chmod g+rwxs /home/${NB_USER}
RUN setfacl -dRm u::rwX,g::rwX,o::0 /home/${NB_USER}

# #========================================#
# # Software (as root user)
# #========================================#

# Add Software sources
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && rm -f packages.microsoft.gpg \
    # Nextcloud Client
    && add-apt-repository ppa:nextcloud-devs/client \
    && chmod -R 770 /home/${NB_USER}/.launchpadlib \
    && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.launchpadlib \
    # # Datalad
    # && wget -q -O- http://neuro.debian.net/lists/focal.us-nh.full | tee /etc/apt/sources.list.d/neurodebian.sources.list \
    # && apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9 \
    # NodeJS
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install CVMFS
RUN wget -q https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -P /tmp \
    && dpkg -i /tmp/cvmfs-release-latest_all.deb \
    && rm /tmp/cvmfs-release-latest_all.deb

# Install Tools and Libs
RUN apt-get update --yes \
    && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends \
        aria2 \
        code \
        cvmfs \
        datalad \
        davfs2 \
        debootstrap \
        emacs \
        gedit \
        git \
        gnome-keyring \
        graphviz \
        htop \
        imagemagick \
        iputils-ping \
        less \
        libgfortran5 \
        libgpgme-dev \
        libossp-uuid-dev \
        libpci3 \
        libreoffice \
        lmod \
        lua-bit32 \
        lua-filesystem \
        lua-json \
        lua-lpeg \
        lua-posix \
        lua-term \
        lua5.2 \
        lxtask \
        man-db \
        nano \
        nextcloud-client \
        nodejs \
        openssh-client \
        openssh-server \
        owncloud-client \
        pciutils \
        qdirstat \
        rsync \
        s3fs \
        screen \
        sshfs \
        tcllib \
        tk \
        tmux \
        tree \
        uidmap \
        unzip \
        vim \
        xdg-utils \
        yarn \
        zip \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install firefox
RUN add-apt-repository ppa:mozillateam/ppa \
    && apt-get update --yes \
    && DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends \
        --target-release 'o=LP-PPA-mozillateam' firefox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY config/firefox/mozillateamppa /etc/apt/preferences.d/mozillateamppa
COPY config/firefox/syspref.js /etc/firefox/syspref.js

#========================================#
# Software (as notebook user)
#========================================#

USER ${NB_USER}

## Install conda packages
# RUN conda install -c conda-forge nipype pip nb_conda_kernels \
#     && conda clean --all -f -y \
#     && rm -rf /home/${NB_USER}/.cache
# RUN conda config --system --prepend envs_dirs '~/conda-environments'

# Install conda packages
RUN conda install -c conda-forge nb_conda_kernels \
    && conda clean --all -f -y \
    && rm -rf /home/${NB_USER}/.cache
RUN conda config --system --prepend envs_dirs '~/conda-environments'

## Update conda / this will update pandoc and consume quite a bit of unnessary space
# RUN conda update -n base conda \
#     && conda clean --all -f -y \
#     && rm -rf /home/${NB_USER}/.cache

# Add datalad-container datalad-osf osfclient ipyniivue to the conda environment
RUN /opt/conda/bin/pip install nipype matplotlib datalad-container datalad-osf osfclient ipyniivue \
    && rm -rf /home/${NB_USER}/.cache

# Install jupyter-server-proxy and disable announcements
# Deprecated: jupyter labextension install ..
RUN /opt/conda/bin/pip install jupyter-server-proxy \
    && /opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements \ 
    && /opt/conda/bin/pip install jupyterlmod \ 
    && /opt/conda/bin/pip install jupyterlab-git \
    && rm -rf /home/${NB_USER}/.cache

#========================================#
# Configuration (as root user)
#========================================#

USER root

# Create cvmfs keys
RUN mkdir -p /etc/cvmfs/keys/ardc.edu.au
COPY config/cvmfs/neurodesk.ardc.edu.au.pub /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub
COPY config/cvmfs/neurodesk.ardc.edu.au.conf /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf
COPY config/cvmfs/default.local /etc/cvmfs/default.local
# This causes conflicts with an external cvmfs setup that gets mounted
# RUN cvmfs_config setup

# # Customise logo, wallpaper, terminal
COPY config/jupyter/neurodesk_brain_logo.svg /opt/neurodesk_brain_logo.svg
COPY config/jupyter/neurodesk_brain_icon.svg /opt/neurodesk_brain_icon.svg

COPY config/lxde/background.png /usr/share/lxde/wallpapers/desktop_wallpaper.png
COPY config/lxde/pcmanfm.conf /etc/xdg/pcmanfm/LXDE/pcmanfm.conf
COPY config/lxde/lxterminal.conf /usr/share/lxterminal/lxterminal.conf
COPY config/lmod/module.sh /usr/share/

# Configure tiling of windows SHIFT-ALT-CTR-{Left,right,top,Bottom} and other openbox desktop mods
COPY ./config/lxde/rc.xml /etc/xdg/openbox

# Allow the root user to access the sshfs mount
# https://github.com/NeuroDesk/neurodesk/issues/47
RUN sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Fetch singularity bind mount list and create placeholder mountpoints
RUN mkdir -p `curl https://raw.githubusercontent.com/NeuroDesk/neurocontainers/master/recipes/globalMountPointList.txt`

# Fix "No session for pid prompt"
RUN rm /usr/bin/lxpolkit

# enable rootless mounts: 
RUN chmod +x /usr/bin/fusermount
    
# Add notebook startup scripts
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html
RUN mkdir -p /usr/local/bin/start-notebook.d/ \
    && mkdir -p /usr/local/bin/before-notebook.d/
COPY config/jupyter/start_notebook.sh /usr/local/bin/start-notebook.d/
COPY config/jupyter/before_notebook.sh /usr/local/bin/before-notebook.d/

# Add jupyter notebook and startup scripts for system-wide configuration
COPY --chown=root:users config/jupyter/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
COPY --chown=root:users config/jupyter/jupyterlab_startup.sh /opt/neurodesktop/jupyterlab_startup.sh
COPY --chown=root:users config/guacamole/guacamole.sh /opt/neurodesktop/guacamole.sh
COPY --chown=root:users config/jupyter/environment_variables.sh /opt/neurodesktop/environment_variables.sh
COPY --chown=root:users config/guacamole/user-mapping.xml /etc/guacamole/user-mapping.xml

RUN chmod +x /etc/jupyter/jupyter_notebook_config.py \
    /opt/neurodesktop/jupyterlab_startup.sh \
    /opt/neurodesktop/guacamole.sh \
    /opt/neurodesktop/environment_variables.sh

# Create Guacamole configurations (user-mapping.xml gets filled in the startup.sh script)
RUN mkdir -p /etc/guacamole \
    && echo -e "user-mapping: /etc/guacamole/user-mapping.xml\nguacd-hostname: 127.0.0.1" > /etc/guacamole/guacamole.properties \
    && echo -e "[server]\nbind_host = 127.0.0.1\nbind_port = 4822" > /etc/guacamole/guacd.conf

# Add NB_USER to sudoers
RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/notebook \
# The following apply to Singleuser mode only. See config/jupyter/before_notebook.sh for Notebook mode
    && /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER} \
    && usermod --shell /bin/bash ${NB_USER}

# Enable deletion of non-empty-directories in JupyterLab: https://github.com/jupyter/notebook/issues/4916
RUN sed -i 's/c.FileContentsManager.delete_to_trash = False/c.FileContentsManager.always_delete_dir = True/g' /etc/jupyter/jupyter_server_config.py

# Copy script to test_containers 
COPY config/test_neurodesktop.sh /usr/share/test_neurodesktop.sh

# Install version 1.1.1 of fix_bash.sh that is required for test_containers
RUN chmod +x /usr/share/test_neurodesktop.sh \
      && git clone https://github.com/civier/fix_bash.git /tmp/fix_bash \
      && cd /tmp/fix_bash \
      && git checkout tags/1.1.1 \
      && cp /tmp/fix_bash/fix_bash.sh /usr/share \
      && rm -Rf /tmp/fix_bash

#========================================#
# Configuration (as notebook user)
#========================================#

# Switch to notebook user
USER ${NB_USER}

# Configure ITKsnap
RUN mkdir -p /home/${NB_USER}/.itksnap.org/ITK-SNAP \
    && chown ${NB_USER} /home/${NB_USER}/.itksnap.org -R
COPY --chown=${NB_UID}:${NB_GID} ./config/itksnap/UserPreferences.xml /home/${NB_USER}/.itksnap.org
COPY --chown=${NB_UID}:${NB_GID} ./config/lxde/mimeapps.list /home/${NB_USER}/.config/mimeapps.list

COPY --chown=${NB_UID}:${NB_GID} config/lxde/panel /home/${NB_USER}/.config/lxpanel/LXDE/panels/panel
COPY --chown=${NB_UID}:${NB_GID} config/lxde/.bashrc /home/${NB_USER}/tmp_bashrc
RUN cat /home/${NB_USER}/tmp_bashrc >> /home/${NB_USER}/.bashrc \
     && rm /home/${NB_USER}/tmp_bashrc

# Setup git
RUN git config --global user.email "user@neurodesk.org" \
    && git config --global user.name "Neurodesk User"

# Setup temp directory for matplotlib (required for fmriprep)
RUN mkdir -p /home/${NB_USER}/.config/matplotlib-mpldir \
    && chmod -R 700 /home/${NB_USER}/.config/matplotlib-mpldir \
    && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}/.config/matplotlib-mpldir

# # Add checkversion script
# COPY ./config/checkversion.sh /usr/share/
# # Add CheckVersion script
# COPY ./config/CheckVersion.desktop /etc/skel/Desktop

COPY --chown=${NB_UID}:${NB_GID} config/vscode/settings.json /home/${NB_USER}/.config/Code/User/settings.json

# Add libfm script
RUN mkdir -p /home/${NB_USER}/.config/libfm
COPY --chown=${NB_UID}:${NB_GID} ./config/lxde/libfm.conf /home/${NB_USER}/.config/libfm

RUN touch /home/${NB_USER}/.sudo_as_admin_successful

ENV DONT_PROMPT_WSL_INSTALL=1
ENV LMOD_CMD /usr/share/lmod/lmod/libexec/lmod

# Add startup and config files for neurodesktop, jupyter, guacamole, vnc
RUN mkdir /home/${NB_USER}/.vnc \
    && chown ${NB_USER} /home/${NB_USER}/.vnc \
    && /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | vncpasswd
COPY --chown=${NB_UID}:${NB_GID} config/lxde/xstartup /home/${NB_USER}/.vnc
COPY --chown=${NB_UID}:${NB_GID} config/conda/conda-readme.md /home/${NB_USER}/

RUN mkdir -p /home/${NB_USER}/.ssh \
    && chmod -R 700 /home/${NB_USER}/.ssh \
    && setfacl -dRm u::rwx,g::0,o::0 /home/${NB_USER}/.ssh
COPY --chown=${NB_UID}:${NB_GID} config/ssh/sshd_config /home/${NB_USER}/.ssh/sshd_config

RUN chmod +x /home/${NB_USER}/.vnc/xstartup

# Set up working directories and symlinks
RUN mkdir -p /home/${NB_USER}/Desktop/ \
    && ln -s /neurodesktop-storage/ /home/${NB_USER} \
    && ln -s /data /home/${NB_USER}

#========================================#
# Finalise build
#========================================#

# Switch to root user
USER root

# Save a backup copy of startup home dir into /tmp
# Used to restore home dir in persistent sessions
RUN cp -rp /home/${NB_USER} /tmp/

# Set up working directories and symlinks
RUN mkdir -p /data \
    && ln -s /neurodesktop-storage /storage

# Install neurocommand
ADD "https://api.github.com/repos/neurodesk/neurocommand/git/refs/heads/main" /tmp/skipcache
RUN rm /tmp/skipcache \
    && git clone https://github.com/NeuroDesk/neurocommand.git /neurocommand \
    && cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && mkdir -p /neurodesktop-storage/containers \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers

USER ${NB_UID}

WORKDIR "${HOME}"

# Install example notebooks
ADD "https://api.github.com/repos/neurodesk/example-notebooks/git/refs/heads/main" /home/${NB_USER}/skipcache
RUN rm /home/${NB_USER}/skipcache \
    && git clone --depth 1 https://github.com/NeuroDesk/example-notebooks

ENV MODULEPATH=/cvmfs/neurodesk.ardc.edu.au/containers/modules/
