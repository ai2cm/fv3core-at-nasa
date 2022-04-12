FROM nvcr.io/nvidia/cuda:11.0-devel-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive

# GNU compiler
RUN apt-get update -y && \
    apt install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends\
    file \
    g++ \
    gcc \
    gcc-9 \
    g++-9 \
    gfortran \
    libgfortran4 \
    libgomp1 \
    make \
    gdb \
    strace \
    wget \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN wget -q http://www.mpich.org/static/downloads/3.1.4/mpich-3.1.4.tar.gz  && \
    tar xf mpich-3.1.4.tar.gz && \
    cd mpich-3.1.4 && \
    ./configure --disable-fortran --enable-fast=all,O3 --prefix=/usr/local --with-cuda=/usr/local/cuda && \
    make -j$(nproc) && \
    make install &&\
    ldconfig && \
    rm ../mpich-3.1.4.tar.gz

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.7.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/osu-micro-benchmarks-5.7.tar.gz -C /var/tmp -z && \
    cd /var/tmp/osu-micro-benchmarks-5.7 && CC=mpicc CXX=mpicxx ./configure --prefix=/usr/local/osu --enable-cuda --with-cuda=/usr/local/cuda && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/osu-micro-benchmarks-5.7 /var/tmp/osu-micro-benchmarks-5.7.tar.gz

ENV PATH=/usr/local/osu/libexec/osu-micro-benchmarks:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/collective:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/one-sided:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/pt2pt:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/startup:$PATH


###########################################################
###########################################################
###########################################################
###########################################################


ENV PATH=/usr/local/osu/libexec/osu-micro-benchmarks:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/collective:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/one-sided:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/pt2pt:/usr/local/osu/libexec/osu-micro-benchmarks/mpi/startup:$PATH

# Linux tooling 
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    nano \
    tar \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# gcc, git, && python

RUN apt-get update -y && \
    apt install -y --no-install-recommends \
    git \
    python \
    python3.8 \
    python3.8-dev &&\
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean


# Fix python && gcc default bin to point to the version we need
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 60
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 60
RUN python --version
RUN gcc --version
RUN g++ --version

# CMake version 3.18.3
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3-Linux-x86_64.sh && \
    mkdir -p /usr/local && \
    /bin/sh /var/tmp/cmake-3.18.3-Linux-x86_64.sh --prefix=/usr/local --skip-license && \
    rm -rf /var/tmp/cmake-3.18.3-Linux-x86_64.sh
ENV PATH=/usr/local/bin:$PATH

#PIP
# Get a random py3 pip then upgrade it to latest (same for setuptools & wheel)
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    python3-pip

RUN python -m pip --no-cache-dir install --upgrade pip && \
    python -m pip --no-cache-dir install setuptools &&\
    python -m pip --no-cache-dir install wheel

# Py default packages
RUN python -m pip --no-cache-dir \
    install \
    kiwisolver \
    numpy \
    matplotlib \
    cupy-cuda110 \
    Cython \
    h5py \
    six \
    zipp \
    pytest \
    pytest-profiling \
    pytest-subtests \
    hypothesis \
    gitpython \
    clang-format \
    gprof2dot \
    cftime \
    f90nml \
    pandas \
    pyparsing \
    python-dateutil \
    pytz \
    pyyaml \
    xarray \
    zarr

RUN LDFLAGS='-L /usr/local/cuda/lib64 -lcudart -lcuda' MPICC=mpicc pip install mpi4py

# gt4py - no GridTools
RUN git clone --branch SC22 https://github.com/gronerl/gt4py &&\
    python -m pip install ./gt4py

# # fv3gfs-util
RUN git clone --branch SC22 https://github.com/ai2cm/fv3gfs-util.git &&\
    python -m pip install ./fv3gfs-util

# # fv3core
RUN git clone --branch SC22 https://github.com/ai2cm/fv3core.git &&\
    python -m pip install ./fv3core

# # DaCe
RUN git clone --branch FV3v1 https://github.com/spcl/dace.git &&\
    python -m pip install ./dace

# Copy caches & runner
# RUN mkdir -p /gt_cache
# ADD SC22 /gt_cache/

# Copy runner & namelist
ADD /SC22/c192_6ranks_baroclinic/ /
ADD /SC22/runner.sh /