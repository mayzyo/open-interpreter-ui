FROM python:3.11-slim-bullseye as builder

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        wget \
        unzip

RUN wget -q -O /tmp/websocketd.zip \
    https://github.com/joewalnes/websocketd/releases/download/v0.2.9/websocketd-0.2.9-linux_amd64.zip \
    && unzip /tmp/websocketd.zip -d /tmp/websocketd && mv /tmp/websocketd/websocketd /usr/bin
    
RUN pip install poetry

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

COPY pyproject.toml poetry.lock ./
RUN touch README.md

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --without dev --no-root



FROM python:3.11-slim-bullseye as runtime

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
copy --from=builder /usr/bin/websocketd /usr/bin/websocketd

COPY . .

EXPOSE 8080

ENTRYPOINT ["websocketd", "--port=8080", "python", "app.py"]