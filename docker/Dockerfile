# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: EUPL-1.2
#
# Prompts on the job: Kik-OS (cornae/kik-os, with its `project` extra) and
# Prompts (cornae/kik-prompts) on the Patterns (cornae/patterns) — three
# packages, nothing else.
#
# The repositories are private until the handover, so the build needs a
# GitHub token with read access to cornae/kik-os, cornae/patterns and
# cornae/kik-prompts, passed as a build secret:
#
#   docker compose build --secret id=github_token,env=GITHUB_TOKEN
#
# The token is used inside one RUN step and is not left in any layer.
FROM python:3.12-slim

ARG KIK_OS_REF
ARG PATTERNS_REF
ARG KIK_PROMPTS_REF

RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl \
 && rm -rf /var/lib/apt/lists/*

RUN --mount=type=secret,id=github_token,required=true \
    set -eu; \
    TOKEN=$(cat /run/secrets/github_token); \
    export GIT_CONFIG_COUNT=2 \
      GIT_CONFIG_KEY_0="url.https://x-access-token:${TOKEN}@github.com/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/" \
      GIT_CONFIG_KEY_1="url.https://x-access-token:${TOKEN}@github.com/.insteadOf" GIT_CONFIG_VALUE_1="ssh://git@github.com/"; \
    pip install --no-cache-dir \
        "kik-os[project] @ git+https://github.com/cornae/kik-os.git@${KIK_OS_REF}" \
        "patterns @ git+https://github.com/cornae/patterns.git@${PATTERNS_REF}" \
        "kik-prompts @ git+https://github.com/cornae/kik-prompts.git@${KIK_PROMPTS_REF}"

COPY theme/vng /srv/theme/vng
COPY docker/entrypoint.sh /usr/local/bin/potj-entrypoint
RUN chmod +x /usr/local/bin/potj-entrypoint \
 && useradd --system --home /srv/data potj \
 && mkdir -p /srv/data /srv/static \
 && chown -R potj:potj /srv/data /srv/static
USER potj
WORKDIR /srv/data

ENV PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=kik_os.project.settings \
    KIK_DATA_DIR=/srv/data \
    KIK_STATIC_ROOT=/srv/static \
    KIK_THEME_DIR=/srv/theme/vng
ENTRYPOINT ["potj-entrypoint"]
CMD ["web"]
