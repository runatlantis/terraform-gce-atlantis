# Securing sensitive environment variables

This guide explains how to secure environment variables when using the Atlantis module on Google Cloud Platform. For more information on using this module, see the [`basic example`](../basic/README.md).

## build your own image
To retrieve sensitive values from the Google Secret manager you need to:

- enable artifact registry in your Google Cloud Project
- build your own image using the [gcp-get-secret](https://github.com/binxio/gcp-get-secret) as entrypoint
- store your secrets in Google Secret Manager.
- set variable values to point to the secret manager secret URL

## Enable artifact registry
To enable artifact registry, type:

```shell
gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories \
  create atlantis \
  --repository-format=docker \
  --location=europe \
  --description="Atlantis gcp-get-secret"
```

## build the image
The build the atlantis image, type the following commands:

```shell
REPOSITORY=europe-docker.pkg.dev/$(gcloud config get-value project)/atlantis:latest
docker build -t $REPOSITORY -f Dockerfile .
docker push $REPOSITORY
echo "INFO: set the terraform variable image to \"$REPOSITORY\"" >&2
```

## Store the secrets in Google Secret Manager
Add the secrets into the secret manager, using the following script:

```bash
for SECRET in ATLANTIS_GH_USER ATLANTIS_GH_TOKEN ATLANTIS_GH_WEBHOOK_SECRET; do
    NAME=$(sed -e 's/_/-/g' | tr '[:upper:]' '[:lower:]')
    
    read "Value for $SECRET:" VALUE
    gcloud secrets create $NAME
    gcloud secrets versions add --secret $NAME --datafile <(echo -n "$VALUE")
    echo "INFO: stored $SECRET as $NAME" >&2
done    
```

## set variable values to point to the secret manager secret URL
Use the `var.env_vars` variable to set non-sensitive environment variables.

```hcl
env_vars = {
  ATLANTIS_GH_USER = "gcp:///atlantis-gh-user"
  ATLANTIS_GH_TOKEN = "gcp:///atlantis-gh-token"
  ATLANTIS_GH_WEBHOOK_SECRET = "gcp:///atlantis-gh-webhook-secret"
  ... other ...
}
```
This will retrieve the value for the environments variables from the Google Secret Manager on startup of Atlantis.
