# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: EUPL-1.2
#
# Prompts on the job: the Kik-OS platform (from cornae/kikaron, run with only
# Kik-OS and Prompts switched on) with Prompts from cornae/kik-prompts.
#
# Both repositories are private until the handover, so the build needs a
# GitHub token with read access to cornae/kikaron, cornae/kik-prompts and
# cornae/kik-os (a pip dependency of kikaron), passed as a build secret:
#
#   docker compose build --secret id=github_token,env=GITHUB_TOKEN
#
# The token is used inside one RUN step and is not left in any layer.
FROM python:3.12-slim

ARG KIKARON_REF
ARG KIK_PROMPTS_REF

RUN apt-get update \
 && apt-get install -y --no-install-recommends git build-essential libpq-dev curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /srv
RUN --mount=type=secret,id=github_token,required=true \
    set -eu; \
    TOKEN=$(cat /run/secrets/github_token); \
    export GIT_CONFIG_COUNT=3 \
      GIT_CONFIG_KEY_0="url.https://x-access-token:${TOKEN}@github.com/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/" \
      GIT_CONFIG_KEY_1="url.https://x-access-token:${TOKEN}@github.com/.insteadOf" GIT_CONFIG_VALUE_1="ssh://git@github.com/" \
      GIT_CONFIG_KEY_2="url.https://x-access-token:${TOKEN}@github.com/.insteadOf" GIT_CONFIG_VALUE_2="git@github.com:"; \
    git clone -q https://github.com/cornae/kikaron.git app; \
    git -C app checkout -q --detach "$KIKARON_REF"; \
    git clone -q https://github.com/cornae/kik-prompts.git kik-prompts; \
    git -C kik-prompts checkout -q --detach "$KIK_PROMPTS_REF"; \
    # The app comes from kik-prompts, not from kikaron's own copy.
    rm -rf app/apps/prompts; \
    cp -r kik-prompts/prompts app/apps/prompts; \
    pip install --no-cache-dir -r app/requirements.txt; \
    rm -rf app/.git kik-prompts

WORKDIR /srv/app
COPY theme/vng /srv/app/static/themes/vng-potj
COPY docker/entrypoint.sh /usr/local/bin/potj-entrypoint
RUN chmod +x /usr/local/bin/potj-entrypoint \
 && useradd --system --home /srv/app potj \
 && mkdir -p /srv/static \
 && chown -R potj:potj /srv/app /srv/static
USER potj

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["potj-entrypoint"]
CMD ["web"]
