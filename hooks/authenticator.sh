#/bin/bash

echo $CERTBOT_VALIDATION > /acme-challenge/$CERTBOT_TOKEN
