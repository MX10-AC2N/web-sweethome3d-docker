# Pull base image.
# NOTE: "debian-10" is no longer a valid tag - Debian 10 is end-of-life and
# was dropped from the baseimage entirely. debian-12 (Bookworm) is the
# current stable, well-supported choice. Swap for debian-13-v4 instead if
# you'd rather have the newer Sweet Home 3D 7.5 package than Bookworm's 7.0.2.
FROM jlesage/baseimage-gui:debian-12-v4

# Install Sweet Home 3D, its extra furniture library, and curl (used by the
# HEALTHCHECK below).
#
# `add-pkg` is the baseimage's own helper for installing packages: unlike a
# plain `apt install`, it also cleans up apt's cache/lists in the same
# layer, so the final image doesn't carry that dead weight.
RUN add-pkg sweethome3d sweethome3d-furniture curl

# Copy the start script and make sure it's executable. It isn't in the git
# repo (mode 644), so without this line the container fails to launch the
# app with a "permission denied" error.
COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh

# Name shown in the web UI's title bar and browser tab.
# (The original Dockerfile left this as "Xterm" - a leftover from the
# baseimage's own xterm example this project was adapted from, which
# installed xterm and never updated the app name afterwards.)
RUN set-cont-env APP_NAME "Sweet Home 3D"

# ---------------------------------------------------------------------------
# Mobile-friendly web UI
# ---------------------------------------------------------------------------
# The baseimage's noVNC page is a fixed-size desktop stream - usable on a
# PC but awful on a phone (tiny shrunken desktop, no auto-fit, the
# settings panel fights with the canvas). We patch it in three ways:
#
#   1. Swap the default ui.js scaling mode from "off" to "scale" so the
#      remote desktop auto-resizes to the browser viewport.
#   2. Replace the launcher index page with a responsive one that
#      detects the device and sets sensible initial sizing.
#   3. Inject a custom CSS file into vnc.html for touch + mobile tweaks,
#      and override nginx to serve the new pages and disable caching.
#
# The nginx override is wired in via a /etc/cont-init.d hook so it
# survives the baseimage regenerating its config at every startup.
# ---------------------------------------------------------------------------

# Copy all custom files in one shot to keep the image layers tidy.
COPY rootfs/ /

# Make the patch script executable and run it at build time.
RUN chmod +x /opt/novnc/patches/01-mobile-defaults.sh && \
    /opt/novnc/patches/01-mobile-defaults.sh && \
    chmod +x /etc/cont-init.d/99-nginx-override.sh

# The web UI (served by nginx) should respond once the container is ready.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fs http://127.0.0.1:5800/ -o /dev/null || exit 1
