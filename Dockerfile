# Weblate wrapper for Railway. Upstream runs as uid 1000 (gid 0) and refuses to start when /app/data is not writable, but Railway
# mounts a volume owned by root. As root nginx cannot reach the granian socket, so the wrapper boots as root (RAILWAY_RUN_UID=0),
# hands both volumes to uid 1000 and drops back to it with its supplementary groups (nginx logs are root-group only) before the stock entrypoint. The literals a deployer should never have to type
# are baked in here, sign-up is closed, and the first administrator is created by upstream from WEBLATE_ADMIN_PASSWORD at boot.
# upstream: WeblateOrg/weblate
FROM weblate/weblate:2026.11.2.0@sha256:559bb57e2cae8471386ac646cb852c615996d199d02a3f8894d004acb03a1b77

USER root
COPY --chmod=0755 boot.sh /railway-boot.sh

# Railway's edge replaces any inbound X-Forwarded-For, so its first address is the client; trusting every peer makes nginx real_ip
# take that leftmost entry (the edge hop rotates per request, so keying on the last one would give every client a new identity).
ENV RAILWAY_RUN_UID=0 \
    WEBLATE_ENABLE_HTTPS=1 \
    WEBLATE_ALLOWED_HOSTS=* \
    WEBLATE_REGISTRATION_OPEN=0 \
    WEBLATE_ADMIN_NAME="Weblate Admin" \
    WEBLATE_SITE_TITLE=Weblate \
    WEBLATE_ADMIN_NOTIFY_ERROR=0 \
    POSTGRES_PORT=5432 \
    REDIS_PORT=6379 \
    REDIS_DB=1 \
    WEBLATE_SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https \
    WEBLATE_IP_PROXY_HEADER=HTTP_X_FORWARDED_FOR \
    WEBLATE_TRUSTED_PROXY_ADDRESSES="0.0.0.0/0 ::/0"
EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["runserver"]
