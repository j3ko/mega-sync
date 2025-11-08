FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ARG ARCH
ARG DEB_DISTRO=Debian_12

# Detect architecture automatically when not provided
#   amd64  → amd64
#   arm64  → arm64
RUN if [ -z "$ARCH" ]; then \
      case "$(dpkg --print-architecture)" in \
        amd64) ARCH="amd64" ;; \
        arm64) ARCH="arm64" ;; \
        *) echo "Unsupported arch"; exit 1 ;; \
      esac; \
      echo "ARCH=$ARCH" > /arch.env; \
    else \
      echo "ARCH=$ARCH" > /arch.env; \
    fi

# Install dependencies
RUN apt-get update && apt-get install -y \
      wget \
      ca-certificates \
      gosu \
      && rm -rf /var/lib/apt/lists/*

# Load detected ARCH
RUN . /arch.env && \
    echo "Using architecture: $ARCH" && \
    wget -qO megacmd.deb \
      "https://mega.nz/linux/repo/${DEB_DISTRO}/${ARCH}/megacmd-${DEB_DISTRO}_${ARCH}.deb" && \
    apt-get update && \
    apt-get install -y ./megacmd.deb && \
    rm megacmd.deb

# Copy scripts
COPY entrypoint.sh /usr/local/bin/
COPY healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1
