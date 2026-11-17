#!/usr/bin/env bash
# SPDX-License-Identifier: EUPL-1.2
#
#   potj-entrypoint setup   migrate, create the hub on first start, build the CSS
#   potj-entrypoint web     gunicorn (HTTP)
#   potj-entrypoint asgi    daphne (WebSockets)
#   potj-entrypoint <cmd>   anything else: manage.py <cmd>
set -euo pipefail
cd /srv/app
M="python manage.py"

export ALLOWED_HOSTS="${ALLOWED_HOSTS:-$HOST,localhost,127.0.0.1}"
export APPS_HOSTS="${APPS_HOSTS:-$HOST}"
export CSRF_TRUSTED_ORIGINS="${CSRF_TRUSTED_ORIGINS:-https://$HOST}"

setup() {
    # A fresh database: kikaron's first migrate cannot run under the tenant
    # router (contacts.0017's cross-schema foreign key), so the very first one
    # runs without it — kikaron docs/local-dev-setup.md, "The database".
    if ! $M shell -c "from django.db import connection; import sys; sys.exit(0 if 'django_migrations' in connection.introspection.table_names() else 1)" 2>/dev/null; then
        echo "first start: bootstrap migrate"
        DJANGO_SETTINGS_MODULE=scripts.bootstrap_settings $M migrate --skip-checks --noinput
    fi
    $M migrate --noinput

    # The one hub: an Apps hub with Prompts, its first administrator, and the
    # VNG theme as its only theme.
    if ! $M shell -c "import sys; from configuration.models import Organisation; sys.exit(0 if Organisation.objects.using('default').filter(slug='$HUB_SLUG').exists() else 1)"; then
        echo "first start: creating hub $HUB_SLUG"
        $M seed_smoke_fixture --slug "$HUB_SLUG" --name "$HUB_NAME" \
            --email "$ADMIN_EMAIL" --password "$ADMIN_PASSWORD" --skip-checks
        $M hub_face "$HUB_SLUG" apps --apps prompts
    fi
    $M shell -c "
from configuration.models import Organisation
Organisation.objects.using('default').filter(slug='$HUB_SLUG').update(
    extra_themes=['vng-potj'], themes_exclusive=True)
"
    $M create_org_databases
    python scripts/compile_sass.py
    # Hand the compiled tree to nginx (the shared volume).
    rm -rf /srv/static/* && cp -a static/. /srv/static/
}

case "${1:-web}" in
    setup) setup ;;
    web)   exec gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 2 --threads 4 --timeout 120 ;;
    asgi)  exec daphne -b 0.0.0.0 -p 8001 core.asgi:application ;;
    *)     exec $M "$@" ;;
esac
