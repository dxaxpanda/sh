#!/bin/bash

##  This script runs daily and sync the new backups from the fiorentina server
## to with available storage thanks to rsync.
## The retention policy is 1 month and any older backups will be discarded
##

#set -exv



# vars

LOGFILE=$(pwd)/rsync.log

BACKUP_DIR="/var/nfs-backups/fiorentina/archives"
BACKUP_USER="backup"
RETENTION_POLICY=30
REMOTE_SERVER="10.0.0.250"
REMOTE_BACKUP_DIR="/fiorentina-backup"
REMOTE_SERVER_PORT=2250
RSYNC_PATH=/usr/bin/rsync
BACKUP_FILES="ST-DBs-*"

# Functions

log() {
  #logger -p local3.info "Information message: "
 # logger -p local3.err "Error Message: "
	# LOG TO /var/log/messages
	# TODO LEARN HOW TO USE THIS
  exec 1> >(logger -p local3.info -t $(basename $0))
  exec 2> >(logger -p local3.err -t $(basename $0))

}

rsync() {
  ${RSYNC_PATH} -avh --size-only -e "ssh -p ${REMOTE_SERVER_PORT}" \
  ${BACKUP_DIR}/${BACKUP_FILES} \
  ${BACKUP_USER}@${REMOTE_SERVER}:${REMOTE_BACKUP_DIR}
}

sync_files() {
  printf '[!]\tSync for new backup files incoming...'
  rsync
  printf '[!]\tFiles sync is now done.\n'
}

check_old_files() {
  #printf "%s\t" '[!]' 'Checking for files older than ${RETENTION_POLICY} days old for deletion..\n'
  printf "[!]\tChecking for files older than %s days old for deletion..\n" ${RETENTION_POLICY}
  OLD_FILES=$(find . -name ${BACKUP_FILES} \
  -type f -mtime +${RETENTION_POLICY} \
  -exec basename \{} \; | sort)
  printf '[!]\tFound following old files :\n'
  printf ${OLD_FILES}
}

delete_old_files() {
  printf '\n[!]\tDeleting thoses old files.\n'
  find . -name ${BACKUP_FILES} \
  -type f -mtime ${RETENTION_POLICY} \
  -print -delete
}

main() {
  log
  sync_files
  check_old_files
  delete_old_files
}

main
