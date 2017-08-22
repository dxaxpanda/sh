#!/bin/sh

# haproxy main function

SERVICE_STATUS=$(service haproxy status)


get_servers(){


	if [ "$SERVICE_STATUS" != *"not"* ]; then
		echo "Haproxy service is running with pid : ` echo ${SERVICE_STATUS} | awk '{print $6}' ` )."
	else
		echo "Retrieving servers configurations : "
		haproxytool frontend -s && haproxytool server -l
	fi
}

disable_server(){

	echo "Disabling servers $SERVERS"
	haproxytool server -d $SERVERS

	if [ $? -ne 0 ]; then
		 echo "An error occured, the servers couldn't be disabled."
	fi
}

enable_server(){

	echo "Enabling servers $1."
	haproxytool server -e $1
}

help_msg(){

	echo "No valid arguments passed. You need to use the script as such : $0 [enable | disable | status] <backend_name1>/<server_name1> <backend_name2>/<server_name2> ..."

}


# set -x for debugging

if [ $# == 0 ]; then

	help_msg

elif [ $# -gt 1 ]; then

	CMD_ARGS=$1
	shift
	SERVERS=$@

else

	CMD_ARGS=$1

fi

case $CMD_ARGS in

	enable*)

		echo "Number of arguments passed : $#"
		for s in $SERVERS; do

			enable_server $s
		done
		;;

	 disable*)
		for s in $SERVERS; do
			 disable_server $s
		done
		;;

	status*)

	       	echo "Showing servers status."
		get_servers

		;;
	*)
		help_msg

		;;
esac
