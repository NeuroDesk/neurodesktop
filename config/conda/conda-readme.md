We use nb_conda_kernels to enable users to create their own conda environments. To create a new environment for use in jupyter it is important that it contains a kernel package (e.g. ipykernel for Python)

```
#create a python environment:
mamba create -n myenv ipykernel
#OR
conda create -n myenv ipykernel
```

```
#create R environment:
mamba create -n r_env r-irkernel
#OR
conda create -n r_env r-irkernel
```