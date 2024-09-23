FROM debian:bullseye AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LIBRDKAFKA_VERSION="2.0.2" \
    DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /tmp/librdkafka
WORKDIR /tmp/librdkafka
# hadolint ignore=DL3008,DL3015
RUN apt-get update && apt-get install -y curl build-essential make lsb-release wget zlib1g-dev libzstd-dev && (curl -q -L "https://github.com/edenhill/librdkafka/archive/refs/tags/v${LIBRDKAFKA_VERSION}.tar.gz" | tar -xz --strip-components=1 -f -) && ./configure && make && make install


FROM python:3.11 AS base-root
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=on \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    POETRY_HOME="/opt/poetry" \
    PATH=/opt/poetry/bin:$PATH \
    POETRY_VIRTUALENVS_CREATE=false
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN (curl -sSL https://install.python-poetry.org | python -) && mkdir -p /app && useradd -ms /bin/bash user && chown -R user:user /app && chmod 755 /app
WORKDIR /app


FROM base-root AS base-arm64
COPY --from=builder /usr/local/lib/librdkafka* /usr/local/lib/
COPY --from=builder /usr/local/include/librdkafka/ /usr/local/include/librdkafka/

FROM base-root AS base-amd64

# hadolint ignore=DL3006
FROM base-${TARGETARCH} AS base
ENV HELM_VERSION=v3.14.0
# Install helm
RUN curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64
COPY pyproject.toml poetry.lock /app/
RUN poetry export --only main -o requirements.txt && pip install --no-cache-dir -r requirements.txt

FROM base as test
RUN poetry export -o dev-requirements.txt --with dev && pip install --no-cache-dir -r dev-requirements.txt
USER user
ENTRYPOINT [ "make" ]

FROM base as app
USER user
COPY cyberint /app/cyberint
