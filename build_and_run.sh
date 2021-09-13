bash stop.sh
docker build -t neurodesktop:latest .
docker run --shm-size=1gb -it --privileged --name neurodesktop -v ~/neurodesktop:/neurodesktop -e USER=user -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 neurodesktop:latest
