FROM binxio/gcp-get-secret:latest

FROM ghcr.io/runatlantis/atlantis:latest
COPY --from=0 /gcp-get-secret /usr/local/bin/


# gcp-get-secret will replace the environment variables values
# with the value in the Google Secret Manager secret before exec'ing
# the atlantis entrypoint.
#
# See https://github.com/binxio/gcp-get-secret
ENTRYPOINT ["/usr/local/bin/gcp-get-secret", "docker-entrypoint.sh"]