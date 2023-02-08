FROM debian:bullseye-slim

WORKDIR /usr/local/bin

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends -o=Dpkg::Use-Pty=0 \
    apt-transport-https \
    ca-certificates \
    cron \
    curl \
    docker.io \
    jq \
    vim \
    libzip-dev \
    procps \
    unzip \
    zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq

COPY entrypoint.sh /usr/local/bin
RUN chmod -R +x /usr/local/bin

USER root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]