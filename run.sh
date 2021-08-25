# docker run -d --name neuromachine -p 8080:8080 -v ~/vnm:/vnm aswinnarayanan/neuromachine:latest
docker rm neuromachine
docker run --privileged -ti --name neuromachine -v ~/neuro:/vnm -p 8080:8080 aswinnarayanan/neuromachine:latest 