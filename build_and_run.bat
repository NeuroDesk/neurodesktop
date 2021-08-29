docker rm neuromachine
docker build -t neuromachine:latest .
docker run --privileged -ti --name neuromachine -v ~/neuro:/vnm -p 8080:8080 neuromachine:latest 