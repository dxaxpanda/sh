#! /bin/bash
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/mnt/real1-nfs-backups/preprod"
MYSQL_USER="bkpuser"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="#BckUpuSeR!"
MYSQL_SERVER="10.3.0.4"
MYSQLDUMP=/usr/bin/mysqldump
databases=$($MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVER -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")
if [ ! -d $BACKUP_DIR/$TIMESTAMP ]; then
  mkdir $BACKUP_DIR/$TIMESTAMP
else

## find all directories older than 3 days and delete them

  find /$BACKUP_DIR/* -mtime +3 -type d | xargs rm -rf
fi

## Loop through all available databases and dump it gzip compressed
for db in $databases; do
  $MYSQLDUMP --force --user=$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVER --databases $db | gzip > "$BACKUP_DIR/$TIMESTAMP/$db.sql.gz"
done
#bCKuPUsEr! user
#BckUpuSeR! mysql
