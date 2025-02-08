FROM python:3.11 AS base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=on \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    POETRY_HOME="/opt/poetry" \
    PATH=/opt/poetry/bin:$PATH \
    POETRY_VIRTUALENVS_CREATE=false
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN (curl -sSL https://install.python-poetry.org | python -) && poetry self add poetry-plugin-export &&  \
    mkdir -p /app && useradd -ms /bin/bash user && chown -R user:user /app && chmod 755 /app
WORKDIR /app
COPY pyproject.toml poetry.lock /app/
RUN poetry export -o requirements.txt --only main && pip install --no-cache-dir  -r requirements.txt


FROM base as test
# hadolint ignore=DL3006
ENV HELM_VERSION=v3.14.0
# Install helm
RUN curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

RUN poetry export -o dev-requirements.txt --with dev && pip install --no-cache-dir -r dev-requirements.txt
USER user
ENTRYPOINT [ "make" ]

FROM base as app
USER user
COPY cyberint /app/cyberint
