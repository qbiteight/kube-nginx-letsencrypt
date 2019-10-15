#/bin/bash

echo "Post hook: removing ACME challenge"
rm -rf /acme-challenge/*
