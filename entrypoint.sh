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

echo "Verifying path to certificate exists"
tree /etc/letsencrypt
CERTPATH=/etc/letsencrypt/csr/0000_csr-certbot.pem
KEYPATH=/etc/letsencrypt/keys/0000_key-certbot.pem
stat $CERTPATH $KEYPATH 2> /dev/null > /dev/null || (echo "Path to cert or key doesn't exist: CERTPATH: $CERTPATH KEYPATH: $KEYPATH" && exit 1)

stat /ssl-secret-patch-template.json 2> /dev/null > /dev/null || (echo "Path to ssl secret patch doesn't exist" && exit 1)

echo "SSL secret patch file exists. Executing template"
cat /ssl-secret-patch-template.json | sed "s/SECRETNAMESPACE/${NAMESPACE}/" | sed "s/SECRETNAME/${SECRETNAME}/" | sed "s/TLSCERT/$(cat ${CERTPATH} | base64 | tr -d '\n')/" | sed "s/TLSKEY/$(cat ${KEYPATH} |  base64 | tr -d '\n')/" > /ssl-secret-patch.json

echo "Updating certificate secret '$SECRETNAME'"
curl -i --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/ssl-secret-patch.json https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/secrets/${SECRETNAME}
