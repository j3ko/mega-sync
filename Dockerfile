FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

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

RUN git clone --recursive https://github.com/meganz/MEGAcmd.git /tmp/MEGAcmd

WORKDIR /tmp/MEGAcmd

RUN sh autogen.sh && \
    ./configure --without-ffmpeg --disable-dependency-tracking && \
    make && \
    make install && \
    ldconfig

RUN rm -rf /tmp/*

COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data

VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1
