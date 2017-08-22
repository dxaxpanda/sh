#!/bin/sh

## backup des datasets zfs importants

# Datasets required according to regex
DATASETS=$(zfs list -t snapshot | grep -Ev 'zjails|NAME' | awk '{print $1}')
REMOTE_USER="jmirre"
REMOTE_SERVER='10.0.0.250'
REMOTE_PORT='222'
COMPRESION=gzip



# Backing up all datasets
for SET in ${DATASETS}; do
    zfs send ${SET} | ${COMPRESSION} | \
    ssh -p ${REMOTE_PORT} \
    ${REMOTE_USER}@${REMOTE_SERVER} \
     "cat > ${SET}.gz"
done

# /* TO DO
# - Add error handling
#
#
# ...
#
# */
