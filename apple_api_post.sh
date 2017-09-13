#!/bin/sh

set -exv
set -e

#PAYLOAD=$1
#BUNDLE_ID=$2
#CERT_FILE=$3
#TOKEN=$4

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

API_PUSH_URL="https://api.push.apple.com/3/device"

#usage(){
#    printf "ERROR : not enough arguments.\n"
#    printf "\t[!] ---\tScript Usage :\t--- [!]\n"
#    printf "In order to run the script you to pass arguments as follow :\n"
#    printf "\t$0 <PAYLOAD> <BUNDLE_ID> <CERT_FILE> <TOKEN> >> /log/path 2>&1\n"
#}

CURL_COMMAND() {
    curl --verbose --data '${PAYLOAD}' \
        --header "apns-topic: ${BUNDLE_ID}" \
        --header "apns-priority: 10" \
        --header "method: POST" \
        --http2 \
        --cert ${CERT_FILE} \
        ${API_PUSH_URL}/${TOKEN}
}

#if [ "$#" -lt 4 ]; then
#    usage
#else


    opt="False"
    while [ ${opt} != "y" ]; do


	printf "[!] Please provide a <PAYLOAD> (enclosed by ' '):\n"
	read -r PAYLOAD

	printf "[!] Please provide a valid Bundle ID:\n"
	read -r BUNDLE_ID

	printf "[!] Please provide a certificate file path in .pem format:\n"
	read -r CERT_FILE

	printf "[!] Please provide a valid TOKEN:\n"
	read -r TOKEN
	printf "[!] Please review following options...\n"
	printf "PAYLOAD: ${PAYLOAD}\n"
	printf "BUNDLE_ID: ${BUNDLE_ID}\n"
	printf "CERT_FILE: ${CERT_FILE}\n"
	printf "TOKEN: ${TOKEN}\n"
	printf "Do you want to send the notification with the previous options ? Enter [y/n :\n"
	read -r opt
    done
    printf "[!] ${TIMESTAMP} ----------------------------------------\n"
    printf "[!] ${TIMESTAMP} - initializing script with theses values:\n"
    printf "PAYLOAD: ${PAYLOAD}\n"
    printf "BUNDLE_ID: ${BUNDLE_ID}\n"
    printf "CERT_FILE: ${CERT_FILE}\n"
    printf "TOKEN: ${TOKEN}\n"
    printf "[!] ${TIMESTAMP} ----------------------------------------\n"

    CURL_COMMAND
#fi
