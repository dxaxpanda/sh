#!/bin/sh

# This script partially automate the update of freebsd machines

VERSION=$1
UPGRADE=$2

freebsd-update --currently-running ${VERSION}-RELEASE fetch 
freebsd-update --currently-running ${VERSION}-RELEASE install
freebsd-update --currently-running ${VERSION}-RELEASE -r ${UPGRADE}-RELEASE upgrade
freebsd-update --currently-running ${VERSION}-RELEASE install

