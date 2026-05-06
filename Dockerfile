FROM ubuntu:24.04

ARG TRIVY_VERSION=0.60.0
ARG CHECKOV_VERSION=3.2.285
ARG SKAFFOLD_VERSION=v2.15.0
ARG COSIGN_VERSION=v2.5.2
ARG TFSEC_VERSION=v1.28.11
ARG TERRAFORM_VERSION=1.9.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    && rm -rf /var/lib/apt/lists/*

# trivy
RUN curl -sSfL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
    | tar -xz -C /usr/local/bin trivy

# tfsec
RUN curl -sSfL "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64" \
    -o /usr/local/bin/tfsec && chmod +x /usr/local/bin/tfsec

# checkov
RUN python3 -m venv /opt/checkov && \
    /opt/checkov/bin/pip install --no-cache-dir checkov==${CHECKOV_VERSION} && \
    ln -s /opt/checkov/bin/checkov /usr/local/bin/checkov

# skaffold
RUN curl -sSfL "https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64" \
    -o /usr/local/bin/skaffold && chmod +x /usr/local/bin/skaffold

# cosign
RUN curl -sSfL "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64" \
    -o /usr/local/bin/cosign && chmod +x /usr/local/bin/cosign

# tfenv + terraform
RUN git clone --depth 1 https://github.com/tfutils/tfenv.git /usr/local/tfenv && \
    ln -s /usr/local/tfenv/bin/tfenv /usr/local/bin/tfenv && \
    ln -s /usr/local/tfenv/bin/terraform /usr/local/bin/terraform && \
    tfenv install ${TERRAFORM_VERSION} && \
    tfenv use ${TERRAFORM_VERSION}

RUN trivy --version && \
    tfsec --version && \
    checkov --version && \
    skaffold version && \
    cosign version && \
    terraform version

CMD ["cat"]
