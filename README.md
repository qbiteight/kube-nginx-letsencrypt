# kube-letsencrypt

Obtain and install Let's Encrypt manual certificates for Kubernetes in a scenario where you want a pod/job to get the certificates and have other pods serving the web content. The certificates requested are manual using the http challenge that gets placed in the `/acme-challenge`. This directory should be a volume shared between the pod running this image and the pods serving the web content. The challenge itself is placed in a secret this image assumes you previously configured.

## Environment variables

Provide the following environment variables to the image:

   * **EMAIL**

        The email that should be associated with the certificate.

   * **DOMAINS**

        Comma-separated list of the domains you want the certificate for.
    
   * **SECRETNAME**

        The `kubernetes.io/tls` secret name where to save the certificate.

   * **ACME_SECRETNAME**

        Secret to hold the acme tokens. Should be of type `Opaque`.

   * **NGINX_PODS**

        Comma separated list of pods with nginx that should be restarted after obtaining the certificates. 
