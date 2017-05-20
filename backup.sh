#!/bin/sh

## backup des répertoires importants
wd=~  /backup
users_home=/usr/home/*
groups=/etc/group
mdp=/etc/passwd
master=/etc/master.passwd
old_server_ip=51.254.227.134
old_server_port=2234
user=jmirre
new_server_ip=51.254.227.148
new_server_port=221


# copie fichiers importants HOST
scp -r -P $old_server_port $user@$old_server_ip:$wd
