# Prompts on the job

The project repository for **Prompts on the job**: how a municipality installs
it. Not the code — the theme, the settings and the setup that put two
repositories together:

| | |
| --- | --- |
| **Kik-OS**, the platform | runs from [cornae/kikaron](https://github.com/cornae/kikaron) with only Kik-OS and Prompts switched on, until Kik-OS is a platform of its own (see [cornae/kik-os](https://github.com/cornae/kik-os)) |
| **Prompts**, the app | [cornae/kik-prompts](https://github.com/cornae/kik-prompts), whose `prompts/` replaces kikaron's own copy in the image |

Which commit of each goes in is pinned in [`versions.env`](versions.env).

## What is here

- [`theme/vng/`](theme/vng/style/all.css) — the VNG theme: custom properties
  only, no selectors. It becomes the hub's only theme.
- [`docker/`](docker/) — the image (`Dockerfile`), what it does at start
  (`entrypoint.sh`: migrate, create the hub, build the CSS) and nginx in front.
- [`compose.yaml`](compose.yaml) — one installation: Postgres, Redis, the app
  (HTTP and WebSockets) and nginx.
- [`.env.example`](.env.example) — the settings: the host, the hub and its
  first administrator, and the Kik-OS switches (the same as
  `kik-os.cornae.com`'s: `STYLE_BUNDLE=kik-os`, `REGISTERED_APPS=prompts`,
  `BILLING=False`, …).

## Install

```bash
cp .env.example .env          # fill in HOST, SECRET_KEY, passwords, admin
export GITHUB_TOKEN=…         # read access to cornae/kikaron, kik-prompts, kik-os, patterns
docker compose --env-file versions.env --env-file .env build \
    --secret id=github_token,env=GITHUB_TOKEN
docker compose --env-file versions.env --env-file .env up -d
```

With **podman-compose**, which takes one `--env-file`, join the two first:
`cat versions.env .env > .env.all` and pass `--env-file .env.all`. On an
SELinux host the containers sharing the static volume run with
`label=disable` (in `compose.yaml`), otherwise nginx cannot read it.

The site answers on port 8080; put TLS in front of it. The first start
migrates a fresh database, creates the hub (`HUB_SLUG`) as an Apps hub with
Prompts, makes `ADMIN_EMAIL` its administrator and sets the VNG theme.

The repositories are private until the handover to the VNG, hence the token;
it is used in one build step and not kept in the image.

## Two-step sign-in is off at first

The first administrator (`ADMIN_EMAIL`) starts **without** two-step sign-in.
Kik-OS sends its code by e-mail, and a new installation has no mail relay yet
(`EMAIL_BACKEND` is the console), so with it on nobody could sign in. Set up
the mail (`EMAIL_BACKEND` and the SMTP settings in `.env`) and then switch it on
under Preferences → Account; people the administrator invites later start with
the platform's default, which is on. Until then the first administrator's
account is protected by its password alone: use a long one, and put TLS in front
of the site.

## Upgrade

Bump `KIKARON_REF` and/or `KIK_PROMPTS_REF` in `versions.env`, then build and
`up -d` again. `setup` migrates and rebuilds the CSS on every start.

## Status

First version, 2026-11-17. Not yet run end to end: the image builds from
private repositories and a fresh kikaron database needs its bootstrap migrate
(handled by `entrypoint.sh`), so the first real install is also its test. The
Helm chart for Haven comes later, next to the compose file.

Licence: EUPL-1.2 (see `LICENSE`).
