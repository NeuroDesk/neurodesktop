set -e


docker build . -t neurodesktop:latest
dive neurodesktop --ci > wasted_space.txt
dive neurodesktop 

rm wasted_space.txt