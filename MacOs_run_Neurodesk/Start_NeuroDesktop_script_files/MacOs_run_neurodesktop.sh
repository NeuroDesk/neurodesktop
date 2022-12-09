#!/bin/bash
#Tom Shaw 20211201
#Check for Docker, open explorer if not and open docker download page
#start the container and wait for the website to be available. 

function countdown(){  
    local now=$(date +%s)
    local end=$((now + $1))
    while (( now < end )); do   
        printf "%s\r" "$(date -u -j -f %s $((end - now)) +%T)"
        sleep 0.25  
        now=$(date +%s)
    done  
    echo
}

echo "Checking if Docker is installed" 
if ! docker ps > /dev/null 2>&1; then
    echo "This script uses docker, and it isn't running - please start docker and try again!"
    echo "--------------------------------------------------------------"
    echo "Or if, you haven't installed docker:"
    echo "Please follow the instruction to download and install Docker:"
    echo "---------------------------------------------------------------"
    open "https://docs.docker.com/engine/install/"
    echo "press any key to quit, then try again once Docker is installed and runningPress any key to continue"
    while [ true ] ; do
        read -t 3 -n 1
        if [ $? = 0 ] ; then
            exit ;
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
    echo "--------------------------------------------------------------"
    #note this is in disconnected mode
    docker pull vnmd/neurodesktop:latest
    docker run -d --shm-size=1gb -it --privileged --name neurodesktop \
    -v ~/Desktop/neurodesktop-storage:/neurodesktop-storage \
    -p 8080:8080 -h neurodesktop-latest vnmd/neurodesktop:latest

    #poll for the guac server using curl  curl http://localhost:8080
    # possible responses while booting are curl: (52) Empty reply from server
    # if running it will say <!DOCTYPE html>
    # if not started it will say curl: (7) Failed to connect to localhost port 8080: Connection refused

until curl http://localhost:8080 >/dev/null 2>&1 
do
echo "--------------------------------------------------------------"
echo "Waiting for Neurodesk, please wait and your browser will open shortly"
echo "--------------------------------------------------------------"
echo "Checking every 5 seconds"
echo "If this takes longer than 10 mins please try restarting Docker or check your internet connection"
countdown 5
done
clear
echo "Docker started, opening session"
open -a Safari "http://localhost:8080/#/?username=user&password=password"
echo "#######################################################################################"
echo "░██╗░░░░░░░██╗███████╗██╗░░░░░░█████╗░░█████╗░███╗░░░███╗███████╗  ████████╗░█████╗░"
echo "░██║░░██╗░░██║██╔════╝██║░░░░░██╔══██╗██╔══██╗████╗░████║██╔════╝  ╚══██╔══╝██╔══██╗"
echo "░╚██╗████╗██╔╝█████╗░░██║░░░░░██║░░╚═╝██║░░██║██╔████╔██║█████╗░░  ░░░██║░░░██║░░██║"
echo "░░████╔═████║░██╔══╝░░██║░░░░░██║░░██╗██║░░██║██║╚██╔╝██║██╔══╝░░  ░░░██║░░░██║░░██║"
echo "░░╚██╔╝░╚██╔╝░███████╗███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║███████╗  ░░░██║░░░╚█████╔╝"
echo "░░░╚═╝░░░╚═╝░░╚══════╝╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚══════╝  ░░░╚═╝░░░░╚════╝░"
echo ""
echo "███╗░░██╗███████╗██╗░░░██╗██████╗░░█████╗░██████╗░███████╗░██████╗██╗░░██╗"
echo "████╗░██║██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██║░██╔╝"
echo "██╔██╗██║█████╗░░██║░░░██║██████╔╝██║░░██║██║░░██║█████╗░░╚█████╗░█████═╝░"
echo "██║╚████║██╔══╝░░██║░░░██║██╔══██╗██║░░██║██║░░██║██╔══╝░░░╚═══██╗██╔═██╗░"
echo "██║░╚███║███████╗╚██████╔╝██║░░██║╚█████╔╝██████╔╝███████╗██████╔╝██║░╚██╗"
echo "╚═╝░░╚══╝╚══════╝░╚═════╝░╚═╝░░╚═╝░╚════╝░╚═════╝░╚══════╝╚═════╝░╚═╝░░╚═╝"
echo "#######################################################################################"
echo "NeuroDesktop is running - press ANY key to shutdown and quit NeuroDesktop!"
while [ true ] ; do
    read -n 1
    if [ $? = 0 ] ; then
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
