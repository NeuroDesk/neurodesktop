# syntax=docker/dockerfile:1-labs
FROM jupyter/base-notebook:2023-03-27
# FROM jupyter/base-notebook:python-3.10.9
# FROM jupyter/base-notebook:2023-02-28

# Parent image source
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/docker-stacks-foundation/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/86d42cadf4695b8e6fc3b3ead58e1f71067b765b/base-notebook/Dockerfile

USER root

# Update apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update

# Install base image dependancies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
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
        software-properties-common

ARG GO_VERSION="1.20.2"
ARG SINGULARITY_VERSION="3.11.0"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.73"
ARG GUACAMOLE_VERSION="1.5.0"

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
    && rm -rf /root/.cache

# Install Apache Tomcat
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_REL}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp \
    && tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /tmp \
    && rm -rf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    && mv /tmp/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat \
    && mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps.dist \
    && mkdir /usr/local/tomcat/webapps \
    && chmod +x /usr/local/tomcat/bin/*.sh

# Install Apache Guacamole
RUN wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" -O /usr/local/tomcat/webapps/ROOT.war \
    && wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -P /tmp \
    && tar xvf /tmp/guacamole-server-${GUACAMOLE_VERSION}.tar.gz -C /tmp \
    && rm /tmp/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /tmp/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /tmp/guacamole-server-${GUACAMOLE_VERSION}

# Add Software sources
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    # VS Code
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list \
    # Nextcloud Client
    && add-apt-repository ppa:nextcloud-devs/client \
    # Datalad
    && wget -q -O- http://neuro.debian.net/lists/focal.us-nh.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list \
    && apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9 \
    # NodeJS
    && curl -fsSL https://deb.nodesource.com/setup_19.x | bash -

# Install CVMFS
RUN wget -q https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -P /tmp \
    && dpkg -i /tmp/cvmfs-release-latest_all.deb \
    && rm /tmp/cvmfs-release-latest_all.deb

# Update apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update

# Install Tools and Libs
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        aria2 \
        code \
        cvmfs \
        datalad \
        davfs2 \
        debootstrap \
        emacs \
        g++ \
        gcc \
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
        libssh2-1-dev \
        libxt6 \
        libzstd1 \
        lmod \
        lsb-release \
        lua-bit32 \
        lua-filesystem \
        lua-json \
        lua-lpeg \
        lua-posix \
        lua-term \
        lua5.2 \
        lxrandr \
        lxtask \
        lxterminal \
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
        tree \
        uidmap \
        unzip \
        vim \
        xauth \
        xdg-utils \
        yarn \
        zip \
        zlib1g-dev

# Install firefox
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    add-apt-repository ppa:mozillateam/ppa \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        --target-release 'o=LP-PPA-mozillateam' firefox
COPY config/firefox/mozillateamppa /etc/apt/preferences.d/mozillateamppa
COPY config/firefox/syspref.js /etc/firefox/syspref.js

# Create cvmfs keys
RUN mkdir -p /etc/cvmfs/keys/ardc.edu.au
COPY config/cvmfs/neurodesk.ardc.edu.au.pub /etc/cvmfs/keys/ardc.edu.au/neurodesk.ardc.edu.au.pub
COPY config/cvmfs/neurodesk.ardc.edu.au.conf /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf
COPY config/cvmfs/default.local /etc/cvmfs/default.local
RUN cvmfs_config setup

# # Add Globus client
# RUN mkdir -p /opt/globusconnectpersonal \
#     && cd /opt/globusconnectpersonal \
#     && wget https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz \
#     && tar xzf globusconnectpersonal-latest.tgz \
#     && rm -rf globusconnectpersonal-latest.tgz/

# Add rclone
RUN cd /opt \
    && wget https://downloads.rclone.org/v1.60.1/rclone-v1.60.1-linux-amd64.zip \
    && unzip rclone-v1.60.1-linux-amd64.zip \
    && rm rclone-v1.60.1-linux-amd64.zip \
    && ln -s /opt/rclone-v1.60.1-linux-amd64/rclone /usr/bin/rclone
COPY --chown=${NB_USER}:users config/rclone/rclone.conf /home/${NB_USER}/.config/rclone/rclone.conf

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
COPY --chown=${NB_USER}:users config/ssh/sshd_config /home/${NB_USER}/.ssh/sshd_config
# Allow the root user to access the sshfs mount
# https://github.com/NeuroDesk/neurodesk/issues/47
RUN sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf

# Fetch singularity bind mount list and create placeholder mountpoints
RUN mkdir -p `curl https://raw.githubusercontent.com/NeuroDesk/neurocontainers/master/recipes/globalMountPointList.txt`

# Fix "No session for pid prompt"
RUN rm /usr/bin/lxpolkit

# RUN wget -O /tmp/Firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64" \
#     && tar xjf /tmp/Firefox.tar.bz2 -C /opt/ \
#     && rm /tmp/Firefox.tar.bz2 \
#     && ln -s /opt/firefox/firefox /usr/bin/

# # Change firefox home
# RUN echo 'pref("browser.startup.homepage", "https://www.neurodesk.org", locked);' >> /etc/firefox/syspref.js \
#     && echo 'pref("browser.startup.firstrunSkipsHomepage", true, locked);' >> /etc/firefox/syspref.js \
#     && echo 'pref("startup.homepage_welcome_url", "https://www.neurodesk.org", locked);' >> /etc/firefox/syspref.js \
#     && echo 'pref("browser.aboutwelcome.enabled", true, locked);' >> /etc/firefox/syspref.js

# # Install xpra
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#     --mount=type=cache,target=/var/lib/apt,sharing=locked \
#     wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/gpg.asc \
#     && cd /etc/apt/sources.list.d;wget https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/jammy/xpra.sources \
#     && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
#         xpra

# ## Update conda
# RUN conda update -n base conda \
#     && conda clean --all -f -y \
#     && rm -rf /home/${NB_USER}/.cache

# ## Install conda packages
# RUN conda install -c conda-forge nipype pip nb_conda_kernels \
#     && conda clean --all -f -y \
#     && rm -rf /home/${NB_USER}/.cache
# RUN conda config --system --prepend envs_dirs '~/conda-environments'

# RUN mkdir .ssh \
#     && touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys \
#     && touch .ssh/config && chmod 600 .ssh/config \
#     && printf "Host localhost\n  Port 2222\n" >> .ssh/config \
#     && chmod -R 700 .ssh && chown -R ${NB_USER}:users .ssh

# Setup git
RUN git config --global user.email "user@neurodesk.org" \
    && git config --global user.name "Neurodesk User"

# Setup temp directory for matplotlib (required for fmriprep)
RUN mkdir -p /home/${NB_USER}/.config/matplotlib-mpldir \
    && chmod -R 700 /home/${NB_USER}/.config/matplotlib-mpldir \
    && chown -R ${NB_USER}:users /home/${NB_USER}/.config/matplotlib-mpldir
ENV MPLCONFIGDIR /home/${NB_USER}/.config/matplotlib-mpldir

# enable rootless mounts: 
RUN chmod +x /usr/bin/fusermount

# Create link to persistent storage on Desktop (This needs to happen before the users gets created!)
RUN mkdir -p /home/${NB_USER}/neurodesktop-storage/containers \
    && mkdir -p /home/${NB_USER}/Desktop/ /data \
    && ln -s /home/${NB_USER}/neurodesktop-storage/ /neurodesktop-storage \
    && ln -s /neurodesktop-storage /storage

# # Add checkversion script
# COPY ./config/checkversion.sh /usr/share/
# # Add CheckVersion script
# COPY ./config/CheckVersion.desktop /etc/skel/Desktop

COPY config/vscode/settings.json /home/${NB_USER}/.config/Code/User/settings.json

# Add libfm script
RUN mkdir -p /home/${NB_USER}/.config/libfm
COPY ./config/lxde/libfm.conf /home/${NB_USER}/.config/libfm

RUN touch /home/${NB_USER}/.sudo_as_admin_successful

# Add datalad-container datalad-osf and osfclient to the conda environment
RUN pip install datalad-container datalad-osf osfclient

ENV DONT_PROMPT_WSL_INSTALL=1
ENV PATH=$PATH:/home/${NB_USER}/.local/bin
ENV SINGULARITY_BINDPATH /data
ENV LMOD_CMD /usr/share/lmod/lmod/libexec/lmod
ENV MODULEPATH /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/molecular_biology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/workflows:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/visualization:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/structural_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/statistics:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spine:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spectroscopy:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/shape_analysis:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/rodent_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quantitative_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quality_control:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/programming:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/phase_processing:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/machine_learning:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_registration:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_reconstruction:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/hippocampus:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/functional_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/electrophysiology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/diffusion_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/data_organisation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/body

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
COPY --chown=${NB_USER}:users config/xpra/xpra.sh /opt/neurodesktop/xpra.sh
COPY --chown=${NB_USER}:users config/jupyter/jupyter_notebook_config.py /home/${NB_USER}/.jupyter/jupyter_notebook_config.py
RUN chmod +x /opt/neurodesktop/guacamole.sh /opt/neurodesktop/xpra.sh \
    /home/${NB_USER}/.jupyter/jupyter_notebook_config.py \
    /home/${NB_USER}/.vnc/xstartup

RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/notebook \
# The following apply to Singleuser mode only. See config/jupyter/before-notebook.sh for Notebook mode
    && /usr/bin/printf '%s\n%s\n' 'password' 'password' | passwd ${NB_USER} \
    && usermod --shell /bin/bash ${NB_USER}

# Install neurocommand
ADD --keep-git-dir=true https://github.com/NeuroDesk/neurocommand.git /neurocommand
RUN cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers

# # # Temporary fix. Pushing select apps onto XNeurodesk menu
# # RUN find /usr/share/applications/neurodesk/ -type f -name 'fsl*.desktop' -exec sed -i 's/Terminal=true/Terminal=false/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name 'fsl*.desktop' -exec sed -i 's/Exec=\(.*\)/Exec=lxterminal --command="\1"/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name 'freesurfer*.desktop' -exec sed -i 's/Terminal=true/Terminal=false/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name 'freesurfer*.desktop' -exec sed -i 's/Exec=\(.*\)/Exec=lxterminal --command="\1"/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name '3dslicer*.desktop' -exec sed -i 's/Terminal=true/Terminal=false/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name '3dslicer*.desktop' -exec sed -i 's/Exec=\(.*\)/Exec=lxterminal --command="\1"/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name 'itksnap*.desktop' -exec sed -i 's/Terminal=true/Terminal=false/g' {} \; \
# #     && find /usr/share/applications/neurodesk/ -type f -name 'itksnap*.desktop' -exec sed -i 's/Exec=\(.*\)/Exec=lxterminal --command="\1"/g' {} \;

USER ${NB_UID}

WORKDIR "${HOME}"

# CMD ["/bin/bash"]
# ## Possible requirements
# # xorg \
# # python3 \
# # python3-annexremote \
# # python3-pip \
# # firefox \
# # cryptsetup-bin\
# # dbus-x11 \
