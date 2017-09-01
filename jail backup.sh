#!/bin/bash

## Script de backup de jail FreeBSD ; IL EST NECESSAIRE DE BACKUP LES JAILSAVANT upgrade


## Début

## TO DO ; modifier le script en python

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
