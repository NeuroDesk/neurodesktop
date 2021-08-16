docker build -t neuromachine:210816 .
docker run -it --privileged -p 8080:8080 neuromachine:210816 -s -v -r