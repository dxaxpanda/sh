#! /bin/sh

### Script qui authorise le purge du cache par le biais des header de pages ou match d'URL par mot clef
### Marche à suivre : ./purge.sh [type: header ou url] header(1)|url(1) header(2)|url(2) ... header(n)|url(n)
###


purge="varnishadm -T 127.0.0.1:6082 -S /usr/local/varnish/juvarnish.juventus.sportytrader.com/_.secret"

if [ $(/usr/bin/id -u) -ne 0 ]; then
	echo "PERMISSION REFUSEE => un accès root est requis. Veuillez vous loguez en root ou utilisez la commande sudo."
	exit 1
fi

if [ $# -lt 2 ]; then 
	echo "ERREUR: ARGUMENT REQUIS => invocation du script $0 [type: header ou url] header(1)|url(1) header(2)|url(2) ... header(n)|url(n)."
	exit 1
fi

type=$1
 
case $type in
	*header*) 
		shift
		for h in $@;
		do
			echo "Vous avez spécifiez le type "header" pour la purge."
			echo "Demarrage de la purge du cache pour le header $h ."
			$purge "ban obj.http.X-Varnish-PageInfo == $h" ; sleep 1 ; echo "..Done"
			echo "Purge du cache fini."
			exit 0
		done
		;;
	*url*)
		shift
		for u in $@;
		do
			echo "Vous avez spécifiez le type "url" pour la purge."
			echo "Demarrage de la purge du cache pour l'url $u"
			
			## BAN de TOUS LES URLS QUI CONTIENNENT LES ARGUMENTS
			## EXEMPLE : [ ban req.url ~ tennis ] VA PURGER LES CACHES SUIVANTS
			## http://www.wincomparator.com.preprod2.wincomparator.net/fr-fr/match-en-direct/tennis/
			## ET
			## http://www.wincomparator.com.preprod2.wincomparator.net/fr-fr/resultats/tennis/
			
			$purge "ban req.url ~ $u"; sleep 1 ; echo "..Done"
			echo "Purge du cache fini."
			exit 0
		done
		;;
	*)
		echo "Vous n'avez spécifiez ni un type header ni un type url."
		echo "Rappel de l'invocation du script :"
		echo "$0 [type: header ou url] header(1)|url(1) header(2)|url(2) ... header(n)|url(n)."
		exit 1
		;;
esac