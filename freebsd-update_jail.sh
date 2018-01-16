#!/bin/sh

# This script partially automate the update of freebsd machines

JAIL_NAME=$1
VERSION=$2
UPGRADE=$3

freebsd-update -b /jails/${JAIL_NAME} --currently-running ${VERSION}-RELEASE fetch 
freebsd-update -b /jails/${JAIL_NAME} --currently-running ${VERSION}-RELEASE install
freebsd-update -b /jails/${JAIL_NAME} --currently-running ${VERSION}-RELEASE -r ${UPGRADE}-RELEASE upgrade
freebsd-update -b /jails/${JAIL_NAME} --currently-running ${VERSION}-RELEASE install
jail -rc ${JAIL_NAME} 
freebsd-update -b /jails/${JAIL_NAME} --currently-running ${VERSION}-RELEASE install

