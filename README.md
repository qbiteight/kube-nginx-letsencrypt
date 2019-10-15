# kube-letsencrypt

Obtain and install Let's Encrypt in Kubernetes pods.

This gets a manual Let's Encrypt certificate, deploys an http challenge in a volume (which should be shared with the service pods serving the domains) and updates a secret with the new certificate.
