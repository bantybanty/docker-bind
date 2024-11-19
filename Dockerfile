# Stage 1: Add required repositories and GPG keys
FROM ubuntu:focal-20241011 AS add-apt-repositories

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg curl apt-transport-https apt-utils \
    && curl -fsSL https://download.webmin.com/jcameron-key.asc | gpg --dearmor -o /usr/share/keyrings/webmin-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list

# Stage 2: Build the final image
FROM ubuntu:focal-20241011

LABEL maintainer="sameer@damagehead.com"

ENV BIND_USER=bind \
    BIND_VERSION=9.16.1 \
    WEBMIN_VERSION=2.202 \
    DATA_DIR=/data

# Copy repositories and keys from the first stage
COPY --from=add-apt-repositories /etc/apt/sources.list.d/webmin.list /etc/apt/sources.list.d/webmin.list
COPY --from=add-apt-repositories /usr/share/keyrings/webmin-archive-keyring.gpg /usr/share/keyrings/webmin-archive-keyring.gpg

RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bind9=${BIND_VERSION}-* bind9-host=${BIND_VERSION}-* dnsutils \
    webmin=${WEBMIN_VERSION} \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script
COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 53/udp 53/tcp 10000/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/sbin/named"]
