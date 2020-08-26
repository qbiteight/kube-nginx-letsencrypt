#/bin/bash

docker build --tag qbiteight/kube-letsencrypt:0.1.9 .
docker push qbiteight/kube-letsencrypt:0.1.9
