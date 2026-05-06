FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/trivy:0.60.0 AS trivy
FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/tfsec:v1.28.11 AS tfsec
FROM harbor.tuxgrid.com/gcr.io/k8s-skaffold/skaffold:v2.15.0 AS skaffold
FROM harbor.tuxgrid.com/docker.io/hashicorp/terraform:1.9.0 AS terraform

FROM harbor.tuxgrid.com/docker.io/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    CHECKOV_VERSION=3.2.285

ENV COSIGN_VERSION=v2.5.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    wget \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=trivy    /usr/local/bin/trivy   /usr/local/bin/trivy
COPY --from=tfsec    /usr/bin/tfsec         /usr/local/bin/tfsec
COPY --from=skaffold /usr/bin/skaffold      /usr/local/bin/skaffold
COPY --from=terraform /bin/terraform        /usr/local/bin/terraform

RUN wget -qO /usr/local/bin/cosign \
    https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64 \
    && chmod +x /usr/local/bin/cosign

RUN pip3 install --no-cache-dir --break-system-packages checkov==${CHECKOV_VERSION}

RUN trivy --version && \
    tfsec --version && \
    cosign version && \
    skaffold version && \
    terraform version && \
    checkov --version

CMD ["cat"]
