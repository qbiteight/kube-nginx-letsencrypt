FROM certbot/certbot:v0.39.0

MAINTAINER André Santos <andrerfcsantos@gmail.com>

RUN mkdir -p /etc/letsencrypt /acme-challenge /hooks

COPY secret-patch-template.json /
COPY entrypoint.sh /
COPY hooks/authenticator.sh /hooks
COPY hooks/cleanup.sh /hooks

CMD ["/entrypoint.sh"]
