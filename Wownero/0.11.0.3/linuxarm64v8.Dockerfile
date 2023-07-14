# Explicitly specify arm64v8 base image
FROM arm64v8/debian:stable-slim
#EnableQEMU COPY qemu-aarch64-static /usr/bin
# # Set necessary environment variables for the current Monero version and hash
# ENV FILE=monero-linux-armv8-v0.18.2.2.tar.bz2
# ENV FILE_CHECKSUM=f3867f2865cb98ab1d18f30adfd9168f397bd07bf7c36550dfe3a2a11fc789ba

# Set necessary environment variables for the current Wownero version and hash
ENV FILE=wownero-arm-linux-gnueabihf-v0.11.0.3.tar.bz2
ENV FILE_CHECKSUM=b90e9154ff0796e7b3f0b54ebb43b06d79fb56dc15685364277cf8dd546d404c

# Set SHELL options per https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install bzip2 ca-certificates wget curl \
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/*

# # Download specified Monero tar.gz and verify downloaded binary against hardcoded checksum
# RUN wget -qO $FILE https://downloads.getmonero.org/cli/$FILE && \
#     echo "$FILE_CHECKSUM $FILE" | sha256sum -c - 

# Download specified Wownero tar.gz and verify downloaded binary against hardcoded checksum
RUN wget -qO $FILE https://git.wownero.com/attachments/cfa621e6-668a-47f4-a421-7ca2b864e4dd && \
    echo "$FILE_CHECKSUM $FILE" | sha256sum -c - 

# Extract and set permissions on Wownero binaries
RUN mkdir -p extracted && \
    tar -jxvf $FILE -C /extracted && \
    find /extracted/ -type f -print0 | xargs -0 chmod a+x && \
    find /extracted/ -type f -print0 | xargs -0 mv -t /usr/local/bin/ && \
    rm -rf extracted && rm $FILE

# Copy notifier script
COPY ./scripts /scripts/
RUN find /scripts/ -type f -print0 | xargs -0 chmod a+x

# Create monero user
RUN addgroup --system --gid 101 wownero && \
	adduser --system --disabled-password --uid 101 --gid 101 monero && \
	mkdir -p /wallet /home/wownero/.bitwownero && \
	chown -R wownero:wownero /home/wownero/.bitwownero && \
	chown -R wownero:wownero /wallet

# Specify necessary volumes
VOLUME /home/wownero/.bitwownero
VOLUME /wallet

# Expose p2p, RPC, and ZMQ ports
EXPOSE 18080
EXPOSE 18081
EXPOSE 18082

# Set HOME environment variable
ENV HOME /home/wownero

# Switch to user monero
USER wownero

# Add HEALTHCHECK against get_info endpoint
HEALTHCHECK --interval=5s --timeout=3s CMD curl --fail http://localhost:18081/get_info || exit 1
