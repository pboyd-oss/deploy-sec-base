ARG TRIVY_VERSION
FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/trivy:${TRIVY_VERSION} AS trivy

ARG TFSEC_VERSION
FROM harbor.tuxgrid.com/ghcr.io/aquasecurity/tfsec:${TFSEC_VERSION} AS tfsec

ARG PYTHON_VERSION
FROM harbor.tuxgrid.com/docker.io/python:${PYTHON_VERSION} AS checkov-build
ARG CHECKOV_VERSION
RUN pip install --no-cache-dir checkov==${CHECKOV_VERSION}

FROM harbor.tuxgrid.com/platform/deploy-base:latest

COPY --from=trivy  /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=tfsec  /usr/bin/tfsec       /usr/local/bin/tfsec
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
