#!/bin/sh


## script d'automatisation de creation de jail FREEBSD
## prend en parametre le dataset de jail à créer et le nom de la jail

set -exv

trap cleanup 0 1 2 3 6 15

JAIL_ACTION=$1
JAIL_NAME=$2
JAIL_ROOT_DATASET=$3
JAIL_DATASET=$4
OS_VERSION='11.0-RELEASE'
TMPDIR=$(mktemp -d /tmp/${JAIL_NAME}.XXXX) || exit 1

## FUNCTIONS DEFINITION

usage() {
  echo -e $1
  echo -e "You need to invoke the script as such : $0 <jail_action> <jail_name> [ <jail_root_dataset> <jail_dataset> | only for create and remove ]."
}

configurations_files() {
        echo -e "Checking if rc.conf file is set..."
          if [ ! -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf" ]; then
            echo -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf doesn't exist. Creating it."
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
          echo -e "File /${JAIL_DATASET}/${JAIL_NAME}/etc/rc.conf exists already."
        fi


echo -e "Checking if resolv.conf file is set..."
      if [ ! -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf" ]; then
        echo -e "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf doesn't exist. Creating it."
        cat <<EOF >> "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf"
nameserver 213.186.33.99
EOF
      else
          if [ ! -s "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf" ]; then
            echo -e "File /${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf exists already but is empty..."
            echo -e "Adding proper DNS record."
          cat <<EOF >> "/${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf"
nameserver 213.186.33.99
EOF
          else
            echo -e "File /${JAIL_DATASET}/${JAIL_NAME}/etc/resolv.conf exists already and has proper DNS."
          fi
      fi

      echo -e "[!] --- Checking if ${JAIL_NAME} is already configured inside /etc/jail.conf ---"
      if grep -q ${JAIL_NAME} /etc/jail.conf; then
        echo -e "${JAIL_NAME} is already set. Continuing"
      else
        echo -e "[!] --- Adding parameters for ${JAIL_NAME} ---"
        cat <<END >> "/etc/jail.conf"
${JAIL_NAME} {
        persist;
        ip4.inherit;
        mount.devfs;
}
END
      fi


}      ## WE can NOW launch the jail


bootstrap_pkg() { # BOOTSTRAP PACKAGES
    echo -e "Boostrapping packages installation for ${JAIL_NAME}... \n"
    pkg -j ${JAIL_NAME} update
    pkg -j ${JAIL_NAME} upgrade
    pkg -j ${JAIL_NAME} install -y sudo vim wget
}

create_dataset() {

  echo -e "Checking if jail dataset ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME} already exists..."
  if [ ! $(zfs get ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME} 2>/dev/null) ]; then
    echo -e "Dataset doesn't exist. Creating it."
    zfs create ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME}
    if [ $? -ne 0 ]; then
      echo -e " An ERROR occured. return code : $?"
      exit $?
    else
      echo -e "Jail dataset ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME} successfully created."
      zfs list |grep -e "NAME" -e "${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME}"
    fi
  fi

}

remove_dataset() {

    echo -e "Removing jail dataset: ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME}"
    zfs destroy -f ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME}
    if [ $? -ne 0 ]; then
      echo -e " An ERROR occured. return code : $?"
      exit $?
    else
      echo -e "Jail dataset ${JAIL_DATASET}/${JAIL_NAME} successfully destroyed."
    fi

}

create_jail() {

  # fetch base packages
  echo -e "[!] --- Fetching FreeBSD base and kernel packages... ---"
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$OS_VERSION/base.txz -o ${TMPDIR}
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/$OS_VERSION/kernel.txz -o ${TMPDIR}

  if [ $(zfs get -H -o value mountpoint ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME}) != /${JAIL_DATASET}/${JAIL_NAME} ]; then

    echo -e "[!] --- Extracting files to /${JAIL_DATASET}/${JAIL_NAME} ---"
    tar --unlink -Jxpf ${TMPDIR}/base.txz -C $(zfs get -H -o value mountpoint ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME})
    tar --unlink -Jxpf ${TMPDIR}/kernel.txz -C $(zfs get -H -o value mountpoint ${JAIL_ROOT_DATASET}/${JAIL_DATASET}/${JAIL_NAME})
  else
  # extracting base packages ; make we are in the right jail directory as a safeguard
  echo -e "[!] --- Extracing files to /${JAIL_DATASET}/${JAIL_NAME}... --- [!]"
    tar --unlink -Jxpf ${TMPDIR}/base.txz -C /${JAIL_DATASET}/${JAIL_NAME}
    tar --unlink -Jxpf ${TMPDIR}/kernel.txz -C /${JAIL_DATASET}/${JAIL_NAME}
  fi

  echo -e "[!] --- Checking fstab.${JAIL_NAME}... ---"
  if [ ! -e "/etc/fstab.${JAIL_NAME}" ]; then
    echo -e "[!] --- fstab.${JAIL_NAME} doesn't exist. Creating it... ---"
      touch /etc/fstab.${JAIL_NAME}
  else
    echo -e "[!] --- fstab.${JAIL_NAME} already exists. ---"
  fi
  configurations_files
  ## WE can NOW launch the jail
}

start_jail() {

  echo -e "[!] --- Starting jail ${JAIL_NAME} ... ---"
  service jail start ${JAIL_NAME}
  if [ $? == 0 ]; then
    echo -e "[!] --- Jail ${JAIL_NAME} successfully started as
    $(jls |grep -e 'JID' -e "${JAIL_NAME}") ---"
    echo -e "Bootstrapping PKG..."
    bootstrap_pkg
  else
    echo -e "[!] --- An ERROR occured: return code $?. --- "
    exit $?
  fi

}


stop_jail() {

  echo -e "[!] --- Stopping jail ${JAIL_NAME} ... --- "
  service jail stop ${JAIL_NAME}
  if [ $? == 0 ]; then
    echo -e "[!] --- Jail ${JAIL_NAME} successfully stopped. ---"
  else
    echo -e "[!] --- An ERROR occured: return code $?. ---"
    exit $?
  fi
}

cleanup() {
  echo -e "[!] --- Exit incoming .. attempting to cleanup. ---"
  if [ -e ${TMPDIR} ]; then
    rm -rvf ${TMPDIR}
  echo -e " [!] --- Done cleaning up ... Exiting. ---"
}

## check if parameters ares passed to the script
  if [ $# -lt 3 ]; then
    usage "Not enough arguments passed to the script."
    exit 1
  fi
  if [ $# -gt 4 ]; then
    usage "Too many arguments passed to the script."
    exit 1
  fi

  if [ "${JAIL_ACTION}" != start -a "${JAIL_ACTION}" != stop -a "${JAIL_ACTION}" != create -a "${JAIL_ACTION}" != remove  ]; then
    usage "Wrong Actions passed to the script."
    exit 1
  else
      if [ "${JAIL_ACTION}" == create || "${JAIL_ACTION}" == remove ] && [ -z ${JAIL_ROOT_DATASET}/${JAIL_DATASET} ]; then
    usage "You provided ${JAIL_ACTION} as Action. When passing create or remove as argument you need to also pass a jail dataset name."
      else
    echo -e "Script initializing with the following parameters:
      $1 jail on $3 dataset. Current OS_VERSION is ${OS_VERSION}."
    fi
  fi




case $JAIL_ACTION in
  *start* )
  cd /${JAIL_DATASET}/${JAIL_NAME} && start_jail
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

echo -e "END."
