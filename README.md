# web-sweethome3d-docker

Run [Sweet Home 3D](https://www.sweethome3d.com/) — the free, open-source
floor-plan and interior-design app — as a containerized web app, accessible
from any browser on your network.

It's built on top of [jlesage/docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui),
which packages the desktop GUI and serves it over HTTP (via noVNC) and,
optionally, plain VNC.

## Quick start

```bash
git clone https://github.com/dermonty/web-sweethome3d-docker.git
cd web-sweethome3d-docker
docker compose up -d --build
```

Then open `http://<your-server-ip>:5800` in a browser.

## Persisting your projects

Everything Sweet Home 3D saves (plans, preferences) lives under `/config`
inside the container, which `docker-compose.yml` maps to a `./config` folder
next to the compose file. **Without this volume, your floor plans are lost
every time the container is recreated or updated.** Keep that mapping in
place, and back up `./config` like you would any other important data.

## Configuration

Set these under `environment:` in `docker-compose.yml`:

| Variable | Purpose | Default |
|---|---|---|
| `USER_ID` / `GROUP_ID` | Match the host user who should own `./config` (run `id` on the host) | `1000` / `1000` |
| `TZ` | Timezone, e.g. `Europe/Paris` | `Etc/UTC` |
| `KEEP_APP_RUNNING` | Restart Sweet Home 3D automatically if it crashes | `1` |
| `SECURE_CONNECTION` | Serve over HTTPS instead of plain HTTP | `0` |
| `WEB_AUTHENTICATION` | Require a login page (needs `SECURE_CONNECTION=1`) | `0` |

The full list of variables is documented in the
[baseimage-gui README](https://github.com/jlesage/docker-baseimage-gui#environment-variables).

If you're only reaching this container from your home network, the defaults
are fine. If you expose it beyond your LAN (e.g. through a reverse proxy),
turn on `SECURE_CONNECTION` and `WEB_AUTHENTICATION`.

## Ports

| Port | Purpose |
|---|---|
| 5800 | Web UI — the only one enabled by default |
| 5900 | VNC, for a VNC client instead of the browser — uncomment in `docker-compose.yml` to enable |

## License

This project is licensed under the GPL-3.0 (see `LICENSE`). Sweet Home 3D
itself is developed by [eTeks](https://www.sweethome3d.com/) and distributed
under the GPL.
