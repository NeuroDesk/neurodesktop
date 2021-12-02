#!/bin/bash
#Tom Shaw 20211201
#Check for Docker, open explorer if not and open docker download page
#start the container and wait for the website to be available.
#function:
function countdown() {
    date1=$(($(date +%s) + $1))
    while [ "$date1" -ge $(date +%s) ]; do
        echo -ne "$(date -u --date @$(($date1 - $(date +%s))) +%H:%M:%S)\r"
        sleep 0.1
    done
}

  YUM_CMD=$(which yum)
  APT_GET_CMD=$(which apt-get)
  APT_CMD=$(which apt)
  APK_CMD=$(which apk)
  DNF_CMD=$(which dnf)
  PACMAN_CMD=$(which pacman)

if [[ ! -z $YUM_CMD ]]; then
    yum install $YUM_PACKAGE_NAME
elif [[ ! -z $APT_GET_CMD ]]; then
    apt-get $DEB_PACKAGE_NAME
elif [[ ! -z $APT_CMD ]]; then
elif [[ ! -z $APT_CMD ]]; then
elif [[ ! -z $APT_CMD ]]; then
elif [[ ! -z $APT_CMD ]]; then
    $OTHER_CMD <proper arguments>
 else
    echo "error can't install package $PACKAGE"
    exit 1;
 fi

#first install xdg-tools
# Check Os
#apt-get install xdg-utils
# Ubuntu
#apt-get install xdg-utils
# Alpine

#apk search pkgName  apk search -v -d 'xdg-utils'
#apk add xdg-utils


# Arch Linux
#pacman -Qs xdg-utils
#pacman -S xdg-utils


# Kali Linux
#apt-get install xdg-utils


# CentOS
#yum install xdg-utils
#yum list installed | grep xdg-utils

# Fedora
#dnf install xdg-utils
#dnf list installed "xdg-utils"

# Raspbian
#apt-get install xdg-utils
# package the file into a .desktop file like so
#https://www.maketecheasier.com/create-desktop-file-linux/
REQUIRED_PKG="xdg-utils"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
echo "Checking for $REQUIRED_PKG: $PKG_OK"
if [ "" = "$PKG_OK" ]; then
    echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
    sudo apt --yes install $REQUIRED_PKG
fi

echo "Checking if Docker is installed"
if ! docker info >/dev/null 2>&1; then
    echo "This script uses docker, and it isn't running - please start docker and try again!"
    echo "--------------------------------------------------------------"
    echo "Or if, you haven't installed docker:"
    echo "Please follow the instruction to download and install Docker:"
    echo "---------------------------------------------------------------"
    xdg-open "https://docs.docker.com/engine/install/"
    echo "press any key to quit, then try again once Docker is installed and runningPress any key to continue"
    while [ true ]; do
        read -t 3 -n 1
        if [ $? = 0 ]; then
            exit
        else
            echo "waiting for the keypress"
        fi
    done
else
    echo "Starting NeuroDesktop:"
    echo "Remove old versions of NeuroDesktop"
    echo "If none are available the daemon will throw an error which can be safely ignored:"
    echo "Checking if the following container is available:"
    docker stop neurodesktop
    echo "Checking if the following container is available:"
    docker rm neurodesktop
    echo "--------------------------------------------------------------"
    echo "Starting NeuroDesktop, please wait..."
    echo "You may be asked to enter your password to run the Docker container"
    echo "--------------------------------------------------------------"
    echo "running command: sudo docker run --shm-size=1gb -it -d --privileged --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 -h neurodesktop-20211028 vnmd/neurodesktop:20211028"
    mkdir -p ~/neurodesktop-storage
    #note this is in disconnected mode
    sudo docker run \
        --shm-size=1gb -it -d --privileged --name neurodesktop \
        -v ~/neurodesktop-storage:/neurodesktop-storage \
        -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
        -p 8080:8080 -h neurodesktop-20211028 \
        vnmd/neurodesktop:20211028

    #poll for the guac server using curl  curl http://localhost:8080
    # possible responses while booting are curl: (52) Empty reply from server
    # if running it will say <!DOCTYPE html>
    # if not started it will say curl: (7) Failed to connect to localhost port 8080: Connection refused

    until curl http://localhost:8080 >/dev/null 2>&1; do
        echo "--------------------------------------------------------------"
        echo "Waiting for Neurodesk, please wait and your browser will open shortly"
        echo "--------------------------------------------------------------"
        echo "Checking every 5 seconds. "
        echo "If this takes longer than 10 mins please try restarting Docker or check your internet connection"
        countdown 5
    done

    echo "Docker started, opening session"
    xdg-open "http://localhost:8080/#/?username=user&password=password"
    echo "NeuroDesktop is running - press ANY key to shutdown and quit NeuroDesktop!"
    while [ true ]; do
        read -n 1
        if [ $? = 0 ]; then
            echo "The following container has been stopped:"
            docker stop neurodesktop
            echo "The following container has been removed:"
            docker rm neurodesktop
            exit 0
        else
            echo "Waiting for the keypress"
        fi
    done
fi
exit
