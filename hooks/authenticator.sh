#/bin/bash

source /hooks/.env

echo "ACME_SECRETNAME: '$ACME_SECRETNAME' | NAMESPACE: '$NAMESPACE'"

if [[ -z $ACME_SECRETNAME || -z $NAMESPACE ]]; then
	echo "ACME_SECRETNAME or NAMESPACE not set, exiting"
    exit 1
fi

echo "ACME authenticator: preparing patch to update the challenge secret"
CERTBOT_VALIDATION_B64=$(echo $CERTBOT_VALIDATION | base64 | tr -d '\n')

echo "ls /challenge-secret-patch-template.json"
ls /challenge-secret-patch-template.json || exit 1

echo "cat /challenge-secret-patch-template.json + sed"
cat /challenge-secret-patch-template.json | sed "s/ACME_SECRETNAME/${ACME_SECRETNAME}/g" | sed "s/ACME_NAMESPACE/${NAMESPACE}/g" | sed "s/ACME_TOKEN_NAME/${CERTBOT_TOKEN}/g" | sed "s/ACME_TOKEN_CONTENT/${CERTBOT_VALIDATION_B64}/g" > /challenge-secret-patch.json

echo "ls /challenge-secret-patch.json"
ls /challenge-secret-patch.json || exit 1

echo "cat /challenge-secret-patch.json"
cat /challenge-secret-patch.json

echo "ACME authenticator: updating challenge secret '${ACME_SECRETNAME}' with token '${CERTBOT_TOKEN}'"
curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -v -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/challenge-secret-patch.json https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/secrets/${ACME_SECRETNAME}


echo "ACME authenticator: waiting 30 seconds before attempting to read from secret"
echo "Start of 30 seconds: `date`"
sleep 30
echo "End of 30 seconds: `date`"

CHALLENGE_URL="http://${CERTBOT_DOMAIN}/.well-known/acme-challenge/${CERTBOT_TOKEN}"

echo "curl -i $CHALLENGE_URL"
curl -i $CHALLENGE_URL
