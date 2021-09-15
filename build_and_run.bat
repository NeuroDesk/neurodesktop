docker stop neurodesktop
docker rm neurodesktop
docker build -t neurodesktop:latest .
docker run --shm-size=1gb -it --privileged --name neurodesktop -v C:/neurodesktop:/neurodesktop -e USER=user -p 8080:8080 neurodesktop:latest
