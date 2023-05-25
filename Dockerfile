FROM debian:bullseye-slim

WORKDIR /home

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends -o=Dpkg::Use-Pty=0 \
    apt-transport-https \
    ca-certificates \
    ca-certificates-java \
    cron \
    curl \
    chromium \
    docker.io \
    fonts-open-sans \
    git \
    jq \
    libzip-dev \
    libappindicator-dev \
    gstreamer1.0-libav \
    libnss3-tools \
    libatk-bridge2.0-0 \
    libcups2-dev \
    libxkbcommon-x11-0 \
    libxcomposite-dev \
    libxshmfence-dev \
    libxrandr2 \
    libgbm-dev \
    libgtk-3-0 \
    mc \
    nano \
    openjdk-11-jdk \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    unzip \
    vim \
    x11-apps \
    zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    #firefox-esr \

# kafka
RUN curl -JLO https://downloads.apache.org/kafka/3.4.0/kafka_2.12-3.4.0.tgz && tar -xf kafka_2.12-3.4.0.tgz && rm kafka_2.12-3.4.0.tgz && mv kafka_2.12-3.4.0 kafka && chmod +x kafka/bin/* && mv kafka /usr/local/bin

# yq
RUN cd /usr/local/bin && curl -JLO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && mv yq_linux_amd64 yq && chmod +x yq

#k9s
RUN cd /usr/local/bin && curl -JLO https://github.com/derailed/k9s/releases/download/v0.27.2/k9s_Linux_amd64.tar.gz && tar -xf k9s_Linux_amd64.tar.gz && chmod +x k9s && rm k9s_Linux_amd64.tar.gz

#saml2aws
RUN cd /usr/local/bin && curl -JLO https://github.com/Versent/saml2aws/releases/download/v2.36.2/saml2aws_2.36.2_linux_amd64.tar.gz && tar -xf saml2aws_2.36.2_linux_amd64.tar.gz && chmod +x saml2aws && rm saml2aws_2.36.2_linux_amd64.tar.gz

#aws cli
RUN pip3 install awscli requests boto3 argparse config

# direnv
RUN curl -sfL https://direnv.net/install.sh | bash

COPY entrypoint.sh /usr/local/bin
RUN chmod -R +x /usr/local/bin

USER root

ENV DISPLAY=host.docker.internal:0.0

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]