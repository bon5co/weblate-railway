# weblate-railway

Thin wrapper over the official [Weblate](https://github.com/WeblateOrg/weblate) image for Railway. It boots as root only long enough
to hand the Railway volumes (`/app/data`, `/app/cache`) to Weblate's uid 1000, forwards upstream's logs, then drops back to that uid
and runs the stock entrypoint. It bakes in HTTPS, the proxy headers, the client-IP header, the database and Redis ports, and closes
public registration; the first administrator is created by upstream from `WEBLATE_ADMIN_EMAIL` and `WEBLATE_ADMIN_PASSWORD`. It
refuses to start without a 12-character admin password, a database and a Redis password. Used by the Weblate template on the Railway
marketplace.
