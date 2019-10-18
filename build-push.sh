#/bin/bash

docker build --tag andrerfcsantos/kube-letsencrypt:0.1.8 .
docker push andrerfcsantos/kube-letsencrypt:0.1.8
