# ===================================
# Purpose: testing `fv3core` on GPU
# Stack:
#   - based on nvidia ubuntu18 image
#   - gcc-9.3 (gt4py)
#   - g++-9.3 (for boost & other built deps)
#   - python-3.8 (fv3core, gt4py)
#   - mpich-dev (latest from PPA)
#   - Boost-1.70 (for serialbox & gt4py)
#   - serialbox-2.6.0 (fv3core)
#   - GT4Py git tag v30 (fv3core)
#   - fv3gfts-util HEAD of master (fv3core)
#   - fv3core HEAD of master (pip install in edit mode)
# Tools & configuration
#   - nano
#   - TMPDIR > /local_tmp
# ===================================

FROM nvcr.io/nvidia/cuda:11.2.0-devel-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive

# Linux tooling 
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    nano \
    tar \
    wget

# gcc, git, && python
# GCC + ubuntu18.04 ppa
RUN apt-get update -y && \
    apt install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test

RUN apt-get update -y && \
    apt install -y --no-install-recommends \
    gcc-9 \
    g++-9 \
    git \
    gfortran \
    python \
    python3.8 \
    python3.8-dev &&\
    rm -rf /var/lib/apt/lists/*

# Fix python && gcc default bin to point to the version we need
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 60
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 60
RUN python --version
RUN gcc --version
RUN g++ --version

# MPICH
ENV MPICH_VERSION=3.4
ENV MPICH_URL="http://www.mpich.org/static/downloads/$MPICH_VERSION/mpich-$MPICH_VERSION.tar.gz"
ENV MPICH_DIR=/opt/mpich

RUN mkdir -p /tmp/mpich
RUN mkdir -p /opt

# download
RUN cd /tmp/mpich && wget -O mpich-$MPICH_VERSION.tar.gz $MPICH_URL && tar xzf mpich-$MPICH_VERSION.tar.gz

# conf & make
RUN cd /tmp/mpich/mpich-$MPICH_VERSION && \
    ./configure \
    --with-cuda=/usr/local/cuda \
    --enable-shared \
    --prefix=$MPICH_DIR \
    --with-device=ch3 && \
    make install

# setup env var for LD & path
ENV PATH=$MPICH_DIR/bin:$PATH
ENV LD_LIBRARY_PATH=$MPICH_DIR/lib:$LD_LIBRARY_PATH
ENV MANPATH=$MPICH_DIR/share/man:$MANPATH

# We need to create a symlink to the extended lib name (This is probably a bug...)
RUN ln -s /opt/mpich/lib/libmpich.so /opt/mpich/lib/libmpich.so.0

# Docker hard limits shared memory usage. MPICH for oversubscribed situation
# uses shared mem for most of its comunication operations,
# which leads to a sigbus crash.
# Both of those (for version <3.2 and >3.2) will force mpich to go
# through the network stack instead of using the shared nemory
# The cost is a slower runtime
ENV MPIR_CVAR_NOLOCAL=1
ENV MPIR_CVAR_CH3_NOLOCAL=1

#PIP
# Get a random py3 pip then upgrade it to latest (same for setuptools & wheel)
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    python3-pip

RUN python -m pip --no-cache-dir install --upgrade pip && \
    python -m pip --no-cache-dir install setuptools &&\
    python -m pip --no-cache-dir install wheel

# Py default packages
RUN python -m pip --no-cache-dir install kiwisolver numpy matplotlib cupy-cuda112 Cython h5py six zipp pytest pytest-profiling pytest-subtests  hypothesis gitpython clang-format gprof2dot cftime f90nml pandas pyparsing python-dateutil pytz pyyaml xarray zarr git+https://github.com/mpi4py/mpi4py.git@aac3d8f2a56f3d74a75ad32ac0554d63e7ef90ab

# Boost version 1.76.0
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bzip2 \
    libbz2-dev \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://boostorg.jfrog.io/artifactory/main/release/1.70.0/source/boost_1_70_0.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/boost_1_70_0.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/boost_1_70_0 && ./bootstrap.sh --prefix=/usr/local/boost --without-libraries=python && \
    ./b2 -j$(nproc) -q install && \
    rm -rf /var/tmp/boost_1_70_0.tar.bz2 /var/tmp/boost_1_70_0
ENV LD_LIBRARY_PATH=/usr/local/boost/lib:$LD_LIBRARY_PATH

# CMake version 3.18.3
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3-Linux-x86_64.sh && \
    mkdir -p /usr/local && \
    /bin/sh /var/tmp/cmake-3.18.3-Linux-x86_64.sh --prefix=/usr/local --skip-license && \
    rm -rf /var/tmp/cmake-3.18.3-Linux-x86_64.sh
ENV PATH=/usr/local/bin:$PATH

# serialbox

RUN git clone -b v2.6.0 --depth 1 https://github.com/GridTools/serialbox.git /usr/src/serialbox && \
    cmake -B build -S /usr/src/serialbox -DSERIALBOX_TESTING=ON  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/serialbox && \
    cmake --build build/ -j 4 --target install && \
    rm -rf /usr/src

ENV PYTHONPATH=/usr/local/serialbox/python:$PYTHONPATH

# gt4py

RUN python -m pip --no-cache-dir install git+https://github.com/VulcanClimateModeling/gt4py.git@v30
RUN git clone --depth 1 -b release_v1.1 https://github.com/GridTools/gridtools.git /usr/local/lib/python3.8/dist-packages/gt4py/_external_src/gridtools
ENV BOOST_ROOT /usr/local/boost
ENV CUDA_HOME /usr/local/cuda

# fv3gfs-util

RUN git clone https://github.com/VulcanClimateModeling/fv3gfs-util.git &&\
    python -m pip install -e fv3gfs-util

# fv3core

RUN git clone https://github.com/VulcanClimateModeling/fv3core.git &&\
    python -m pip install -e fv3core


# Move tmp to a bind point
RUN mkdir /mnt/tmp
ENV TMPDIR=/mnt/tmp
RUN mkdir /mnt/data

# Check everything is running as expect
COPY ./setup_check.py ./setup_check.py 
RUN python ./setup_check.py 
