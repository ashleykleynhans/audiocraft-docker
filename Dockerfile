# Stage 1: Base
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as base

ARG AUDIOCRAFT_VERSION=2.0.1
ARG TORCH_VERSION=2.0.1
ARG XFORMERS_VERSION=0.0.22

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-pip \
        python3-tk \
        nginx \
        bash \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Stage 2: Install Web UI and python modules
FROM base as setup

# Create and use the Python venv
RUN python3 -m venv --system-site-packages /venv

# Clone the git repo of Audiocraft Plus and set version
WORKDIR /
RUN git clone https://github.com/GrandaddyShmax/audiocraft_plus.git && \
    cd /audiocraft_plus && \
    git checkout tags/${AUDIOCRAFT_VERSION}

# Install the dependencies for Audiocraft Plus
WORKDIR /audiocraft_plus
RUN source /venv/bin/activate && \
    pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install --no-cache-dir xformers==${XFORMERS_VERSION} protobuf && \
    pip3 install -r requirements.txt && \
    pip3 install -e . && \
    deactivate

# Install Jupyter
RUN pip3 install -U --no-cache-dir jupyterlab \
        jupyterlab_widgets \
        ipykernel \
        ipywidgets \
        gdown

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install croc
RUN curl https://getcroc.schollz.com | bash

# Install speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt install speedtest

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

WORKDIR /

# Copy the scripts
COPY --chmod=755 scripts/* ./

# Start the container
ENV TEMPLATE_VERSION=3.0.4
SHELL ["/bin/bash", "--login", "-c"]
ENTRYPOINT [ "/start.sh" ]
