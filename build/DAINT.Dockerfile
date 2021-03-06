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

# NVIDIA Nsight Systems 2020.2.1

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://developer.download.nvidia.com/devtools/repos/ubuntu1804/amd64/nvidia.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/devtools/repos/ubuntu1804/amd64/ /" >> /etc/apt/sources.list.d/nsight.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    nsight-systems-2021.1.1 && \
    rm -rf /var/lib/apt/lists/*

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

#PIP
# Get a random py3 pip then upgrade it to latest (same for setuptools & wheel)
RUN apt-get update -y &&\
    apt install -y --no-install-recommends\
    python3-pip

RUN python -m pip --no-cache-dir install --upgrade pip && \
    python -m pip --no-cache-dir install setuptools &&\
    python -m pip --no-cache-dir install wheel

# Boost version 1.76.0
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bzip2 \
    libbz2-dev \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

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
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

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

# # Install mpi4py from source
# RUN wget https://github.com/mpi4py/mpi4py/releases/download/3.1.1/mpi4py-3.1.1.tar.gz && \
#     tar xf mpi4py-3.1.1.tar.gz && \
#     cd mpi4py-3.1.1 && \
#     python setup.py build --mpicc=$MPI_DIR/bin/mpicc && \
#     rm ../mpi4py-3.1.1.tar.gz

# RUN pip install -e mpi4py-3.1.1

# RUN ln -s /usr/local/mpich/lib/libmpich.so /usr/local/mpich/lib/libmpich_gnu_82.so.3

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
    zarr \
    mpi4py

# gt4py
# Install manually GT 1.1 and 2.0+ (master) in the default directory exepcted by GT4PY

RUN git clone --depth 1 --branch v36 https://github.com/ai2cm/gt4py
RUN git clone --depth 1 -b release_v1.1 https://github.com/GridTools/gridtools.git /gt4py/src/gt4py/_external_src/gridtools
RUN git clone --depth 1 -b master https://github.com/GridTools/gridtools.git /gt4py/src/gt4py/_external_src/gridtools2
RUN python -m pip install -e gt4py
ENV BOOST_ROOT /usr/local/boost
ENV CUDA_HOME /usr/local/cuda

# fv3gfs-util

RUN git clone https://github.com/ai2cm/fv3gfs-util.git &&\
    python -m pip install -e fv3gfs-util

# fv3core

RUN git clone https://github.com/ai2cm/fv3core.git &&\
    python -m pip install -e fv3core

# performance-visualisation

RUN git clone https://github.com/ai2cm/performance_visualization.git &&\
    python -m pip install -e performance_visualization

# Move tmp to a bind point
RUN mkdir /mnt/tmp
ENV TMPDIR=/mnt/tmp
RUN mkdir /mnt/data
