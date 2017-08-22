#!/bin/bash

## Script d'upgrade automatique FREEBSD, depuis n'importe quelle version vers la version stable actuelle. Le script reprend les jails et les backup vers un serveur donné.

# définition fonction backup

declare -A my_array
jails=()


dir_prereq() {
  ## this function create prereqs datasets
    zfs create $1
}

copy_confs() {
#    cp /etc/rc.conf /etc/rc.conf.back
    cp $1 $1.back
    rm $1
    ## copie de la bonne conf
cat <<'EOF' >> brightup.sh
    hostname="getafe-pp2"
    sshd_enable="YES"
    jail_enable="YES"
    jail_conf="/etc/jail.conf"
    ntpd_enable="YES"
    # Set dumpdev to "AUTO" to enable crash dumps, "NO" to disable
    dumpdev="AUTO"
    zfs_enable="YES"
    ifconfig_vmx0="inet 51.254.227.148 netmask 255.255.255.255 broadcast 51.254.227.148"
    static_routes="ovhv4"
    route_ovhv4="-net 5.135.138.254 -iface vmx0"
    defaultrouter="5.135.138.254"
EOF
}

prompt() {
  local prompt=$1
  attr=$2

  read -p "$prompt $attr" $attr ; echo "$attr vaut : ${!attr}."

  add_array ${attr} ${!attr}
}

add_array() {
  key=$1
  value=$2
  my_array[$key]=$value
  echo "Ajout de la clef $key avec pour valeur $value."
}


## Début

echo "Lancement du script de backup FreeBSD. Plusieurs informations sont collectés afin de permettre au script d'atteindre son objectif."

## prompt the users with statement
string="Veuillez Renseignez le dossier de backup: "
prompt "$string" backup_dir
echo "Le dossier de backup choisi est $my_array[${!attr}]"
string="Veuillez renseignez le remote user: "
prompt "$string" remote_user
echo "Le remote user choisi est $my_array[${!attr}]"
string="Veuillez renseignez le serveur de backup: "
prompt "$string" remote_host
echo "Le serveur de backup choisi est $my_array[${!attr}]"
string="Veuillez renseignez le port de backup: "
prompt "$string" remote_port
echo "Le port du serveur de backup est $my_array[${!attr}]"
string="Veuillez renseignez la ou les jails de backup: "
prompt "$string" jails
echo "Les jails à backup sont $my_array[${!attr}]."



## send jail backup to remote host into format or choice
echo "Script de backup en cours d'execution..."
for j in "{jails[@]}"
do
  echo -n "ZFS send de $j  vers $remote_host."
  zfs send $j | ssh -p $remote_port $remote_user@$remotehost "$compression > $j.img.$compression"

  if [$? != 0 ]
    echo -n "ERROR : errcode $?"
    exit $?
  else
    echo -n "Receive complete."
    exit $?
done

echo -n "Backup complete. Veuillez lancer l'upgrade systeme à présent."
