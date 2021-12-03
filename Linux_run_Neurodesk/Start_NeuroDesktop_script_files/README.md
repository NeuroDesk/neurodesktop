# How to build .run file for Linux
## first edit the shell script
## then 
git clone https://github.com/megastep/makeself.git 
cd makeself
git submodule update --init --recursive
make

bash makeself.sh ../Linux_run_Neurodesk/ NeuroDesktop.run "NeuroDesktop start script" ./Linux_run_neurodesktop.sh

cp NeuroDesktop.run ../Linux_run_Neurodesk/
