set -e

if docker ps --all | grep neurodesktop; then
    bash stop_and_clean.sh
fi
# docker build -t neurodesktop:latest .
# docker run --shm-size=1gb -it --privileged --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 neurodesktop:latest
# -e CVMFS_DISABLE=true # will disable CVMFS for testing purposes

docker build . -t neurodesktop:latest

docker run --shm-size=1gb -it --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
    --device=/dev/fuse --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage \
    -v /cvmfs:/cvmfs -p 8888:8888 \
    --user=root -e NB_UID="$(id -u)" -e NB_GID="$(id -g)" -e GRANT_SUDO=yes \
    neurodesktop:latest
