# Set base image
FROM debian:stable-slim

# Set necessary environment variables for the current Monero version and hash
# ENV FILE=monero-linux-x64-v0.18.2.2.tar.bz2
# ENV FILE_CHECKSUM=186800de18f67cca8475ce392168aabeb5709a8f8058b0f7919d7c693786d56b

# Set necessary environment variables for the current Wownero version and hash
ENV FILE=wownero-x86_64-linux-gnu-v0.11.0.3.tar.bz2
ENV FILE_CHECKSUM=e31d9f1e76d5c65e774c4208dfd1a18cfeda9f3822facaf1d114459ca9a38320

# Set SHELL options per https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install bzip2 ca-certificates wget curl \
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/*

# Download specified Wownero tar.gz and verify downloaded binary against hardcoded checksum
# RUN wget -qO $FILE https://downloads.getmonero.org/cli/$FILE && \
#     echo "$FILE_CHECKSUM $FILE" | sha256sum -c - 

RUN wget -qO $FILE https://git.wownero.com/attachments/c1de2873-a72d-41d3-a807-d36e8305ea3f && \
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
	adduser --system --disabled-password --uid 101 --gid 101 wownero && \
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
