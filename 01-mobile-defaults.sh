#!/bin/bash
#
# patches/01-mobile-defaults.sh
#
# Patches the noVNC UI to enable Local Scaling by default. The baseimage
# ships noVNC configured with resize=off, which is the *worst* default
# for a remote desktop accessed from a phone - the user gets a tiny
# fixed-size desktop with no way to make it fit their screen short of
# pinch-zoom and pan.
#
# We switch to resize=scale: the remote desktop stays at the configured
# DISPLAY_WIDTH x DISPLAY_HEIGHT (large by default) and the browser
# scales it down to fit the viewport. This is smooth, mobile-friendly,
# and works with any VNC server - no need for the ExtendedDesktopSize
# pseudo-encoding.
#
# This script is run as a build step in the Dockerfile. It's idempotent
# and safe to re-run.
#
# Pinned against noVNC 1.4.0 (the version shipped in jlesage/baseimage-gui
# debian-12-v4). If the baseimage updates noVNC, the sed patterns below
# may need to be updated to match the new ui.js layout.

set -e

UI_JS="/opt/novnc/app/ui.js"

if [ ! -f "$UI_JS" ]; then
    echo "[patch] WARNING: $UI_JS not found - skipping (baseimage may have updated noVNC version)" >&2
    exit 0
fi

# 1. Switch the default scaling mode from "off" to "scale".
#    This is THE change that makes the remote desktop auto-fit the
#    browser window. Without it, on a phone the user sees a tiny
#    1920x1080 desktop with no way to make it bigger.
if grep -qF "UI.initSetting('resize', 'off');" "$UI_JS"; then
    sed -i "s/UI\.initSetting('resize', 'off');/UI.initSetting('resize', 'scale');/" "$UI_JS"
    echo "[patch] ui.js: resize default -> 'scale'"
else
    echo "[patch] ui.js: resize default already patched or upstream changed (skipping)"
fi

# 2. Switch reconnect default from false to true, so a brief network
#    blip on a phone doesn't kick the user out. We only flip it if
#    it's still the upstream default.
if grep -qF "UI.initSetting('reconnect', false);" "$UI_JS"; then
    sed -i "s/UI\.initSetting('reconnect', false);/UI.initSetting('reconnect', true);/" "$UI_JS"
    echo "[patch] ui.js: reconnect default -> true"
fi

# 3. Enable local cursor by default (the browser draws the cursor
#    locally instead of waiting for cursor updates from the VNC
#    server). This makes the cursor feel snappy on touch devices
#    where the remote cursor would lag noticeably. The pattern
#    varies across noVNC versions, so we just try the common one.
if grep -qF "UI.initSetting('cursor', !UI.isTouchDevice);" "$UI_JS"; then
    sed -i "s/UI\.initSetting('cursor', !UI\.isTouchDevice);/UI.initSetting('cursor', true);/" "$UI_JS"
    echo "[patch] ui.js: cursor default -> local (true)"
fi

echo "[patch] Done."
