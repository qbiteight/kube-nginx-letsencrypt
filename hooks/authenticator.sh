#/bin/bash

source /hooks/.env

echo "ACME_SECRETNAME: '$ACME_SECRETNAME' | NAMESPACE: '$NAMESPACE'"

if [[ -z $ACME_SECRETNAME || -z $NAMESPACE ]]; then
	echo "ACME_SECRETNAME or NAMESPACE not set, exiting"
    exit 1
fi

echo "ACME authenticator: preparing patch to update the challenge secret"
CERTBOT_VALIDATION_B64=$(echo $CERTBOT_VALIDATION | base64 | tr -d '\n')

ls /challenge-secret-patch-template.json || (echo "ACME authenticator: patch template not found" && exit 1)

echo "ACME authenticator: patch template exists, executing template replacements"
cat /challenge-secret-patch-template.json | sed "s/ACME_SECRETNAME/${ACME_SECRETNAME}/g" | sed "s/ACME_NAMESPACE/${NAMESPACE}/g" | sed "s/ACME_TOKEN_NAME/${CERTBOT_TOKEN}/g" | sed "s/ACME_TOKEN_CONTENT/${CERTBOT_VALIDATION_B64}/g" > /challenge-secret-patch.json

ls /challenge-secret-patch.json || (echo "ACME authenticator: Patch file not found" && exit 1)

echo "ACME authenticator: updating challenge secret '${ACME_SECRETNAME}' with token '${CERTBOT_TOKEN}'"
curl -sS -I --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -k -XPATCH  -H "Accept: application/json, */*" -H "Content-Type: application/strategic-merge-patch+json" -d @/challenge-secret-patch.json https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/secrets/${ACME_SECRETNAME}

CHALLENGE_URL="http://${CERTBOT_DOMAIN}/.well-known/acme-challenge/${CERTBOT_TOKEN}"
echo "ACME authenticator: Attempting to verify the challenge at '$CHALLENGE_URL' before passing control to certbot again"

for i in {1..24}
do
    RES=$(curl -sS -I $CHALLENGE_URL | head -n1)
    echo "`date`: Attempt $i: $RES"
    if [[ $RES == *"200 OK"* ]]; then
        exit 0
    fi
    
    if [[ $i == 24 ]]; then
        echo "ACME authenticator: max attempts reached to get the callenge. Quitting."
        exit 1
    fi

    sleep 5
done


