docker stop neurodesktop
docker rm neurodesktop
docker build -t neurodesktop:latest .
docker run --shm-size=1gb -it --privileged --name neurodesktop -v C:/neurodesktop-storage:/neurodesktop-storage -e USER=user -p 8080:8080 neurodesktop:latest
@REM docker run --shm-size=1gb -it --privileged --name neurodesktop -v C:/neurodesktop-storage:/neurodesktop-storage -e USER=user -e CVMFS_DISABLE=true -p 8080:8080 neurodesktop:latest
