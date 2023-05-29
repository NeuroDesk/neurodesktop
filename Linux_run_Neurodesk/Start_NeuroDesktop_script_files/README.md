# How to build .run file for Linux
1) first edit the shell script to update the version variable
2) then 

``` 
git clone https://github.com/megastep/makeself.git ;
cd makeself && git submodule update --init --recursive ;
make #make sure to set Linebreaks correctly in shell scripts!
```

3)

``` 
bash makeself.sh ../../../Linux_run_Neurodesk/ ../../NeuroDesktop.run \
 "NeuroDesktop start script" \
 ./Start_NeuroDesktop_script_files/Linux_run_neurodesktop.sh 
 ```
