set -e

if docker ps --all | grep neurodesktop; then
    if docker ps --all | grep neurodeskapp; then
        echo "detected a Neurodeskapp container and ignoring it!"
    else
        bash stop_and_clean.sh
    fi
fi
# docker build -t neurodesktop:latest .
# docker run --shm-size=1gb -it --privileged --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 neurodesktop:latest
# -e CVMFS_DISABLE=true # will disable CVMFS for testing purposes

docker build . -t neurodesktop:latest

# Test with internal CVMFS
# docker run --shm-size=1gb -it --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
#     --device=/dev/fuse --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage \
#     -p 8888:8888 \
#     --user=root -e NB_UID="$(id -u)" -e NB_GID="$(id -g)" \
#     neurodesktop:latest

# Test with persistent home directory
docker volume create neurodesk-home
docker run --shm-size=1gb -it --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
    --device=/dev/fuse --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage \
    --mount source=neurodesk-home,target=/home/jovyan \
    -p 8888:8888 \
    --user=root -e NB_UID="$(id -u)" -e NB_GID="$(id -g)" \
    neurodesktop:latest

# Run with external CVMFS:
# docker run --shm-size=1gb -it --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
#     --device=/dev/fuse --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage \
#     -v /cvmfs:/cvmfs -p 8888:8888 \
#     --user=root -e NB_UID="$(id -u)" -e NB_GID="$(id -g)" \
#     neurodesktop:latest

# launch with custom token
# docker run --shm-size=1gb -it --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
#     --device=/dev/fuse --name neurodesktop -v ~/neurodesktop-storage:/neurodesktop-storage \
#     --mount source=neurodesk-home,target=/home/jovyan \
#     -p 8888:8888 \
#     --user=root -e NB_UID="$(id -u)" -e NB_GID="$(id -g)" \
#     neurodesktop:latest start.sh jupyter lab --ServerApp.password="" --no-browser --expose-app-in-browser --ServerApp.token="jlab:srvr:123" --ServerApp.port=33163 --LabApp.quit_button=False
