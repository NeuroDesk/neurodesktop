bash stop_and_clean.sh
docker build -t neurodesktop:latest .
docker run --shm-size=1gb -it --privileged --name neurodesktop -v ~/neurodesktop:/neurodesktop -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -p 8080:8080 neurodesktop:latest
# -e CVMFS_DISABLE=true # will disable CVMFS for testing purposes