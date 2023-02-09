FROM debian:bullseye-slim

WORKDIR /home

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends -o=Dpkg::Use-Pty=0 \
    apt-transport-https \
    ca-certificates \
    cron \
    curl \
    docker.io \
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
    procps \
    python3 \
    python3-pip \
    unzip \
    vim \
    zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# yq
RUN cd /usr/local/bin && curl -LJO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && mv yq_linux_amd64 yq && chmod +x yq

#k9s
RUN cd /usr/local/bin && curl -LJO https://github.com/derailed/k9s/releases/download/v0.27.2/k9s_Linux_amd64.tar.gz && tar -xf k9s_Linux_amd64.tar.gz && chmod +x k9s && rm k9s_Linux_amd64.tar.gz

#saml2aws
RUN cd /usr/local/bin && curl -LJO https://github.com/Versent/saml2aws/releases/download/v2.36.2/saml2aws_2.36.2_linux_amd64.tar.gz && tar -xf saml2aws_2.36.2_linux_amd64.tar.gz && chmod +x saml2aws && rm saml2aws_2.36.2_linux_amd64.tar.gz

#aws cli
RUN pip3 install awscli

COPY entrypoint.sh /usr/local/bin
RUN chmod -R +x /usr/local/bin

USER root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]