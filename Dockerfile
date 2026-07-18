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

# The web UI (served by nginx) should respond once the container is ready.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fs http://127.0.0.1:5800/ -o /dev/null || exit 1
