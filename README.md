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

## Mobile / tablet usage

The web UI is patched to be responsive on phones and tablets:

- The landing page is a small launcher that adapts to any screen
  width (works on a 5" phone as well as on a 4K monitor).
- The remote desktop is rendered at `DISPLAY_WIDTH x DISPLAY_HEIGHT`
  (1920×1080 by default) and **auto-scaled** to fit the browser
  viewport, so you no longer have to pinch-zoom and pan around a
  tiny shrunken desktop.
- Touch gestures are tuned for the VNC canvas: pinch-zoom is
  disabled on the canvas (it was fighting with drag/scroll), and
  long-press sends a right-click.
- A reconnect-on-disconnect default means a brief network blip on
  a phone won't kick you out.

Open `http://<your-server-ip>:5800` on your phone, tap **Open
Sweet Home 3D**, and the desktop fills your screen. For very small
phones (under 5"), rotating to landscape is more comfortable.

> **Note:** Sweet Home 3D itself is a Java desktop application. What
> you see in the browser is a live, hardware-accelerated stream of
> that desktop — not a native mobile UI. Touch targets and font
> sizes are those of the desktop app, just rendered at a size that
> fits your screen. For a truly native mobile UI you'd need
> [Sweet Home 3D JS](https://github.com/cincheo/sh3do-getting-started),
> which is a different (and much more limited) project.

### Tuning the mobile experience

| Variable | Purpose | Default |
|---|---|---|
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | The internal desktop size the app renders at. Larger = more detail, more bandwidth. | `1920` / `1080` |
| `KEEP_APP_RUNNING` | Auto-restart Sweet Home 3D if it crashes | `1` |

If the desktop feels blurry on your phone, raise `DISPLAY_WIDTH`/
`DISPLAY_HEIGHT` (e.g. `2560x1440`). If the stream lags on a slow
link, lower them (e.g. `1366x768`).

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
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | Internal desktop resolution; mobile UI auto-scales to fit | `1920` / `1080` |

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

## How the mobile UI is built (for the curious)

The baseimage's noVNC page was designed for desktop browsers and
doesn't auto-fit a phone screen. We patch it at build time with
three small changes, all under `rootfs/`:

1. **`rootfs/opt/novnc/patches/01-mobile-defaults.sh`** — `sed`
   swap in `ui.js` to change the default `resize` setting from
   `'off'` to `'scale'`. This is the single change that makes the
   remote desktop auto-fit the browser.
2. **`rootfs/opt/novnc/index.html`** — a self-contained responsive
   launcher that replaces the baseimage's fixed-width landing page.
3. **`rootfs/opt/novnc/app/styles/responsive.css` + nginx override**
   — touch-action, viewport-fit, and full-screen settings panel for
   the VNC page itself. Wired in via a
   `/etc/cont-init.d/99-nginx-override.sh` hook so the baseimage's
   auto-generated nginx config picks up our `include`.

To customize further, edit those files and `docker compose up -d
--build`.

## License

This project is licensed under the GPL-3.0 (see `LICENSE`). Sweet Home 3D
itself is developed by [eTeks](https://www.sweethome3d.com/) and distributed
under the GPL.
