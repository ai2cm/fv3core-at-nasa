FROM gitlab.nccs.nasa.gov:5050/nccs-ci/nccs-containers/base/ubuntu18

FROM nvcr.io/nvidia/cuda:11.2.0-base-ubuntu18.04

FROM nvcr.io/nvidia/cuda:11.2.0-runtime-ubuntu18.04

# mpich

RUN apt-get update -y && apt install -y git

RUN dpkg-divert --remove /usr/bin/gfortran && apt-get update -y && apt install -y gfortran

RUN apt-get update -y && apt install -y libmpich-dev

# Python & common py packages
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    python3.8 \
    python3.8-dev &&\
    rm -rf /var/lib/apt/lists/*
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&\
    python3.8 get-pip.py
RUN pip3 --no-cache-dir install --upgrade pip && \
    pip3 --no-cache-dir install setuptools &&\
    pip3 --no-cache-dir install wheel &&\
    pip3 --no-cache-dir install kiwisolver numpy matplotlib cupy-cuda112 Cython h5py six zipp pytest pytest-profiling pytest-subtests  hypothesis gitpython clang-format gprof2dot cftime f90nml pandas pyparsing python-dateutil pytz pyyaml xarray zarr git+https://github.com/mpi4py/mpi4py.git@aac3d8f2a56f3d74a75ad32ac0554d63e7ef90ab

# Boost version 1.76.0
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bzip2 \
    libbz2-dev \
    tar \
    wget \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/boost_1_76_0.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/boost_1_76_0 && ./bootstrap.sh --prefix=/usr/local/boost --without-libraries=python && \
    ./b2 -j$(nproc) -q install && \
    rm -rf /var/tmp/boost_1_76_0.tar.bz2 /var/tmp/boost_1_76_0
ENV LD_LIBRARY_PATH=/usr/local/boost/lib:$LD_LIBRARY_PATH

# CMake version 3.18.3
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
    cmake -B build -S /usr/src/serialbox -DSERIALBOX_TESTING=ON         -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/serialbox         -DNETCDF_ROOT=/usr/local/netcdf && \
    cmake --build build/ -j 4 --target install && \
    rm -rf /usr/src

ENV PYTHONPATH=/usr/local/serialbox/python:$PYTHONPATH

# gt4py

# pip
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3-pip \
    python3-setuptools \
    python3-wheel && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 --no-cache-dir install git+https://github.com/VulcanClimateModeling/gt4py.git@v30

RUN git clone --depth 1 -b release_v1.1         https://github.com/GridTools/gridtools.git         /usr/local/lib/python3.8/dist-packages/gt4py/_external_src/gridtools

# fv3gfs-util

RUN git clone https://github.com/VulcanClimateModeling/fv3gfs-util.git && \
    pip3 install -e fv3gfs-util

# fv3core

RUN git clone https://github.com/VulcanClimateModeling/fv3core.git && \
    pip3 install -e fv3core

