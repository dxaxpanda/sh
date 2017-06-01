#!/bin/sh

## Script de mise à jour de version FreeBSD

## valable pour les jails ou host

family=''
upgrade_version=''
current_version=''

echo "Script d'automatisation d'upgrade FreeBSD."

read -p "Veuillez renseigner le type de serveur que vous voulez mettre à jour: host ou jail" $family

fetch() {
  freebsd-update fetch
}
install() {
  freebsd-update install
}
upgrade() {
  case $family in
    jail*)

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
    else [ $current_version == "10.3-RELEASE" ]; then
      echo "Version 11.0-RELEASE est la prochaine mise à jour à effectuer pour "
      upgrade_version="11.0-RELEASE"
      freebsd-update upgrade -r $upgrade_version

  esac


  freebsd-update upgrade -r $upgrade_version
}



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
