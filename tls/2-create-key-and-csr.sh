#!/bin/bash

# Change to be whatever
FQDN="$1"

# make directories to work from
mkdir -p certs/{servers,tmp}

# Create Certificate for this domain,
mkdir -p "certs/servers/${FQDN}"
openssl genrsa \
  -out "certs/servers/${FQDN}/privkey.key" \
  4096

# Create the CSR
openssl req -new \
  -key "certs/servers/${FQDN}/privkey.key" \
  -out "certs/tmp/${FQDN}.csr.pem" \
  -subj "/C=FR/ST=Lille/L=Nord/O=ACME Service/CN=${FQDN}"
