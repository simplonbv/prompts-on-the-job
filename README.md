# Prompts on the job

The project repository for **Prompts on the job**: how a municipality installs
it. Not the code — the theme, the settings and the setup that put two
repositories together:

| | |
| --- | --- |
| **Kik-OS**, the platform | [cornae/kik-os](https://github.com/cornae/kik-os), installed as a package with its `project` extra: the installation's settings, sign-in, administration and first-run setup (`kik_os.project`) |
| **Patterns**, the front end's bottom layer | [cornae/patterns](https://github.com/cornae/patterns) |
| **Prompts**, the app | [cornae/kik-prompts](https://github.com/cornae/kik-prompts), a package that registers itself with Kik-OS |

No Kikaron: the image installs these three packages and nothing else.
Which version of each goes in is pinned in [`versions.env`](versions.env).

## What is here

- [`theme/vng/`](theme/vng/style/all.css) — the VNG theme: custom properties
  only, no selectors, linked between Kik-OS's stylesheet and its components.
- [`docker/`](docker/) — the image (`Dockerfile`), what it does at start
  (`entrypoint.sh`: migrate, build the stylesheet, gather the static files,
  make the hub, its administrator and the language model) and nginx in front.
- [`compose.yaml`](compose.yaml) — one installation: Postgres, Redis, the app
  (one daphne process for HTTP and the assistant's sockets) and nginx.
- [`.env.example`](.env.example) — the settings: the host, the hub and its
  first administrator, the database, the language model, mail.

## Install

```bash
cp .env.example .env          # fill in HOST, KIK_SECRET_KEY, the passwords, the admin, the model
export GITHUB_TOKEN=…         # read access to cornae/kik-os, patterns, kik-prompts
docker compose --env-file versions.env --env-file .env build \
    --secret id=github_token,env=GITHUB_TOKEN
docker compose --env-file versions.env --env-file .env up -d
```

With **podman-compose**, which takes one `--env-file`, join the two first:
`cat versions.env .env > .env.all` and pass `--env-file .env.all`. On an
SELinux host the containers sharing the static volume run with
`label=disable` (in `compose.yaml`), otherwise nginx cannot read it.

The site answers on port 8080 (`PORT`); put TLS in front of it. The first
start migrates a fresh database, makes the hub (`KIK_HUB_NAME`), makes
`KIK_ADMIN_EMAIL` its administrator with `KIK_ADMIN_PASSWORD`, and adds the
language model from `KIK_LLM_*`. Every later start changes none of that.

People and their roles, the hub and the language models are managed under
`/beheer/` (the administration), as the first administrator.

The repositories are private until the handover to the VNG, hence the token;
it is used in one build step and not kept in the image.

## Upgrade

Bump `KIK_OS_REF`, `PATTERNS_REF` and/or `KIK_PROMPTS_REF` in `versions.env`,
then build and `up -d` again. `setup` migrates, rebuilds the stylesheet and
gathers the static files on every start.

## Status

2026-11-18: built from Kik-OS, Patterns and kik-prompts alone, and run end to
end on a fresh database (podman). The Helm chart for Haven comes later, next
to the compose file.

Licence: EUPL-1.2 (see `LICENSE`).
