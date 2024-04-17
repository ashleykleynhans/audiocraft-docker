ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Create and use the Python venv
WORKDIR /
RUN python3 -m venv --system-site-packages /venv

# Clone the git repo of Audiocraft Plus and set version
ARG AUDIOCRAFT_VERSION
RUN git clone https://github.com/GrandaddyShmax/audiocraft_plus.git && \
    cd /audiocraft_plus && \
    git checkout tags/${AUDIOCRAFT_VERSION}

# Install the dependencies for Audiocraft Plus
ARG INDEX_URL
ARG TORCH_VERSION
ARG XFORMERS_VERSION
WORKDIR /audiocraft_plus
RUN source /venv/bin/activate && \
    pip3 install --no-cache-dir torch==${TORCH_VERSION} torchvision torchaudio --index-url ${INDEX_URL} && \
    pip3 install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${INDEX_URL} && \
    pip3 install --no-cache-dir protobuf && \
    pip3 install -r requirements.txt && \
    pip3 install -e . && \
    deactivate

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
