#!/bin/sh

## Script de mise à jour de version FreeBSD

## valable pour les jails ou host

## déclaration des variables utiles ; A FAIRE passage en arguments CMD des variables
family=''
upgrade_version=''
current_version=''

echo "Script d'automatisation d'upgrade FreeBSD."

read -p "Veuillez renseigner le type de serveur que vous voulez mettre à jour: host ou jail" $family

## FUNCTIONS

fetch() { # fetch update
  freebsd-update fetch
}
install() { # install update
  freebsd-update install
}

upgrade() { # upgrade function ; depends of the previous variables initialized
            # act differently if jail or host
  case $family in
    jail*)
            ## TO DO
      ;;

    host*)
      if [ $current_version == "10.0-RELEASE" ]; then
      echo "Version 10.1-RELEASE est la prochaine mise à jour à effectuer pour "
      upgrade_version="10.1-RELEASE"
      freebsd-update upgrade -r $upgrade_version
    elif [ $current_version == "10.1-RELEASE" ]; then
      echo "Version 10.2-RELEASE est la prochaine mise à jour à effectuer pour "
      upgrade_version="10.2-RELEASE"
      freebsd-update upgrade -r $upgrade_version
    elif [ $current_version == "10.2-RELEASE" ]; then
      echo "Version 10.3-RELEASE est la prochaine mise à jour à effectuer pour "
      upgrade_version="10.3-RELEASE"
      freebsd-update upgrade -r $upgrade_version
    else if [ $current_version == "10.3-RELEASE" ]; then
      echo "Version 11.0-RELEASE est la prochaine mise à jour à effectuer pour "
      upgrade_version="11.0-RELEASE"
      freebsd-update upgrade -r $upgrade_version

    fi
      ;;

    *) # reste

      ;;

  esac


  freebsd-update upgrade -r $upgrade_version
}



## check what to do if jail or host ; TO DO

while [ $family != jail || $family != host ]; do

  case $family in
    jail*)
        echo "Le type de serveur choisi est [ ${family} ]."
        echo "Veuillez renseignez les noms des jails à mettre à jour."
        ;;
    host*)
        echo "Le type de serveur choisi est [ ${family} ]."
        echo "Récolte des informations système pour la procédure de mise à jour..."
        current_version=$(freebsd-version)
        echo "La version actuelle de FreeBSD est là suivante : ${current_version}"

        fetch
        install
        upgrade
        install
        echo "Il est nécessaire de reboot la machine. a présent. Ensuite relancer un freebsd-update install."
        ;;
    *)
      echo "Type de serveur mal renseigné veuillez recommencer."
      ;;
    esac

done
