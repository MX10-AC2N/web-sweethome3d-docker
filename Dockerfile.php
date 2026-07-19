# PHP service for Sweet Home 3D JS web editor.
#
# Self-contained: nginx + php-fpm in one image, running as a single
# process under supervisord. Modeled after the jlesage baseimage
# pattern in the sibling service so the two services feel consistent.
#
# Why one image and not two (nginx + php-fpm separate)? Because the
# PHP API here is trivial (three ~30-line scripts). Splitting buys
# nothing and adds two containers to manage.

FROM php:8.2-fpm-bookworm

# ---- System packages ----
# - nginx: serve static assets + reverse-proxy PHP
# - supervisor: run nginx + php-fpm as a supervised process group
# - unzip: extract SweetHome3DJS archive at build time
# - curl: used by HEALTHCHECK
RUN apt-get update && apt-get install --no-install-recommends -y \
        nginx \
        supervisor \
        unzip \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---- PHP extensions ----
# SweetHome3DJS's PHP scripts are pure I/O (read/write/list files).
# No DB, no exotic extensions. We just need a sane default set
# for any future edits. opcache is the only one with measurable impact.
RUN docker-php-ext-install opcache

# ---- Download SweetHome3DJS ----
# We pin to a specific version (7.5.2) so the build is reproducible.
# The archive contains the JS engine, furniture catalog, and the
# 3 PHP files we need to serve.
ARG SH3DJS_VERSION=7.5.2
ARG SH3DJS_URL=https://sourceforge.net/projects/sweethome3d/files/SweetHome3DJS/SweetHome3DJS-${SH3DJS_VERSION}.zip/download
RUN curl -fsSL -o /tmp/sh3djs.zip "${SH3DJS_URL}" \
    && unzip -q /tmp/sh3djs.zip -d /tmp/sh3djs \
    && mkdir -p /opt/sh3djs \
    && cp -r /tmp/sh3djs/lib /opt/sh3djs/lib \
    && cp /tmp/sh3djs/index.html /opt/sh3djs/index.html \
    && cp /tmp/sh3djs/listHomes.php /opt/sh3djs/listHomes.php \
    && cp /tmp/sh3djs/writeData.php /opt/sh3djs/writeData.php \
    && cp /tmp/sh3djs/deleteHome.php /opt/sh3djs/deleteHome.php \
    # Inject our mobile.css into the upstream index.html so the
    # editor is responsive on phones/tablets.
    && sed -i 's|<link rel="stylesheet" type="text/css" href="lib/sweethome3djs.css">|<link rel="stylesheet" type="text/css" href="lib/sweethome3djs.css"><link rel="stylesheet" type="text/css" href="mobile.css">|' /opt/sh3djs/index.html \
    && mkdir -p /opt/sh3djs/data \
    && chown -R www-data:www-data /opt/sh3djs \
    && rm -rf /tmp/sh3djs /tmp/sh3djs.zip

# ---- Custom files (responsive landing, mobile CSS, nginx config) ----
COPY rootfs-php/ /

# nginx: install our site config, disable the default one
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -sf /etc/nginx/sites-available/sh3djs /etc/nginx/sites-enabled/sh3djs

# supervisor: install our program definitions
RUN mkdir -p /var/log/supervisor

# The data directory holds user home files. The compose file mounts
# a host folder here so the plans persist across container rebuilds
# and can be shared with the desktop VNC service.
VOLUME ["/opt/sh3djs/data"]

EXPOSE 5801

# Health check: nginx should respond on the web port
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fs http://127.0.0.1:5801/ -o /dev/null || exit 1

# supervisord keeps both nginx and php-fpm alive and reaps zombies.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/sh3djs.conf"]
