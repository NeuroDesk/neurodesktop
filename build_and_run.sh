docker build -t neuromachine:latest .
docker run --shm-size=1gb -it --privileged --name neuromachine -v ~/neurodesktop:/neurodesktop -e USER=user -p 8080:8080 neuromachine:latest