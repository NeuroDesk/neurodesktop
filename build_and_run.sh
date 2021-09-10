bash stop.sh
docker build -t neuromachine:latest .
mkdir -p ~/neurodesktop
# docker run --shm-size=1gb -it --privileged --name neuromachine -v ~/neurodesktop:/neurodesktop -e USER=user --user 1000:100 -p 8080:8080 neuromachine:latest

# docker run --shm-size=1gb -it --privileged --name neuromachine -v ~/neurodesktop:/neurodesktop -e USER=user -e UID="$(id -u)" -e GID="$(id -g)"  -u `id -u $USER` -p 8080:8080 neuromachine:latest

docker run --shm-size=1gb -it --privileged --name neuromachine -v ~/neurodesktop:/neurodesktop -e USER=user -e UID="$(id -u)" -e GID="$(id -g)" -p 8080:8080 neuromachine:latest
