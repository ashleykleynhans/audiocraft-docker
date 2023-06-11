FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

ARG AUDIOCRAFT_COMMIT=5fff830b1334334c41a8243d19025bc8b52fd487
ARG VENV=/workspace/venv

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /workspace

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-tk \
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

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Create and use the Python venv
RUN python3 -m venv ${VENV}

# Install Torch
RUN source ${VENV}/bin/activate && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install --no-cache-dir xformers && \
    deactivate

# Clone the git repo of Audiocraft and set version
WORKDIR /workspace
RUN git clone https://github.com/facebookresearch/audiocraft.git && \
    cd /workspace/audiocraft && \
    git reset ${AUDIOCRAFT_COMMIT} --hard

# Complete Jupyter installation
RUN source ${VENV}/bin/activate && \
    pip3 install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown && \
    deactivate

# Install the dependencies for Audiocraft
WORKDIR /workspace/audiocraft
RUN source ${VENV}/bin/activate && \
    pip3 install -r requirements.txt && \
    pip3 install -e . && \
    deactivate

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Move audiocraft and venv to the root so it doesn't conflict with Network Volumes
WORKDIR /workspace
RUN mv /workspace/venv /venv
RUN mv /workspace/audiocraft /audiocraft

# Set up the container startup script
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]