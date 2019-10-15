#/bin/bash

docker build --tag kube-letsencrypt:0.1 .
docker push kube-letsencrypt:0.1

