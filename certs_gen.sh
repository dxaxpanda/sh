#!/bin/bash

declare -a nodes=(newyork dallas toronto)
SSL_DIR=/etc



create_nodes_key() {
echo "Creating nodes key for ${nodes[@]}."
for n in ${nodes[@]}; do
  echo "Creating key for ${n} in ${PWD}/certs/${n}/${n}-glusterfs.key."
  if [ ! -d ${PWD}/certs/$n ]; then
    mkdir -p ${PWD}/certs/$n
  fi

  #generating keys
  openssl genrsa -out ${PWD}/certs/$n/$n-glusterfs.key
  echo "Done making ${n}-glusterfs.pem file."
  openssl req -new -x509 -key ${PWD}/certs/$n/$n-glusterfs.key -subj "/CN=${n}" -out ${PWD}/certs/$n/$n-glusterfs.pem
done
}

create_nodes_key

echo "Creating ca file."
## cat into super cert file
find . -name "*.pem" -exec cat {} + > ${PWD}/certs/glusterfs.ca
echo "DONE."
