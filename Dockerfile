# syntax=docker/dockerfile:1

FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04


# Labels

LABEL version="0.1"
LABEL description="Docker image for darglein/ADOP"

# Envs
ENV HOME_PATH=/usr/local
ENV ADOP_PATH=${HOME_PATH}/ADOP

# ignore interactive mode, just install everything
ENV DEBIAN_FRONTEND noninteractive

# Start as root
USER root

# install conda (thank you https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/debian/Dockerfile)

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# hadolint ignore=DL3008
RUN apt-get update -q && \
    apt-get install -q -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH /opt/conda/bin:$PATH

CMD [ "/bin/bash" ]

# Leave these args here to better use the Docker build cache
ARG CONDA_VERSION=latest

RUN set -x && \
    UNAME_M="$(uname -m)" && \
    if [ "${UNAME_M}" = "x86_64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh"; \
        SHA256SUM="1ea2f885b4dbc3098662845560bc64271eb17085387a70c2ba3f29fff6f8d52f"; \
    elif [ "${UNAME_M}" = "s390x" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-s390x.sh"; \
        SHA256SUM="1faed9abecf4a4ddd4e0d8891fc2cdaa3394c51e877af14ad6b9d4aadb4e90d8"; \
    elif [ "${UNAME_M}" = "aarch64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-aarch64.sh"; \
        SHA256SUM="4879820a10718743f945d88ef142c3a4b30dfc8e448d1ca08e019586374b773f"; \
    elif [ "${UNAME_M}" = "ppc64le" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-ppc64le.sh"; \
        SHA256SUM="fa92ee4773611f58ed9333f977d32bbb64769292f605d518732183be1f3321fa"; \
    fi && \
    wget "${MINICONDA_URL}" -O miniconda.sh -q && \
    echo "${SHA256SUM} miniconda.sh" > shasum && \
    if [ "${CONDA_VERSION}" != "latest" ]; then sha256sum --check --status shasum; fi && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh shasum && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate adop" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

# Install ADOP dependencies and other dependencies
RUN apt-get -q update && \
    apt-get -qy install software-properties-common && \
    apt-add-repository ppa:ubuntu-toolchain-r/test && \
    apt-add-repository universe && \
    apt-get -q update && \
    apt-get -qy install \
        gcc-9 \
        g++-9 \
        git \
        unzip \
        build-essential \
        cmake \
        xorg-dev \
        libglu1-mesa-dev \
        freeglut3-dev \
        mesa-common-dev \
        mesa-utils \
        doxygen \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Fetch ADOP

RUN git clone https://github.com/darglein/ADOP.git ${ADOP_PATH}

# cd into ${ADOP_PATH}

WORKDIR ${ADOP_PATH}

# install submodules

RUN git submodule update --init --recursive --jobs 0

# Create Conda env

RUN ./create_environment.sh

SHELL ["conda", "run", "-n", "adop", "/bin/bash", "-c"]

# Install pytorch

RUN ./install_pytorch.sh

# Build adop

RUN ./build_adop.sh

# set some default exports
RUN echo "export LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH}:/opt/conda/envs/adop/lib\"" >> ~/.bashrc
