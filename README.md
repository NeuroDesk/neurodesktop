_Further information available at [neurodesk.github.io](https://neurodesk.github.io)_

# Neuromachine

A compact Docker container with a browser-accessible environment for reproducible neuroimaging analysis. Only the required applications, already pre-installed, are downloaded from a public library (downloaded as containers).

## Minimum System Requirements
1. Atleast 3GB free space for neuromachine base image
2. Docker requirements. Details found under https://docs.docker.com/get-docker/
3. (Windows Users) If installing docker using WSL, atleast 20GB space recommended for WSL with Ubuntu

## Quickstart
1. Install Docker from here: https://docs.docker.com/get-docker/ (Mac, Windows, Linux; for HPC/supercomputer: https://github.com/NeuroDesk/neurodesk)

2. Create a local folder where the downloaded applications will be stored, e.g. ~/vnm in Mac and Linux, or C:\vnm in Windows 

3. Open a terminal, and type the folowing command to automatically download the neuromachine container and run it (Mac, Windows, Linux commands listed below) 

* Mac:
```
docker run -it --privileged --name neuromachine -v ~/vnm:/vnm -e USER=user -p 8080:8080 vnmd/neuromachine:20210825
```
(notice: There is a bug in docker 3.3.0 for Mac that makes this command not run correctly and there will be no application menu when you start the desktop. Update your docker version when you see this!)

* Windows:
```
docker run -it --privileged --name neuromachine -v C:/vnm:/vnm -e USER=user -p 8080:8080 vnmd/neuromachine:20210825
```
* Linux:
```
sudo docker run -it --privileged --name neuromachine -v ~/vnm:/vnm -v /dev/shm:/dev/shm -e USER=user -p 8080:8080 vnmd/neuromachine:20210825
```
(notice: if you get errors in neuromachine then check if the ~/vnm directory is writable to all users, otherwise run `chmod a+rwx ~/vnm`)

4. Once neuromachine is downloaded i.e. `guacd[77]: INFO:        Listening on host 127.0.0.1, port 4822` is displayed in terminal, open a browser and go to:
```
http://localhost:8080
```
or open a VNC Client and connect to port 5901 (for this -p 5901:5901 has to be added to the docker call)

5. neuromachine is ready to use!
- User is `user`
- Password is `password`

## Stopping neuromachine:
When done processing your data it is important to stop and remove the container - otherwise the next start or container update will give an error ("... The container name "/neuromachine" is already in use...")
1. Click on the terminal from which you ran neuromachine

2. Press control-C

3. Type:
```
docker stop neuromachine
```
4. Type:
```
docker rm neuromachine
```
