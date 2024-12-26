# Start from a Debian-based image
FROM debian:bookworm-slim

# Set non-interactive frontend to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required build dependencies
RUN apt-get update && apt-get install -y \
    gosu \
    autoconf \
    libtool \
    make \
    g++ \
    libcrypto++-dev \
    zlib1g-dev \
    libsqlite3-dev \
    libssl-dev \
    libcurl4-gnutls-dev \
    libreadline-dev \
    libsodium-dev \
    libc-ares-dev \
    libfreeimage-dev \
    libavcodec-dev \
    libavutil-dev \
    libavformat-dev \
    libswscale-dev \
    libmediainfo-dev \
    libzen-dev \
    libuv1-dev \
    libicu-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Clone MEGAcmd source code with submodules
RUN git clone --recursive https://github.com/meganz/MEGAcmd.git /tmp/MEGAcmd

# Set the working directory
WORKDIR /tmp/MEGAcmd

# Run Autotools and configure with --without-ffmpeg and --disable-dependency-tracking
RUN sh autogen.sh && \
    ./configure --without-ffmpeg --disable-dependency-tracking && \
    make && \
    make install && \
    ldconfig

# Clean up unnecessary files to reduce image size
RUN rm -rf /tmp/*

# Copy a startup script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the working directory for MEGAcmd
WORKDIR /data

# Expose a volume to allow syncing with MEGA
VOLUME ["/data"]

# Run the entrypoint script that logs in and sets up the sync
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

