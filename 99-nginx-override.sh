#!/bin/bash
#
# /etc/cont-init.d/99-nginx-override.sh
#
# Runs at container startup, AFTER the baseimage has generated its
# default /etc/nginx/sites-available/webui. We append our override
# include to the bottom of that generated file. The baseimage
# regenerates webui every start, so this is the safe hook to use.
#
# If for some reason the base file isn't there, we do nothing - the
# baseimage still works, just without our mobile improvements.

set -e

WEBUI_CONF="/etc/nginx/sites-available/webui"
OVERRIDE="/etc/nginx/sites-available/webui.override"

# Sanity checks
if [ ! -f "$WEBUI_CONF" ]; then
    echo "[nginx-override] $WEBUI_CONF not found - skipping"
    exit 0
fi

if [ ! -f "$OVERRIDE" ]; then
    echo "[nginx-override] $OVERRIDE not found - skipping"
    exit 0
fi

# Idempotent: only append once.
if ! grep -qF 'webui.override' "$WEBUI_CONF"; then
    echo "" >> "$WEBUI_CONF"
    echo "# --- Custom override for mobile-friendly noVNC (sweethome3d) ---" >> "$WEBUI_CONF"
    echo "include $OVERRIDE;" >> "$WEBUI_CONF"
    echo "[nginx-override] Custom webui.override included in nginx config"
else
    echo "[nginx-override] webui.override already included - skipping"
fi
