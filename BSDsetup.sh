#!/bin/sh


## script d'automatisation de creation de jail FREEBSD
## prend en parametre le dataset de jail à créer et le nom de la jail

JAIL_ACTION=$1
JAIL_NAME=$2
JAIL_DATASET=$3
OS_VERSION='11.0-RELEASE'
## check if parameters ares passed to the script

  if [ $# -lt 2 ]; then

  echo "Not enough arguments passed to the script."
  echo "You need to invoke the script as such : $0 <jail_action> <jail_name> [ jail_dataset | only for create and remove ]."
  exit 1
  fi
  if [ $# -gt 3 ]; then
    echo "Too many arguments passed to the script."
    echo "You need to invoke the script as such : $0 <jail_action> <jail_name> [ jail_dataset | only for create and remove ]."
    exit 1
  fi

  if [ "${JAIL_ACTION}" != start -a "${JAIL_ACTION}" != stop -a "${JAIL_ACTION}" != create -a "${JAIL_ACTION}" != remove  ]; then
    echo "Wrong Actions passed to the script."

  else
      if [ "${JAIL_ACTION}" == create || "${JAIL_ACTION}" == remove ] && [ -z ${JAIL_DATASET} ]; then
    echo "You provided ${JAIL_ACTION} as Action. When passing create or remove as argument you need to also pass a jail dataset name."
      else
    echo "Script initializing with the following parameters:
      $1 jail on $3 dataset. Current OS_VERSION is ${OS_VERSION}."
    fi
  fi

configurations_files() {


        echo "Checking if rc.conf file is set..."
          if [ ! -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf" ]; then
            echo "/${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf doesn't exist. Creating it."
cat <<EOF >> "/${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf"
# location: base jail
###
# Jail stuff
###
hostname="${JAIL_NAME}-preprod.wincomparator.com"
# Shouldn't run sendmail
sendmail_enable="NONE"
clear_tmp_enable="YES"
# Syslog shouldn't listen for incoming connections
syslogd_flags="-ss"
rpcbind_enable="NO"
##
## Services
##
sshd_enable="YES"
#nginx_enable="YES"
#php_fpm_enable="YES"
#apache24_enable="YES"
#pureftpd_enable="YES"
EOF

        else
          echo "File /${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf exists already."
        fi


echo "Checking if resolv.conf file is set..."
      if [ ! -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf" ]; then
        echo "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf doesn't exist."
        cat <<EOF >> "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf"
nameserver 213.186.33.99
EOF
      else
          if [ ! -s "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf" ]; then
            echo "File /${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf exists already but is empty..."
            echo "Adding proper DNS record."
          cat <<EOF >> "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf"
nameserver 213.186.33.99
EOF
          else
            echo "File /${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf exists already and has proper DNS."
          fi
      fi

}      ## WE can NOW launch the jail


bootstrap_pkg() {


    pkg -j ${JAIL_NAME} update
    pkg -j ${JAIL_NAME} upgrade
    pkg -j ${JAIL_NAME} install -y sudo vim wget
}

create_dataset() {

  echo "Checking if jail dataset ${JAIL_DATASET}/${JAIL_NAME} already exists..."
  if ! $(zfs get all $JAIL_DATASET/$JAIL_NAME); then
    echo "Dataset doesn't exist. Creating it."
    zfs create $JAIL_DATASET/$JAIL_NAME
    if [ $? -ne 0 ]; then
      echo " An ERROR occured. return code : $?"
      exit $?
    else
      echo "Jail dataset ${JAIL_DATASET}/${JAIL_NAME} successfully created."
      zfs list |grep -e "NAME" -e "${JAIL_DATASET}/${JAIL_NAME}"
    fi
  fi

}

remove_dataset() {

    echo "Removing jail dataset: ${JAIL_DATASET}/${JAIL_NAME}"
    zfs destroy -f $JAIL_DATASET/$JAIL_NAME
    if [ $? -ne 0 ]; then
      echo " An ERROR occured. return code : $?"
      exit $?
    else
      echo "Jail dataset ${JAIL_DATASET}/${JAIL_NAME} successfully destroyed."
    fi

}

create_jail() {

  cd /tmp

  # fetch base packages
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$OS_VERSION/base.txz
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$OS_VERSION/kernel.txz

  if $(zfs get -H -o value mountpoint ${JAIL_DATASET}/${JAIL_NAME}) != /${JAIL_DATASET}/${JAIL_NAME}; then
    tar --unlink -Jxpf base.txz -C $(zfs get -H -o value mountpoint ${JAIL_DATASET}/${JAIL_NAME})
    tar --unlink -Jxpf kernel.txz -C $(zfs get -H -o value mountpoint ${JAIL_DATASET}/${JAIL_NAME})

    rm -rvf /tmp/base.txz
    rm -rvf /tmp/kernel.txz
  else
  # extracting base packages ; make we are in the right jail directory as a safeguard
    tar --unlink -Jxpf base.txz -C /$JAIL_DATASET/$JAIL_NAME
    tar --unlink -Jxpf kernel.txz -C /$JAIL_DATASET/$JAIL_NAME

    rm -rvf /tmp/base.txz
    rm -rvf /tmp/kernel.txz
  done

  echo "Checking fstab.${JAIL_NAME}..."
  if [ ! -e "/etc/fstab.${JAIL_NAME}" ]; then
    echo "fstab.${JAIL_NAME} doesn't exist. Creating it."
      touch /etc/fstab.$JAIL_NAME
  else
    echo "fstab.${JAIL_NAME} already exists."
  fi
  configurations_files
  ## WE can NOW launch the jail
}

start_jail() {

  service jail start $JAIL_NAME
  if [ $? == 0 ]; then
    echo "Jail ${JAIL_NAME} successfully started as
    $(jls |grep -e 'JID' -e "${JAIL_NAME}")"
    echo "Bootstrapping PKG..."
    bootstrap_pkg
  else
    echo "An ERROR occured: return code $?."
    exit $?
  fi

}


stop_jail() {

  service jail stop $JAIL_NAME
  if [ $? == 0 ]; then
    echo "Jail ${JAIL_NAME} successfully stopped."
  else
    echo "An ERROR occured: return code $?."
    exit $?
  fi
}


case $JAIL_ACTION in
  *start* )
  cd /$JAIL_DATASET/$JAIL_NAME && start_jail
    ;;
  *stop* )
      stop_jail
    ;;
  *create* )
  create_dataset
  create_jail
  start_jail
  bootstrap_pkg
    ;;
  *remove* )
  stop_jail
  remove_dataset
    ;;
    * )
    ;;
esac

echo "END."
