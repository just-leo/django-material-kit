FROM python:3.11-slim as dependencies

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc

COPY requirements.txt .
# install python dependencies
RUN pip install --upgrade pip
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# --- Release with Alpine ----
FROM python:3.11-slim as release

ENV PROJECT_DIR=/opt/app
ENV APPUSER=app

WORKDIR ${PROJECT_DIR}

RUN addgroup --gid 999 ${APPUSER} && \
    adduser --uid 999 --system --shell /bin/false --disabled-password --group ${APPUSER}

# ---- Copy Files/Build ----
COPY --chown=${APPUSER} --from=dependencies /app/wheels ./wheels
COPY --chown=${APPUSER} . .

# Install app dependencies
RUN pip install --no-cache ./wheels/*

# ---- Running migrations ----
RUN python manage.py migrate

EXPOSE 5005

USER ${APPUSER}

# gunicorn
CMD ["gunicorn", "--config", "gunicorn-cfg.py", "core.wsgi"]
