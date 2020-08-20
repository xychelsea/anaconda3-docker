# Anaconda 3 Environment for GPU-enabled Docker container

Provides an [NVIDIA GPU-enabled](https://hub.docker.com/r/nvidia/cuda) container with a lightweight (Miniconda) [Anaconda](https://anaconda.com/) installation. Anaconda is an open data science platform based on Python 3. This container installs Anaconda into the ```/usr/local/anaconda``` directory. The default user, ```anaconda``` runs a [Tini shell](https://github.com/krallin/tini/) ```/usr/bin/tini```, and comes preloaded with the ```conda``` command in the environment ```$PATH```. Additional versions with [NVIDIA/CUDA](https://hub.docker.com/r/nvidia/cuda/) support and [Jupyter Notebooks](https://jupyter.org/) tags are available.

Anaconda 3 with conda-forge
-----

This container enables the ```conda``` command with a lightweight version of Anaconda (Miniconda) and the ```conda-forge``` [repository](https://conda-forge.org/) in the ```/usr/local/anaconda``` directory. The default user, ```anaconda``` runs a [Tini shell](https://github.com/krallin/tini/) ```/usr/bin/tini```, and comes preloaded with the ```conda``` command in the environment ```$PATH```. Additional versions with [NVIDIA/CUDA](https://hub.docker.com/r/nvidia/cuda/) support and [Jupyter Notebooks](https://jupyter.org/) tags are available.

### NVIDIA/CUDA GPU-enabled Containers

Two flavors provide an [NVIDIA GPU-enabled](https://hub.docker.com/r/nvidia/cuda) container with [Anaconda](https://anaconda.com/).

## Getting the containers

### Vanilla Anaconda

The base container, based on the ```ubuntu:latest``` from [Ubuntu](https://hub.docker.com/_/ubuntu/) running a Tini shell. For the container with a ```/usr/bin/tini``` entry point, use:

```bash
docker pull xychelsea/anaconda3:latest
```

With Jupyter Notebooks server pre-installed, pull with:

```bash
docker pull xychelsea/anaconda3:latest-jupyter
```

### Anaconda with NVIDIA/CUDA GPU support

Modified version of ```nvidia/cuda:latest``` container, with support for NVIDIA/CUDA graphical processing units through the Tini shell. For the container with a ```/usr/bin/tini``` entry point:

```bash
docker pull xychelsea/anaconda3:latest-gpu
```

With Jupyter Notebooks server pre-installed, pull with:

```bash
docker pull xychelsea/anaconda3:latest-gpu-jupyter
```

## Running the containers

To run the containers with the generic Docker application or NVIDIA enabled Docker, use the ```docker run``` command.

### Vanilla Anaconda

```bash
docker run --rm -it xychelsea/anaconda3:latest
```

With Jupyter Notebooks server pre-installed, run with:

```bash
docker run --rm -it -d -p 8888:8888 xychelsea/anaconda:latest-jupyter
```
### Anaconda with NVIDIA/CUDA GPU support

```bash
docker run --gpus all --rm -it xychelsea/anaconda:latest-gpu /bin/bash
```

With Jupyter Notebooks server pre-installed, run with:

```bash
docker run --gpus all --rm -it -d -p 8888:8888 xychelsea/magenta:latest-gpu-jupyter
```

## Building the containers

To build either a GPU-enabled container or without GPUs, use the [xychelsea/anaconda3-docker](https://github.com/xychelsea/anaconda3-docker) GitHub repository.

```bash
git clone git://github.com/xychelsea/anaconda3-docker.git
```

### Vanilla Magenta

The base container, based on the ```ubuntu:latest``` from [Ubuntu](https://hub.docker.com/_/ubuntu/) running Tini shell:

```bash
docker build -t anaconda3:latest -f Dockerfile .
```

With Jupyter Notebooks server pre-installed, build with:

```bash
docker build -t anaconda3:latest-jupyter -f Dockerfile.jupyter .
```

### Anaconda with NVIDIA/CUDA GPU support

```bash
docker build -t anaconda3:latest-gpu -f Dockerfile.nvidia .
```

With Jupyter Notebooks server pre-installed, build with:

```
docker build -t anaconda3:latest-gpu-jupyter -f Dockerfile.nvidia-jupyter .
```

## Environment

The default environment uses the following configurable options:

```
ANACONDA_DIST=Miniconda3
ANACONDA_PYTHON=py38
ANACONDA_CONDA=4.8.3
ANACONDA_OS=Linux
ANACONDA_ARCH=x86_64
ANACONDA_VERSION=$ANACONDA_DIST-$ANACONDA_PYTHON_$ANACONDA_CONDA-$ANACONDA_OS-$ANACONDA_ARCH
ANACONDA_GID=100
ANACONDA_PATH=/usr/local/anaconda3
ANACONDA_UID=1000
ANACONDA_USER=anaconda
ANACONDA_ENV=magenta
HOME=/home/$ANACONDA_USER
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_ALL=en_US.UTF-8
SHELL=/bin/bash

```

## References

- [Anaconda 3](https://www.anaconda.com/blog/tensorflow-in-anaconda)
- [conda-forge](https://conda-forge.org/)
