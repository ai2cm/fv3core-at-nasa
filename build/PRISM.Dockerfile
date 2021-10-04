# ===================================
# Purpose: testing `fv3core` on GPU
# Stack:
#   - based on nvidia-devel ubuntu18 image
#   - gcc-9.3 / g++-9.3
#   - OFED / GDRCOPY / KNEM / PMI2 > MPI-Cuda
#   - Nsight Systems
#   - osu benchmark (in /osu)
#   - python-3.8 (fv3core, gt4py)
#   - openmpi (from source, hidden dependancy on ssh)
#   - Boost-1.70 (for serialbox & gt4py)
#   - serialbox-2.6.0 (fv3core)
#   - GT4Py git tag v36 (fv3core)
#   - fv3gfts-util HEAD of master (fv3core)
#   - fv3core HEAD of master (pip install in edit mode)
# Tools & configuration
#   - nano
# ===================================

FROM nvcr.io/nvidia/cuda:11.0-devel-ubuntu18.04

ENV DEBIAN_FRONTEND=noninteractive

# In order to go through NASA's proxy reliably when updating the PPA repository of Ubuntu
RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

# GNU compiler
RUN apt-get update -y && \
    apt install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    g++ \
    gcc \
    gcc-9 \
    g++-9 \
    gfortran \
    libgfortran4 \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# GDRCOPY version 2.2
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/NVIDIA/gdrcopy/archive/v2.2.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/v2.2.tar.gz -C /var/tmp -z && \
    cd /var/tmp/gdrcopy-2.2 && \
    mkdir -p /usr/local/gdrcopy/include /usr/local/gdrcopy/lib && \
    make prefix=/usr/local/gdrcopy lib lib_install && \
    echo "/usr/local/gdrcopy/lib" >> /etc/ld.so.conf.d/hpccm.conf && ldconfig && \
    rm -rf /var/tmp/gdrcopy-2.2 /var/tmp/v2.2.tar.gz
ENV CPATH=/usr/local/gdrcopy/include:$CPATH \
    LIBRARY_PATH=/usr/local/gdrcopy/lib:$LIBRARY_PATH \
    LD_LIBRARY_PATH=/usr/local/gdrcopy/lib:$LD_LIBRARY_PATH

# KNEM version 1.1.4
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && cd /var/tmp && git clone --depth=1 --branch knem-1.1.4 https://gitlab.inria.fr/knem/knem.git knem && cd - && \
    mkdir -p /usr/local/knem && \
    cd /var/tmp/knem && \
    mkdir -p /usr/local/knem/include && \
    cp common/*.h /usr/local/knem/include && \
    echo "/usr/local/knem/lib" >> /etc/ld.so.conf.d/hpccm.conf && ldconfig && \
    rm -rf /var/tmp/knem
ENV CPATH=/usr/local/knem/include:$CPATH

#Mellanox OFED version 4.6-1.0.1.1
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    libnl-3-200 \
    libnl-route-3-200 \
    libnuma1 \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add - && \
    mkdir -p /etc/apt/sources.list.d && wget -q -nc --no-check-certificate -P /etc/apt/sources.list.d https://linux.mellanox.com/public/repo/mlnx_ofed/4.6-1.0.1.1/ubuntu18.04/mellanox_mlnx_ofed.list && \
    apt-get update -y && \
    mkdir -m 777 -p /var/tmp/packages_download && cd /var/tmp/packages_download && \
    apt-get download -y --no-install-recommends \
    ibverbs-utils \
    libibmad \
    libibmad-devel \
    libibumad \
    libibumad-devel \
    libibverbs-dev \
    libibverbs1 \
    libmlx4-1 \
    libmlx4-dev \
    libmlx5-1 \
    libmlx5-dev \
    librdmacm-dev \
    librdmacm1 && \
    mkdir -p /usr/local/ofed/4.6-1.0.1.1 && \
    find /var/tmp/packages_download -regextype posix-extended -type f -regex "/var/tmp/packages_download/(ibverbs-utils|libibmad|libibmad-devel|libibumad|libibumad-devel|libibverbs-dev|libibverbs1|libmlx4-1|libmlx4-dev|libmlx5-1|libmlx5-dev|librdmacm-dev|librdmacm1).*deb" -exec dpkg --extract {} /usr/local/ofed/4.6-1.0.1.1 \; && \
    rm -rf /var/tmp/packages_download && \
    rm -f /etc/apt/sources.list.d/mellanox_mlnx_ofed.list && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /etc/libibverbs.d

# Mellanox OFED version 5.2-2.2.0.0
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add - && \
    mkdir -p /etc/apt/sources.list.d && wget -q -nc --no-check-certificate -P /etc/apt/sources.list.d https://linux.mellanox.com/public/repo/mlnx_ofed/5.2-2.2.0.0/ubuntu18.04/mellanox_mlnx_ofed.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ibverbs-providers \
    ibverbs-utils \
    libibmad-dev \
    libibmad5 \
    libibumad-dev \
    libibumad3 \
    libibverbs-dev \
    libibverbs1 \
    librdmacm-dev \
    librdmacm1 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean


# UCX version 1.10.0
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    binutils-dev \
    file \
    libnuma-dev \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/openucx/ucx/releases/download/v1.10.0/ucx-1.10.0.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/ucx-1.10.0.tar.gz -C /var/tmp -z && \
    cd /var/tmp/ucx-1.10.0 &&   ./configure --prefix=/usr/local/ucx --disable-assertions --disable-debug --disable-doxygen-doc --disable-logging --disable-params-check --disable-static --enable-mt --enable-optimizations --with-cuda=/usr/local/cuda --with-gdrcopy=/usr/local/gdrcopy --with-knem=/usr/local/knem && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/ucx-1.10.0 /var/tmp/ucx-1.10.0.tar.gz
ENV CPATH=/usr/local/ucx/include:$CPATH \
    LD_LIBRARY_PATH=/usr/local/ucx/lib:$LD_LIBRARY_PATH \
    LIBRARY_PATH=/usr/local/ucx/lib:$LIBRARY_PATH \
    PATH=/usr/local/ucx/bin:$PATH

# UCX version 1.10.0
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    libbinutils \
    binutils-dev \
    file \
    libnuma-dev \
    make \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/openucx/ucx/releases/download/v1.10.0/ucx-1.10.0.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/ucx-1.10.0.tar.gz -C /var/tmp -z && \
    cd /var/tmp/ucx-1.10.0 &&  LD_LIBRARY_PATH=/usr/local/ofed/4.6-1.0.1.1/lib:${LD_LIBRARY_PATH} ./configure --prefix=/usr/local/ucx-mlnx-legacy --disable-assertions --disable-debug --disable-doxygen-doc --disable-logging --disable-params-check --disable-static --enable-mt --enable-optimizations --with-cuda=/usr/local/cuda --with-gdrcopy=/usr/local/gdrcopy --with-knem=/usr/local/knem --with-rdmacm=/usr/local/ofed/4.6-1.0.1.1/usr --with-verbs=/usr/local/ofed/4.6-1.0.1.1/usr && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/ucx-1.10.0 /var/tmp/ucx-1.10.0.tar.gz

RUN ln -s /usr/local/ucx-mlnx-legacy/bin/* /usr/local/ofed/4.6-1.0.1.1/usr/bin && \
    ln -s /usr/local/ucx-mlnx-legacy/lib/* /usr/local/ofed/4.6-1.0.1.1/usr/lib

# SLURM PMI2 version 20.11.7
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bzip2 \
    file \
    make \
    perl \
    tar \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-20.11.7.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/slurm-20.11.7.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/slurm-20.11.7 &&   ./configure --prefix=/usr/local/pmi && \
    cd /var/tmp/slurm-20.11.7 && \
    make -C contribs/pmi2 install && \
    rm -rf /var/tmp/slurm-20.11.7 /var/tmp/slurm-20.11.7.tar.bz2

# OpenMPI version 4.0.5
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bzip2 \
    file \
    hwloc \
    libnuma-dev \
    make \
    openssh-client \
    perl \
    tar \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.5.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/openmpi-4.0.5.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/openmpi-4.0.5 &&   ./configure --prefix=/usr/local/openmpi --disable-getpwuid --disable-oshmem --disable-static --enable-mca-no-build=btl-uct --enable-orterun-prefix-by-default --with-cuda --with-pmi=/usr/local/pmi --with-ucx --without-verbs && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    echo "/usr/local/openmpi/lib" >> /etc/ld.so.conf.d/hpccm.conf && ldconfig && \
    rm -rf /var/tmp/openmpi-4.0.5 /var/tmp/openmpi-4.0.5.tar.bz2

ENV PATH=/usr/local/openmpi/bin:$PATH

ENV OMPI_ALLOW_RUN_AS_ROOT=1 \
    OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

ENV CUDA_CACHE_DISABLE=1 \
    MELLANOX_VISIBLE_DEVICES=all \
    OMPI_MCA_pml=ucx


# OSU benchmark

# http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.7.tar.gz
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.7.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/osu-micro-benchmarks-5.7.tar.gz -C /var/tmp -z && \
    cd /var/tmp/osu-micro-benchmarks-5.7 &&  CC=mpicc CXX=mpicxx ./configure --prefix=/usr/local/osu --enable-cuda --with-cuda=/usr/local/cuda && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/osu-micro-benchmarks-5.7 /var/tmp/osu-micro-benchmarks-5.7.tar.gz

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

# Py default packages
RUN python -m pip --no-cache-dir install kiwisolver numpy matplotlib cupy-cuda110 Cython h5py six zipp pytest pytest-profiling pytest-subtests  hypothesis gitpython clang-format gprof2dot cftime f90nml pandas pyparsing python-dateutil pytz pyyaml xarray zarr git+https://github.com/mpi4py/mpi4py.git@aac3d8f2a56f3d74a75ad32ac0554d63e7ef90ab

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

# Entrypoint for MCA selection
COPY ./build/PRISM_entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
