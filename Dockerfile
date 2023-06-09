
FROM jupyter/base-notebook:2023-05-01
# FROM jupyter/base-notebook:python-3.10.10

# Parent image source
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/docker-stacks-foundation/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/base-notebook/Dockerfile

USER root

# Install base image dependancies
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
        # Destop Env
        lxde \
        # Installer tools
        wget \
        curl \
        dirmngr \ 
        gpg \
        gpg-agent \
        software-properties-common \
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
RUN export VERSION=${GO_VERSION} OS=linux ARCH=amd64 \
    && wget https://go.dev/dl/go${VERSION}.${OS}-${ARCH}.tar.gz \
    && sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz \
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

# Add Software sources
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list \
    # Nextcloud Client
    && add-apt-repository ppa:nextcloud-devs/client \
    # Datalad
    && wget -q -O- http://neuro.debian.net/lists/focal.us-nh.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list \
    && apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9 \
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

# Create cvmfs keys
RUN mkdir -p /etc/cvmfs/keys/ardc.edu.au
COPY config/cvmfs/neurodesk.ardc.edu.au.pub /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub
COPY config/cvmfs/neurodesk.ardc.edu.au.conf /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf
COPY config/cvmfs/default.local /etc/cvmfs/default.local
# This causes conflicts with an external cvmfs setup that gets mounted
# RUN cvmfs_config setup

# # Customise logo, wallpaper, terminal, panel
COPY config/jupyter/neurodesk_brain_logo.svg /opt/neurodesk_brain_logo.svg
COPY config/jupyter/neurodesk_brain_icon.svg /opt/neurodesk_brain_icon.svg

COPY config/lxde/background.png /usr/share/lxde/wallpapers/desktop_wallpaper.png
COPY config/lxde/pcmanfm.conf /etc/xdg/pcmanfm/LXDE/pcmanfm.conf
COPY config/lxde/lxterminal.conf /usr/share/lxterminal/lxterminal.conf
COPY config/lxde/panel /home/${NB_USER}/.config/lxpanel/LXDE/panels/panel

COPY config/lmod/module.sh /usr/share/
COPY config/lxde/.bashrc /home/${NB_USER}/tmp_bashrc
RUN cat /home/${NB_USER}/tmp_bashrc >> /home/${NB_USER}/.bashrc \
     && rm /home/${NB_USER}/tmp_bashrc

# Configure tiling of windows SHIFT-ALT-CTR-{Left,right,top,Bottom} and other openbox desktop mods
COPY ./config/lxde/rc.xml /etc/xdg/openbox

# Configure ITKsnap
RUN mkdir -p /home/${NB_USER}/.itksnap.org/ITK-SNAP \
    && chown ${NB_USER} /home/${NB_USER}/.itksnap.org -R
COPY ./config/itksnap/UserPreferences.xml /home/${NB_USER}/.itksnap.org
COPY ./config/lxde/mimeapps.list /home/${NB_USER}/.config/mimeapps.list

# Allow the root user to access the sshfs mount
# https://github.com/NeuroDesk/neurodesk/issues/47
RUN sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Fetch singularity bind mount list and create placeholder mountpoints
RUN mkdir -p `curl https://raw.githubusercontent.com/NeuroDesk/neurocontainers/master/recipes/globalMountPointList.txt`

# Fix "No session for pid prompt"
RUN rm /usr/bin/lxpolkit

## Update conda / this will update pandoc and consume quite a bit of unnessary space
# RUN conda update -n base conda \
#     && conda clean --all -f -y \
#     && rm -rf /home/${NB_USER}/.cache

## Install conda packages
RUN conda install -c conda-forge nipype pip nb_conda_kernels \
    && conda clean --all -f -y \
    && rm -rf /home/${NB_USER}/.cache
RUN conda config --system --prepend envs_dirs '~/conda-environments'

# Setup git
RUN git config --global user.email "user@neurodesk.org" \
    && git config --global user.name "Neurodesk User"

# Setup temp directory for matplotlib (required for fmriprep)
RUN mkdir -p /home/${NB_USER}/.config/matplotlib-mpldir \
    && chmod -R 700 /home/${NB_USER}/.config/matplotlib-mpldir \
    && chown -R ${NB_USER}:users /home/${NB_USER}/.config/matplotlib-mpldir

# enable rootless mounts: 
RUN chmod +x /usr/bin/fusermount

# Create link to persistent storage on Desktop (This needs to happen before the users gets created!)
# This currently doesn't work, because /neurodesktop-storage gets mounted in from outside
# RUN mkdir -p /home/${NB_USER}/neurodesktop-storage/containers \
#     && mkdir -p /home/${NB_USER}/Desktop/ /data \
#     && ln -s /home/${NB_USER}/neurodesktop-storage/ /neurodesktop-storage \
#     && ln -s /neurodesktop-storage /storage

# In kubernetes we later have to put persistent storage to /neurodesktop-storage
RUN mkdir -p /home/${NB_USER}/Desktop/ /data \
    && ln -s /neurodesktop-storage/ /home/${NB_USER} \
    && ln -s /neurodesktop-storage /storage \
    && ln -s /data /home/${NB_USER}

# # Add checkversion script
# COPY ./config/checkversion.sh /usr/share/
# # Add CheckVersion script
# COPY ./config/CheckVersion.desktop /etc/skel/Desktop

COPY config/vscode/settings.json /home/${NB_USER}/.config/Code/User/settings.json

# Add libfm script
RUN mkdir -p /home/${NB_USER}/.config/libfm
COPY ./config/lxde/libfm.conf /home/${NB_USER}/.config/libfm

RUN touch /home/${NB_USER}/.sudo_as_admin_successful

# Add datalad-container datalad-osf osfclient ipyniivue to the conda environment
RUN su ${NB_USER} -c "/opt/conda/bin/pip install datalad-container datalad-osf osfclient ipyniivue" \
    && rm -rf /home/${NB_USER}/.cache

ENV DONT_PROMPT_WSL_INSTALL=1
ENV LMOD_CMD /usr/share/lmod/lmod/libexec/lmod

# Install jupyter-server-proxy and disable announcements
# Depracated: jupyter labextension install ..
RUN su ${NB_USER} -c "/opt/conda/bin/pip install jupyter-server-proxy" \
    && su ${NB_USER} -c "/opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements" \ 
    && su ${NB_USER} -c "/opt/conda/bin/pip install jupyterlmod" \ 
    && rm -rf /home/${NB_USER}/.cache
    
# Add notebook startup scripts
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html
RUN mkdir -p /usr/local/bin/start-notebook.d/ \
    && mkdir -p /usr/local/bin/before-notebook.d/
COPY config/jupyter/start-notebook.sh /usr/local/bin/start-notebook.d/
COPY config/jupyter/before-notebook.sh /usr/local/bin/before-notebook.d/

# Create Guacamole configurations (user-mapping.xml gets filled in the startup.sh script)
RUN mkdir -p /etc/guacamole \
    && echo -e "user-mapping: /etc/guacamole/user-mapping.xml\nguacd-hostname: 127.0.0.1" > /etc/guacamole/guacamole.properties \
    && echo -e "[server]\nbind_host = 127.0.0.1\nbind_port = 4822" > /etc/guacamole/guacd.conf

# Add startup and config files for neurodesktop, jupyter, guacamole, vnc
RUN mkdir /home/${NB_USER}/.vnc \
    && chown ${NB_USER} /home/${NB_USER}/.vnc \
    && /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su ${NB_USER} -c vncpasswd
COPY --chown=${NB_USER}:users config/lxde/xstartup /home/${NB_USER}/.vnc
COPY --chown=${NB_USER}:root config/guacamole/user-mapping.xml /etc/guacamole/user-mapping.xml
COPY --chown=${NB_USER}:users config/guacamole/guacamole.sh /opt/neurodesktop/guacamole.sh
COPY --chown=${NB_USER}:users config/jupyter/environment_variables.sh /opt/neurodesktop/environment_variables.sh
COPY --chown=${NB_USER}:users config/jupyter/jupyter_notebook_config.py /home/${NB_USER}/.jupyter/jupyter_notebook_config.py
COPY --chown=${NB_USER}:users config/ssh/sshd_config /home/${NB_USER}/.ssh/sshd_config
COPY --chown=${NB_USER}:users config/k8s_postStart_copy_homedirectory.sh /tmp/k8s_postStart_copy_homedirectory.sh
COPY --chown=${NB_USER}:users config/conda/conda-readme.md /home/${NB_USER}/
RUN chmod +x /opt/neurodesktop/guacamole.sh \
    /home/${NB_USER}/.jupyter/jupyter_notebook_config.py \
    /home/${NB_USER}/.vnc/xstartup

RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/notebook \
# The following apply to Singleuser mode only. See config/jupyter/before-notebook.sh for Notebook mode
    && /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER} \
    && usermod --shell /bin/bash ${NB_USER}

# Enable deletion of non-empty-directories in JupyterLab: https://github.com/jupyter/notebook/issues/4916
RUN sed -i 's/c.FileContentsManager.delete_to_trash = False/c.FileContentsManager.always_delete_dir = True/g' /etc/jupyter/jupyter_server_config.py

# Copy script to test_containers 
COPY config/test_neurodesktop.sh /usr/share/test_neurodesktop.sh
RUN chmod +x /usr/share/test_neurodesktop.sh

# Install version 1.1.1 of fix_bash.sh that is required for test_containers
RUN git clone https://github.com/civier/fix_bash.git /tmp/fix_bash \
      && cd /tmp/fix_bash \
      && git checkout tags/1.1.1 \
      && cp /tmp/fix_bash/fix_bash.sh /usr/share \
      && rm -Rf /tmp/fix_bash

# Install neurocommand
ADD "https://api.github.com/repos/neurodesk/neurocommand/git/refs/heads/main" /tmp/skipcache
RUN rm /tmp/skipcache \
    && git clone https://github.com/NeuroDesk/neurocommand.git /neurocommand \
    && cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers 

USER ${NB_UID}

WORKDIR "${HOME}"

# Add example notebooks
RUN git clone --depth 1 https://github.com/NeuroDesk/example-notebooks