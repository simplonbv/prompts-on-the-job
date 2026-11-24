#!/usr/bin/env bash
# SPDX-License-Identifier: EUPL-1.2
#
#   potj-entrypoint setup   migrate, build the stylesheet, gather the static
#                           files, make the hub, its administrator and the
#                           language model when missing (kik_setup)
#   potj-entrypoint web     daphne: HTTP and the assistant's sockets
#   potj-entrypoint <cmd>   anything else: django-admin <cmd>
set -euo pipefail
M="uv run -m django"

export KIK_HOSTS="${HOST}"
export KIK_CSRF_ORIGINS="${ORIGIN:-https://$HOST}"

setup() {
    $M migrate --noinput
    # Hand the static files to nginx (the shared volume), refreshed on every
    # start so an upgraded image never serves the previous version's files.
    $M collectstatic --noinput --clear -v 0
    $M kik_setup
}

case "${1:-web}" in
    setup) setup ;;
    web)   exec uv run daphne -b 0.0.0.0 -p 8000 --proxy-headers kik_os.project.asgi:application ;;
    *)     exec $M "$@" ;;
esac
