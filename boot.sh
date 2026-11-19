#!/bin/sh
# Railway boot for Weblate.
#
# Refuses to start without a strong admin password and the database and Redis settings, makes the two volumes writable for
# upstream's uid, then runs the stock entrypoint as that uid.
set -u
fail() { echo "[railway] $1" >&2; exit 1; }
[ -n "${WEBLATE_ADMIN_PASSWORD:-}" ] || fail "WEBLATE_ADMIN_PASSWORD is not set; refusing to start a translation server without an admin login"
[ "${#WEBLATE_ADMIN_PASSWORD}" -ge 12 ] || fail "WEBLATE_ADMIN_PASSWORD must be at least 12 characters"
[ -n "${WEBLATE_ADMIN_EMAIL:-}" ] || fail "WEBLATE_ADMIN_EMAIL is not set"
[ -n "${POSTGRES_HOST:-}" ] || fail "POSTGRES_HOST is not set"
[ -n "${POSTGRES_PASSWORD:-}" ] || fail "POSTGRES_PASSWORD is not set"
[ -n "${REDIS_HOST:-}" ] || fail "REDIS_HOST is not set"
[ -n "${REDIS_PASSWORD:-}" ] || fail "REDIS_PASSWORD is not set"
if [ -z "${WEBLATE_SITE_DOMAIN:-}" ]; then
  [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] || fail "neither WEBLATE_SITE_DOMAIN nor RAILWAY_PUBLIC_DOMAIN is set"
  export WEBLATE_SITE_DOMAIN="$RAILWAY_PUBLIC_DOMAIN"
fi
echo "[railway] Weblate as $WEBLATE_SITE_DOMAIN, postgres $POSTGRES_HOST, redis $REDIS_HOST, uid=$(id -u) data owner before=$(stat -c %u:%g /app/data)"
if [ "$(id -u)" = 0 ]; then
  chown -R 1000:0 /app/data /app/cache || fail "could not hand /app/data and /app/cache to uid 1000"
  chmod -R g+rwX /app/data /app/cache 2>/dev/null || true
  echo "[railway] data owner after=$(stat -c %u:%g /app/data)"
  # Upstream logs through /dev/fd/1 and symlinks to /dev/stdout, which a process that dropped to uid 1000 cannot reopen from root-owned
  # pipes. Point every log at one world-writable fifo and forward it from root, which keeps the real stdout.
  mkfifo -m 666 /run/railway-log || fail "could not create the log fifo"
  (while :; do cat /run/railway-log; done) &
  sed -i "s#/dev/fd/1#/run/railway-log#" /etc/supervisor/conf.d/*.conf
  ln -sf /run/railway-log /var/log/nginx/access.log
  ln -sf /run/railway-log /var/log/nginx/error.log
  exec setpriv --reuid=1000 --regid=1000 --groups=1000,0,5 /app/bin/start "$@"
fi
exec /app/bin/start "$@"
