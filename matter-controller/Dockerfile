ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install dependencies including build tools for chip-tool
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-websockets \
    py3-requests \
    py3-aiohttp \
    py3-pydantic \
    py3-cryptography \
    py3-yaml \
    jq \
    curl \
    git \
    cmake \
    ninja \
    make \
    g++ \
    glib-dev \
    openssl-dev \
    avahi-dev \
    bluez-dev \
    linux-headers \
    pkgconfig

# Install Python packages
RUN pip3 install --no-cache-dir \
    fastapi \
    uvicorn \
    PyJWT

# Install chip-tool (Matter/Thread CLI tool)
RUN git clone --recurse-submodules https://github.com/project-chip/connectedhomeip.git /tmp/connectedhomeip && \
    cd /tmp/connectedhomeip && \
    ./scripts/checkout_submodules.py --allow-changing-global-git-config --shallow --platform linux && \
    ./scripts/build/build_examples.py --target linux-x64-chip-tool build && \
    cp out/linux-x64-chip-tool/chip-tool /usr/local/bin/ && \
    chmod +x /usr/local/bin/chip-tool && \
    rm -rf /tmp/connectedhomeip

# Copy files
COPY rootfs/matter_controller /matter_controller
COPY rootfs/usr/bin/debug-install.sh /usr/bin/debug-install.sh
COPY run.sh /

# Create data directories
RUN mkdir -p /data/matter_controller/credentials \
    && mkdir -p /data/logs \
    && mkdir -p /data/matter_server

# Make scripts executable
RUN chmod +x /usr/bin/debug-install.sh \
    && chmod +x /run.sh

CMD [ "/run.sh" ]
