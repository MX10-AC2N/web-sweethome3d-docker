# web-sweethome3d-docker

Run [Sweet Home 3D](https://www.sweethome3d.com/) — the free, open-source
floor-plan and interior-design app — as a containerized web app, accessible
from any browser on your network.

This project ships **two complementary services** behind a single
`docker compose up`:

| Service | Port | What it is | Best for |
|---|---|---|---|
| `sweethome3d` (VNC) | `5800` | The full Java desktop app streamed over VNC | Complex edits, photo rendering, all plugins |
| `sweethome3d-web` (JS) | `5801` | The HTML5/JavaScript/WebGL port, served via PHP | **Phones, tablets, touch devices** |

Both share the same home directory structure (`.sh3d` / `.sh3x` are
the same XML format) so you can design on PC, walk away with your
phone, and keep working.

It's built on top of [jlesage/docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui)
for the VNC service, and uses the official
[SweetHome3DJS](https://sourceforge.net/projects/sweethome3d/files/SweetHome3DJS/)
PHP server for the web editor.

## Quick start

```bash
git clone https://github.com/dermonty/web-sweethome3d-docker.git
cd web-sweethome3d-docker
docker compose up -d --build
```

Then open:

- `http://<your-server-ip>:5800` — desktop app (VNC)
- `http://<your-server-ip>:5801` — web editor (HTML5, touch-friendly)

## The two services

### `sweethome3d` (port 5800) — the VNC desktop app

The full Java Sweet Home 3D app, served over noVNC. Works on any
device with a browser and a mouse/keyboard, but it's a **desktop**
experience so it's clunky on touch screens (tiny buttons, requires
pinch-zoom on a phone).

The baseimage's noVNC page was designed for desktop browsers, so we
patch it at build time with three small changes (all under `rootfs/`):

1. **`rootfs/opt/novnc/patches/01-mobile-defaults.sh`** — `sed`
   swap in `ui.js` to change the default `resize` setting from
   `'off'` to `'scale'`. This is the single change that makes the
   remote desktop auto-fit the browser.
2. **`rootfs/opt/novnc/index.html`** — a self-contained responsive
   launcher that replaces the baseimage's fixed-width landing page.
3. **`rootfs/opt/novnc/app/styles/responsive.css` + nginx override**
   — touch-action, viewport-fit, and full-screen settings panel for
   the VNC page itself.

On a phone, this gets you a usable-but-not-great view. For real
mobile editing, use the second service.

### `sweethome3d-web` (port 5801) — the HTML5 web editor

A pure HTML5 / WebGL port of Sweet Home 3D that runs entirely in
the browser. **Truly responsive, genuinely touch-friendly**, no
VNC stream. Works the same on a 5" phone as on a 4K monitor.

The web editor is built on top of the official
[SweetHome3DJS PHP server](https://sourceforge.net/projects/sweethome3d/files/SweetHome3DJS/).
The Docker image (`Dockerfile.php`) is a self-contained nginx +
php-fpm stack, supervised by supervisord. At build time it:

1. Downloads the official `SweetHome3DJS-X.Y.Z.zip` archive.
2. Drops the JS engine, the furniture catalog, and the 3 PHP API
   scripts into `/opt/sh3djs/`.
3. Injects our `mobile.css` into the upstream `index.html` to make
   the editor's UI fit small screens.
4. Replaces the upstream's bare-bones landing page with a
   responsive one (`/opt/sh3djs/landing.html`) that lists your
   saved plans, has a "New empty plan" button, and links to the
   VNC service.

#### What works in the web editor

✅ Full 2D plan editing (walls, rooms, dimensions, texts)
✅ Furniture catalog (default ~600 items, multilingual)
✅ 3D view (orbit, walk, top-down)
✅ Save / open plans (stored as `.sh3x` files on the server)
✅ Multi-language UI
✅ Touch gestures (pinch-zoom, drag, long-press = right-click)

#### What doesn't work in the web editor

❌ Photo / video rendering (use the VNC service for that)
❌ Third-party plugins (only the upstream defaults are available)
❌ Importing some advanced `.sh3d` files (the JS port doesn't
   support all features of the desktop format yet)

#### Sharing plans between the two services

Both services store plans as files. By default they use different
folders on the host (`./config/` and `./plans/`) so they're
isolated. To share, you have two options:

- **Symlink** (simplest): `ln -s ./config ./plans` (or vice versa).
  Both containers will then read/write the same files.
- **Reconfigure** the volumes in `docker-compose.yml` to mount
  the same path into both containers.

The file formats are compatible — `.sh3x` (web) is the same XML
zipped format as `.sh3d` (desktop). The desktop app opens `.sh3x`
files just fine; the web editor opens `.sh3d` files just fine.

## Configuration

Set these under `environment:` in `docker-compose.yml`:

| Variable | Service | Purpose | Default |
|---|---|---|---|
| `USER_ID` / `GROUP_ID` | VNC | Match the host user who should own `./config` | `1000` / `1000` |
| `TZ` | both | Timezone, e.g. `Europe/Paris` | `Etc/UTC` |
| `KEEP_APP_RUNNING` | VNC | Restart Sweet Home 3D automatically if it crashes | `1` |
| `SECURE_CONNECTION` | VNC | Serve over HTTPS instead of plain HTTP | `0` |
| `WEB_AUTHENTICATION` | VNC | Require a login page (needs `SECURE_CONNECTION=1`) | `0` |
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | VNC | Internal desktop resolution; mobile UI auto-scales to fit | `1920` / `1080` |

The full list of variables is documented in the
[baseimage-gui README](https://github.com/jlesage/docker-baseimage-gui#environment-variables).

If you're only reaching this container from your home network, the defaults
are fine. If you expose it beyond your LAN (e.g. through a reverse proxy),
turn on `SECURE_CONNECTION` and `WEB_AUTHENTICATION`.

## Ports

| Port | Service | Purpose |
|---|---|---|
| 5800 | VNC | Web UI — the desktop app |
| 5900 | VNC | Plain VNC, for a VNC client instead of the browser — uncomment in `docker-compose.yml` to enable |
| 5801 | Web | Web editor — HTML5, touch-friendly |

## Persisting your projects

Each service stores plans in its own folder on the host:

| Folder | Service | Format |
|---|---|---|
| `./config/` | VNC | `.sh3d` files (and the app's preferences) |
| `./plans/` | Web | `.sh3x` files (and `userPreferences.json`) |

Both folders are mounted as Docker volumes, so plans survive
container rebuilds. **Without the volumes, plans are lost on every
`docker compose up`.** Keep the mappings in place, and back the
folders up like you would any other important data.

## License

This project is licensed under the GPL-3.0 (see `LICENSE`).
Sweet Home 3D itself is developed by
[eTeks / Space Mushrooms](https://www.sweethome3d.com/) and
distributed under the GPL. SweetHome3DJS is also GPL.
