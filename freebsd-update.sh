#!/bin/sh

# This script partially automate the update of freebsd machines

freebsd-update --not-running-from-cron fetch

freebsd-update --not-running-from-cron install

freebsd-update --not-running-from-cron -r $1-RELEASE upgrade

freebsd-update --not-running-from-cron install

freebsd-update --not-running-from-cron install
