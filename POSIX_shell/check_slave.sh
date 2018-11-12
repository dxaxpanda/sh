#!/bin/sh

CHECK=$(mysql -e 'SHOW SLAVE STATUS\G' |grep -Ei 'Slave_SQL_Running:\s' |awk '{print $2}')

if test "${CHECK#*$Yes}" == "Yes"; then
  printf "[+] %s" "Slave is running."
  /usr/bin/curl -fsS --retry 3 https://status.skores.eu/ping/3ac0c2f2-67a8-4c11-a3a2-da1cb79f0689 
else
  printf "[!] %s" "Replication broken, slave is not running ! "
fi
      
