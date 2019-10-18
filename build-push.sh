#/bin/bash

docker build --tag andrerfcsantos/kube-letsencrypt:dryrun-0.1.17 .
docker push andrerfcsantos/kube-letsencrypt:dryrun-0.1.17
