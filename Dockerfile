FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/trivy:0.60.0 AS trivy
FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/tfsec:v1.28.11 AS tfsec
FROM harbor.tuxgrid.com/gcr.io/k8s-skaffold/skaffold:v2.15.0 AS skaffold
FROM harbor.tuxgrid.com/docker.io/hashicorp/terraform:1.9.0 AS terraform
FROM harbor.tuxgrid.com/ghcr.io/sigstore/cosign/cosign:v2.5.2 AS cosign

FROM harbor.tuxgrid.com/docker.io/python:3.12-slim AS checkov-build
ARG CHECKOV_VERSION=3.2.285
RUN pip install --no-cache-dir checkov==${CHECKOV_VERSION}

FROM harbor.tuxgrid.com/platform/deploy-base:latest

COPY --from=trivy     /usr/local/bin/trivy  /usr/local/bin/trivy
COPY --from=tfsec     /usr/bin/tfsec        /usr/local/bin/tfsec
COPY --from=skaffold  /usr/bin/skaffold     /usr/local/bin/skaffold
COPY --from=terraform /bin/terraform        /usr/local/bin/terraform
COPY --from=cosign    /ko-app/cosign        /usr/local/bin/cosign
COPY --from=checkov-build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/dist-packages
COPY --from=checkov-build /usr/local/bin/checkov /usr/local/bin/checkov
RUN sed -i '1s|.*|#!/usr/bin/python3|' /usr/local/bin/checkov

RUN trivy --version && \
    tfsec --version && \
    cosign version && \
    skaffold version && \
    terraform version && \
    checkov --version

CMD ["cat"]
