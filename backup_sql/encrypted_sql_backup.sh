
#! /bin/bash

TIMESTAMP=$(date +"%F")

BACKUP_DIR=/mnt/data/mysqldata # dossier de backup glusterfs
EXPORT=/export # archives de backup + version encryptée
MYSQL_USER="bkpuser" # user de backup
MYSQL=/usr/bin/mysql
MYSQL_SERVER="172.10.10.20" # serveur mysql
MYSQLDUMP=/usr/bin/mysqldump
BACKUP_SERVER="37.59.57.184" # serveur de backup distant Canada
FILE='randompassphrase.itsnothing.really' # passphrase
DEC=/.dec # dossier contant les clefs
PSSPSS=/var/.local # passphrase encryptée

databases=$($MYSQL  -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")

if [ ! -d $BACKUP_DIR/$TIMESTAMP ]; then

  mkdir $BACKUP_DIR/$TIMESTAMP

else

## find all directories older than 3 days and delete them

  find /$BACKUP_DIR/* -mtime +3 -type d | xargs rm -rf

fi

## Loop through all available databases and dump it gzip compressed

for db in $databases; do

  $MYSQLDUMP --force --databases $db | gzip > "$BACKUP_DIR/$TIMESTAMP/$db-$TIMESTAMP.sql.gz"

done

tar czvf $EXPORT/$TIMESTAMP-backup.tar.gz $BACKUP_DIR/$TIMESTAMP

# encrypt with passphrase previously generated first
openssl enc -aes-256-cbc -pass file:$DEC/$FILE < $EXPORT/$TIMESTAMP/$TIMESTAMP-backup.tar.gz > $EXPORT/$TIMESTAMP/encrypted.dat

# then proceed to encrypt the passphrase with the public key

openssl rsautl -encrypt -pubin -inkey /.dec/key-public.pem < $DEC/$FILE > $PSSPSS/emptiness.$TIMESTAMP

## Then sends to our remote backup store

scp -P 222 $DEC/$EXPORT/$TIMESTAMP/encrypted.dat jmirre@37.59.57.184:~/.qwirk_backup
