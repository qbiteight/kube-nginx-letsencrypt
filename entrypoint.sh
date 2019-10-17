#!/bin/bash

if [[ -z $EMAIL || -z $DOMAINS || -z $SECRETNAME ]]; then
	echo "EMAIL, DOMAINS and SECRETNAME env vars required"
	exit 1
fi

NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

echo "Requesting certificates for:"
echo "  EMAIL: $EMAIL"
echo "  DOMAINS: $DOMAINS"
echo "  NAMESPACE: $NAMESPACE"
echo "Certificates will be placed into the '$SECRETNAME' secret"

echo "Requesting certificate"
certbot certonly --manual --preferred-challenges http -n --agree-tos --email ${EMAIL} --no-self-upgrade -d ${DOMAINS} --manual-public-ip-logging-ok --manual-auth-hook /hooks/authenticator.sh --manual-cleanup-hook /hooks/cleanup.sh

echo "Verifying path to certificate"
tree /etc/letsencrypt
CERTPATH=/etc/letsencrypt/live/$(echo $DOMAINS | cut -f1 -d',')
ls $CERTPATH || exit 1

echo "Preparing patch to update the certificate secret ($SECRETNAME)"
cat /ssl-secret-patch-template.json | \
	sed "s/SECRETNAMESPACE/${NAMESPACE}/" | \
	sed "s/SECRETNAME/${SECRETNAME}/" | \
	sed "s/TLSCERT/$(cat ${CERTPATH}/fullchain.pem | base64 | tr -d '\n')/" | \
	sed "s/TLSKEY/$(cat ${CERTPATH}/privkey.pem |  base64 | tr -d '\n')/" \
	> /ssl-secret-patch.json

ls /ssl-secret-patch.json || exit 1

echo "Updating certificate secret '$SECRETNAME'"
curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/ssl-secret-patch.json https://kubernetes/api/v1/namespaces/${NAMESPACE}/secrets/${SECRETNAME}
