FROM ubuntu:26.04

ARG BUILDTIME
ARG REVISION
ARG TARGETPLATFORM
ARG VERSION

LABEL maintainer="Hans Jörg Wieland <mail@wieland.tech>" \
      org.opencontainers.image.authors="Hans Jörg Wieland <mail@wieland.tech>" \
      org.opencontainers.image.base.name="ubuntu:26.04" \
      org.opencontainers.image.created="${BUILDTIME}" \
      org.opencontainers.image.description="Debug Pod for Kubernetes" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.ref.name="hajowieland/debug-pod" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/hajowieland/debug-pod" \
      org.opencontainers.image.url="https://github.com/hajowieland/debug-pod.git" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.vendor="Wieland IT-Consulting"

ENV AWSCLI="2.36.5"
ENV DEBIAN_FRONTEND="noninteractive"
ENV ETCD="v3.6.13"
ENV FLUXCLI="2.9.1"
ENV KUBECTL="1.36.2"
ENV TZ="Europe/Berlin"
ENV YQ="4.53.3"

# Install packages
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
  tzdata \
  ca-certificates \
  curl \
  bind9-dnsutils \
  iputils-ping \
  jq \
  git \
  gnupg \
  less \
  netcat-openbsd \
  nmap \
  openssh-client \
  postgresql-client \
  tree \
  unzip \
  vim-tiny \
  wget \
  yamllint \
  && rm -rf /var/lib/apt/lists/*


# Config ca-certificates for wget
RUN echo "ca_certificate=/etc/ssl/certs/ca-certificates.crt" > "$HOME/.wgetrc"

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata

# AWS CLI
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=none; else ARCHITECTURE=x86_64; fi && \
  if [ "$ARCHITECTURE" = "none" ]; then echo "AWS CLI v2 has no armv7 release, skipping"; else \
  curl -fSsL -o /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${ARCHITECTURE}-${AWSCLI}.zip" && \
  unzip -q /tmp/awscliv2.zip -d /tmp && \
  /tmp/aws/install && \
  rm -rf /tmp/aws /tmp/awscliv2.zip && \
  aws --version; fi

# etcdctl + etcdutl
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=none; else ARCHITECTURE=amd64; fi && \
  if [ "$ARCHITECTURE" = "none" ]; then echo "etcd has no armv7 release, skipping"; else \
  curl -fSsL -o /tmp/etcd.tar.gz "https://github.com/etcd-io/etcd/releases/download/${ETCD}/etcd-${ETCD}-linux-${ARCHITECTURE}.tar.gz" && \
  tar xzf /tmp/etcd.tar.gz -C /tmp && \
  mv "/tmp/etcd-${ETCD}-linux-${ARCHITECTURE}/etcdctl" "/tmp/etcd-${ETCD}-linux-${ARCHITECTURE}/etcdutl" /usr/local/bin/ && \
  rm -rf /tmp/etcd* && \
  etcdctl version && etcdutl version; fi

# Flux CLI
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
  curl -fSsL -o /tmp/flux.tar.gz "https://github.com/fluxcd/flux2/releases/download/v${FLUXCLI}/flux_${FLUXCLI}_linux_${ARCHITECTURE}.tar.gz" && \
  tar xzf /tmp/flux.tar.gz -C /tmp && \
  mv /tmp/flux /usr/local/bin/ && \
  rm -rf /tmp/flux* && \
  flux --version

# kubectl
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=linux/amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=linux/arm; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=linux/arm64; else ARCHITECTURE=linux/amd64; fi && \
  curl -fSsL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v${KUBECTL}/bin/${ARCHITECTURE}/kubectl && \
  chmod +x /usr/local/bin/kubectl && \
  kubectl version --client

# yq
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; else ARCHITECTURE=amd64; fi && \
  curl -fSsL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ}/yq_linux_${ARCHITECTURE} && \
  chmod +x /usr/local/bin/yq && \
  yq --version

CMD ["kubectl", "version", "--client"]

