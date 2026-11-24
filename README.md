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
  It is the theme kik-os.cornae.com runs (Kikaron's `static/themes/vng-potj`),
  kept level with `tools/sync-theme-from-kikaron.sh`; which commit it came
  from is in [`theme/vng/SYNC.md`](theme/vng/SYNC.md).
- [`container/`](container/) — the image (`Containerfile`), what it does at start
  (`entrypoint.sh`: migrate, build the stylesheet, gather the static files,
  make the hub, its administrator and the language model) and nginx in front.
- [`compose.yaml`](compose.yaml) — one installation: Postgres, Redis, the app
  (one daphne process for HTTP and the assistant's sockets), nginx and traefik.
- [`.env.example`](.env.example) — the settings: the host, the hub and its
  first administrator, the database, the language model, mail.

## Install

```bash
cp .env.example .env          # fill in HOST, KIK_SECRET_KEY, the passwords, the admin, the model
export GITHUB_TOKEN=$(gh auth token)   # or a classic token with the repo scope: see below
docker compose build --secret id=github_token,env=GITHUB_TOKEN
docker compose up -d
```

The site answers on port 8000; put TLS in front of it (Traefik can
[handle that automatically](https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/)). The first
start intialises a fresh database, makes the hub (`KIK_HUB_NAME`), makes
`KIK_ADMIN_EMAIL` its administrator with `KIK_ADMIN_PASSWORD`, and adds the
language model from `KIK_LLM_*`. Every later start changes none of that.

People and their roles, the hub and the language models are managed under
`/beheer/` (the administration), as the first administrator.

The repositories are private until the handover to the VNG, hence the token;
it is used in one build step and not kept in the image. It must read
`cornae/kik-os`, `cornae/patterns` and `cornae/kik-prompts` — accept the
collaborator invitation for each first. They belong to a personal account,
not an organisation, so a **fine-grained** token cannot reach them: use
`gh auth token` (after `gh auth login`) or a classic token with the `repo`
scope. Nothing else is fetched; Kikaron is not needed.

## Upgrade

Update the `rev` values in the `[tool.uv.sources]` section in
[`pyproject.toml`](./pyproject.toml) and run `uv lock`. Then run `docker compose
build` and `docker compose up -d --force-recreate` to build and deploy the new
 version.

## Status

2026-11-18: built from Kik-OS, Patterns and kik-prompts alone (no build cache),
installed on a fresh database and run end to end (podman): sign-in, every
Prompts screen, writing, rating and commenting on prompts (comment threads
update live for every reader), the assistant workspace, Check and Test answered
live, challenges, help — no errors. The Helm chart for Haven comes later, next
to the compose file.

Licence: EUPL-1.2 (see `LICENSE`).
