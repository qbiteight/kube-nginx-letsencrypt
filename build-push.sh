#/bin/bash

docker build --tag andrerfcsantos/kube-letsencrypt:dryrun-0.1.15 .
docker push andrerfcsantos/kube-letsencrypt:dryrun-0.1.15
