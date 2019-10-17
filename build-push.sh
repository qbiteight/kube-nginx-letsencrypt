#/bin/bash

docker build --tag andrerfcsantos/kube-letsencrypt:dryrun-0.1.3 .
docker push andrerfcsantos/kube-letsencrypt:dryrun-0.1.3

