FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Copy the prebuilt MEGAcmd binaries
COPY dist/mega* /usr/bin/
COPY dist/megacmd /opt/megacmd/

# Ensure binaries are executable
RUN chmod +x /usr/bin/mega* && chmod +x /opt/megacmd/*

# Copy and set permissions for scripts
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/healthcheck.sh /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /usr/bin
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1
