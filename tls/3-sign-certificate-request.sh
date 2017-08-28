#!/bin/bash

FQDN="$1"
CA_NAME="$2"

# Sign the request from Server with your Root CA
openssl x509 \
  -req -in certs/tmp/${FQDN}.csr.pem \
  -CA certs/ca/$2.pem \
  -CAkey certs/ca/$2.key \
  -CAserial certs/ca/$2.srl \
  -out certs/servers/${FQDN}/cert.pem \
  -days 9131

# If you already have a serial file, you would use that (in place of CAcreateserial)
# -CAserial certs/ca/my-root-ca.srl
