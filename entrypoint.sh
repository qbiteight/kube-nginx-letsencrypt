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

echo "Creating env file"
cat /hooks/.env-template | sed "s/ACME_SECRETNAME_TEMPLATE/${ACME_SECRETNAME}/" | sed "s/NAMESPACE_TEMPLATE/${NAMESPACE}/" > /hooks/.env

echo "Requesting certificate"
certbot certonly --dry-run --manual --preferred-challenges http -n --agree-tos --email ${EMAIL} --no-self-upgrade -d ${DOMAINS} --manual-public-ip-logging-ok --manual-auth-hook /hooks/authenticator.sh

echo "Verifying path to certificate"
tree /etc/letsencrypt
CERTPATH=/etc/letsencrypt/csr/0000_csr-certbot.pem
KEYPATH=/etc/letsencrypt/keys/0000_key-certbot.pem
ls $CERTPATH $KEYPATH || exit 1

echo "ls /ssl-secret-patch.json"
ls /ssl-secret-patch.json || exit 1

echo "Preparing patch to update the certificate secret ($SECRETNAME)"
cat /ssl-secret-patch-template.json | sed "s/SECRETNAMESPACE/${NAMESPACE}/" | sed "s/SECRETNAME/${SECRETNAME}/" | sed "s/TLSCERT/$(cat ${CERTPATH} | base64 | tr -d '\n')/" | sed "s/TLSKEY/$(cat ${KEYPATH} |  base64 | tr -d '\n')/" > /ssl-secret-patch.json

echo "Updating certificate secret '$SECRETNAME'"
curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/ssl-secret-patch.json https://kubernetes/api/v1/namespaces/${NAMESPACE}/secrets/${SECRETNAME}
