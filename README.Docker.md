# Running Eraser with Docker

This is a self-contained, containerized copy of Eraser. It runs the web
dashboard and persists all your data (config, send history, in-progress jobs)
in a Docker volume.

## Quick start

```bash
docker compose up -d --build
```

Then open the dashboard at:

```
http://<your-server-ip>:8080
```

The first time you open it, a setup wizard walks you through your profile and
Gmail SMTP settings, then saves them to the persistent volume.

## Changing the port

The container always listens on **8080** internally. To expose it on a
different host port, edit `.env`:

```env
ERASER_PORT=8081
```

That maps `8081:8080`, so you'd reach the dashboard at
`http://<your-server-ip>:8081`. Apply it with:

```bash
docker compose up -d
```

## Reaching it over the network

The container listens on `0.0.0.0` (all interfaces) via the `ERASER_HOST`
environment variable, so the dashboard is reachable from other machines at
`<server-ip>:<port>` — not just localhost. Make sure your server's firewall /
security group allows the chosen port.

> **Security note:** the dashboard has no login. If the server is exposed to
> the public internet, put it behind a reverse proxy with authentication
> (or a VPN / private network), since it can send email on your behalf and
> stores your personal profile.

## Data persistence

Everything mutable lives in the `eraser-data` named volume, mounted at `/data`
inside the container (`HOME=/data`):

- `/data/.eraser/config.yaml` — your profile + email credentials
- `/data/.eraser/history.db` — send history
- `/data/.eraser/pending_job.json` — resumable in-progress send job

Inspect or back it up:

```bash
docker volume inspect eraser_eraser-data
docker run --rm -v eraser_eraser-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/eraser-data-backup.tar.gz -C /data .
```

### Seeding an existing config

If you already have a `config.yaml`, copy it into the volume before starting:

```bash
docker compose up -d            # creates the volume
docker cp ./config.yaml eraser:/data/.eraser/config.yaml
docker compose restart
```

## Common commands

```bash
docker compose logs -f          # follow logs
docker compose restart          # restart
docker compose down             # stop & remove container (volume kept)
docker compose down -v          # stop & ALSO delete the data volume
docker compose up -d --build    # rebuild after code changes
```

## Notes

- Browser-automation commands (`fill`, `confirm` form solving) need Chrome,
  which is **not** included in this lean image. The email-sending dashboard
  works fully without it.
- This directory is an isolated copy of the main repo; building/running it
  here does not affect your local `eraser_family` checkout.
