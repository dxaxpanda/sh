#!/bin/bash

# name of the certificate authority
CA_NAME=$1
IP=$2
# make directories to work from
mkdir -p certs/ca

# Create your very own Root Certificate Authority : generate private key using AES256
# for strong encryption
openssl genrsa \
  -out certs/ca/${CA_NAME}.key \
  4096

# Create the root certificate using the private key
openssl req \
  -x509 \
  -new \
  -nodes \
  -key certs/ca/${CA_NAME}.key \
  -days 9131 \
  -out certs/ca/${CA_NAME}.pem \
  -subj "/C=FR/ST=Lille/L=Nord/O=ACME Signing Authority Inc/CN=${IP}"
