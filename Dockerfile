# FROM jupyter/base-notebook:2023-02-28
# FROM jupyter/base-notebook:python-3.10.9
FROM jupyter/base-notebook:notebook-6.5.3

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
        libpng-dev \
        libjpeg-turbo8-dev \
        libcairo2-dev \
        libtool-bin \
        libossp-uuid-dev \
        libwebp-dev \
        lxde \
        libssl-dev \
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
        openjdk-19-jre \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /home/jovyan/.cache

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        build-essential \
        libseccomp-dev \
        libglib2.0-dev \
        pkg-config \
        squashfs-tools \
        cryptsetup \
        runc

# openjdk-11-jre \
# openssh-server \
# libpango1.0-dev \
# libssh2-1-dev \
# openssh-server \

ARG GO_VERSION="1.20.2"
ARG SINGULARITY_VERSION="3.11.0"
ARG TOMCAT_REL="9"
ARG TOMCAT_VERSION="9.0.73"
ARG GUACAMOLE_VERSION="1.5.0"
ARG JULIA_VERSION="1.8.3"

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
WORKDIR /etc/guacamole
RUN wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war" -O /usr/local/tomcat/webapps/ROOT.war \
    && wget -q "https://dlcdn.apache.org/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz" -O /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && tar xvf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && rm -rf /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}.tar.gz \
    && cd /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && rm -r /etc/guacamole/guacamole-server-${GUACAMOLE_VERSION}*

# Create Guacamole configurations (user-mapping.xml gets filled in the startup.sh script)
RUN echo -e "user-mapping: /etc/guacamole/user-mapping.xml\nguacd-hostname: 127.0.0.1" > /etc/guacamole/guacamole.properties
RUN echo -e "[server]\nbind_host = 127.0.0.1\nbind_port = 4822" > /etc/guacamole/guacd.conf

# Add CVMFS
RUN wget -q https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -O /tmp/cvmfs-release-latest_all.deb \
    && dpkg -i /tmp/cvmfs-release-latest_all.deb \
    && rm /tmp/cvmfs-release-latest_all.deb

# Add Visual Studio code and nextcloud client
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list \
    && add-apt-repository ppa:nextcloud-devs/client

# Add datalad
RUN wget -q -O- http://neuro.debian.net/lists/focal.us-nh.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9

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
    && echo 'CVMFS_SERVER_URL="http://cvmfs.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-phoenix.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-perth.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-ashburn.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-zurich.neurodesk.org/cvmfs/@fqrn@;http://cvmfs-sydney.neurodesk.org/cvmfs/@fqrn@"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
    && echo 'CVMFS_KEYS_DIR="/etc/cvmfs/keys/ardc.edu.au/"' | sudo tee -a /etc/cvmfs/config.d/neurodesk.ardc.edu.au.conf \
    && echo "CVMFS_HTTP_PROXY=DIRECT" | sudo tee  /etc/cvmfs/default.local \
    && echo "CVMFS_QUOTA_LIMIT=5000" | sudo tee -a  /etc/cvmfs/default.local \
    && cvmfs_config setup

# Install jupyter-server-proxy and disable announcements
RUN rm -rf /home/jovyan/.cache \
    && su jovyan -c "/opt/conda/bin/pip install jupyter-server-proxy" \
    && su jovyan -c "/opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements"

# # Install plugins and pip packages
# RUN su jovyan -c "/opt/conda/bin/pip install jupyter-server-proxy" \
#     su jovyan -c "/opt/conda/bin/jupyter labextension disable @jupyterlab/apputils-extension:announcements" \
#     && rm -rf /home/jovyan/.cache

# Customise logo, wallpaper, terminal, panel
COPY config/neurodesk_brain_logo.svg /opt/neurodesk_brain_logo.svg
COPY config/background.png /usr/share/lxde/wallpapers/desktop_wallpaper.png
COPY config/pcmanfm.conf /etc/xdg/pcmanfm/LXDE/pcmanfm.conf
COPY config/lxterminal.conf /usr/share/lxterminal/lxterminal.conf
COPY config/panel /home/jovyan/.config/lxpanel/LXDE/panels/panel

COPY config/module.sh /usr/share/
COPY config/.bashrc /home/jovyan/tmp_bashrc
RUN cat /home/jovyan/tmp_bashrc >> /home/jovyan/.bashrc && rm /home/jovyan/tmp_bashrc

RUN rm -rf /home/jovyan/.cache \
    && su jovyan -c "/opt/conda/bin/pip install jupyterlmod"

# Create link to persistent storage on Desktop (This needs to happen before the users gets created!)
RUN mkdir -p /home/jovyan/neurodesktop-storage/containers \
    && mkdir -p /home/jovyan/Desktop/ /data \
    && chown -R jovyan:users /home/jovyan/Desktop/ \
    && chown -R jovyan:users /home/jovyan/neurodesktop-storage/ \
    && ln -s /home/jovyan/neurodesktop-storage/ /neurodesktop-storage


# RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y cvmfs
    
# Add notebook startup scripts
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html
RUN mkdir -p /usr/local/bin/start-notebook.d/ \
    && mkdir -p /usr/local/bin/before-notebook.d/
COPY config/before-start.sh /usr/local/bin/start-notebook.d/
COPY config/after-start.sh /usr/local/bin/before-notebook.d/

# Install xpra
RUN wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/gpg.asc
RUN cd /etc/apt/sources.list.d;wget https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/jammy/xpra.sources
RUN apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      xpra
      
# Add startup and config files for neurodesktop, jupyter, guacamole, vnc
RUN mkdir /home/jovyan/.vnc \
    && chown jovyan /home/jovyan/.vnc \
    && /usr/bin/printf '%s\n%s\n%s\n' 'password' 'password' 'n' | su jovyan -c vncpasswd
COPY --chown=jovyan:users config/xstartup /home/jovyan/.vnc
COPY --chown=jovyan:users config/guacamole.sh /opt/neurodesktop/guacamole.sh
COPY --chown=jovyan:users config/xpra.sh /opt/neurodesktop/xpra.sh
COPY --chown=jovyan:users config/jupyter_notebook_config.py /home/jovyan/.jupyter/jupyter_notebook_config.py
COPY --chown=jovyan:root config/user-mapping.xml /etc/guacamole/user-mapping.xml
RUN chmod +x /opt/neurodesktop/guacamole.sh /opt/neurodesktop/xpra.sh \
    /home/jovyan/.jupyter/jupyter_notebook_config.py \
    /home/jovyan/.vnc/xstartup

ENV SINGULARITY_BINDPATH /data
ENV LMOD_CMD /usr/share/lmod/lmod/libexec/lmod
ENV MODULEPATH /cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/molecular_biology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/workflows:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/visualization:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/structural_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/statistics:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spine:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/spectroscopy:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/shape_analysis:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/rodent_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quantitative_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/quality_control:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/programming:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/phase_processing:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/machine_learning:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_segmentation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_registration:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/image_reconstruction:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/hippocampus:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/functional_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/electrophysiology:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/diffusion_imaging:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/data_organisation:/cvmfs/neurodesk.ardc.edu.au/neurodesk-modules/body

# Install neurocommand
ADD "http://api.github.com/repos/NeuroDesk/neurocommand/commits/main" /tmp/skipcache
RUN rm /tmp/skipcache \
    && git clone https://github.com/NeuroDesk/neurocommand.git /neurocommand \
    && cd /neurocommand \
    && bash build.sh --lxde --edit \
    && bash install.sh \
    && ln -s /neurodesktop-storage/containers /neurocommand/local/containers

RUN echo "jovyan ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/notebook

RUN /usr/bin/printf '%s\n%s\n' 'password' 'password' | sudo passwd jovyan

USER ${NB_UID}

WORKDIR "${HOME}"
