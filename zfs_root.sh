#!/bin/sh
HOST=$1
#route="178.33.234.94"



## OVH config
INET="51.254.227.150"
NETMASK="255.255.255.255"
GATEWAY_NETWORK="5.135.138.0"
GATEWAY_IP="5.135.138.254"
DNS="nameserver 213.186.33.99"
ROUTE_1=""
ROUTE_2=""

zpool destroy -f zroot

gpart destroy -F ada0
gpart destroy -F ada1

gpart create -s gpt ada0
gpart create -s gpt ada1

gpart add -t freebsd-boot -l boot0 -a 4k -s 512k ada0
gpart add -t freebsd-swap -l swap0 -a 4k -s 8g ada0
gpart add -t freebsd-zfs -l disk0 ada0

gpart add -t freebsd-boot -l boot1 -a 4k -s 512k ada1
gpart add -t freebsd-swap -l swap1 -a 4k -s 8g ada1
gpart add -t freebsd-zfs -l disk1 ada1

gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada0

kldload zfs

## Align for 4k sector
#sysctl vfs.zfs.min_auto_ashift=12

## MIRROR

#zpool create -f -m none -o altroot=/mnt -o cachefile=/tmp/zpool.cache -O compress=lz4 -O atime=off zroot mirror gpt/disk0 gpt/disk1
zpool create -f -m none -o altroot=/mnt -o cachefile=/tmp/zpool.cache -O compress=lz4 -O atime=off zroot gpt/disk0 

zfs set mountpoint=/mnt/ zroot
zfs create -o mountpoint=/usr zroot/usr
zfs create -o mountpoint=/var zroot/var
zfs create -o mountpoint=/var/mail zroot/var/mail
zfs create -o mountpoint=/var/crash zroot/var/crash
zfs create -o mountpoint=/var/log zroot/var/log
zfs create -o mountpoint=/var/db zroot/var/db
zfs create -o mountpoint=/var/db/pkg zroot/var/db/pkg
zfs create -o mountpoint=/var/empty zroot/var/empty
zfs create -o mountpoint=/var/run zroot/var/run
zfs create -o mountpoint=/var/tmp zroot/var/tmp
zfs create -o mountpoint=/jails zroot/jails
zfs create -o mountpoint=/tmp zroot/tmp
zfs create -o mountpoint=/www zroot/www
zfs create -o mountpoint=/usr/home zroot/usr/home

zpool set bootfs=zroot zroot
zfs set checksum=fletcher4 zroot

cd /mnt

fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/11.0-RELEASE/base.txz
fetch ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/11.0-RELEASE/kernel.txz
tar --unlink -Jxpf base.txz -C /mnt
tar --unlink -Jxpf kernel.txz -C /mnt
rm base.txz kernel.txz

cat << EOF > /mnt/etc/rc.conf
hostname="${HOST}"
sendmail_enable="NONE"
hostid_enable="NO"
keymap="fr.acc"
ifconfig_em0="inet ${INET} netmask ${NETMASK} broadcast ${INET}"
route_net1="-net ${GATEWAY_IP}/32 -iface em0"
route_net2="${GATEWAY_IP}
static_routes="net1 net2"
defaultrouter="${GATEWAY_IP}"
fsck_y_enable="YES"
background_fsck="YES"
zfs_enable="YES"
sshd_enable="YES"
jail_enable="YES"
jail_conf="/etc/jail.conf"
EOF

cat << EOF > /mnt/boot/loader.conf

zfs_load="YES"
vfs.root.mountfrom="zfs:zroot"
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="9600"
console="comconsole"
comconsole_port="0x2F8"
EOF

cat << EOF > /mnt/etc/fstab
 # Device                       Mountpoint              FStype  Options         Dump    Pass#
 /dev/gpt/swap0                 none                    swap    sw              0       0
 /dev/gpt/swap1                 none                    swap    sw              0       0
EOF

cp /tmp/zpool.cache /mnt/boot/zfs/zpool.cache

#vi /mnt/etc/ssh/sshd_config
#ou

echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config
echo 'PermitEmptyPasswords no' >> /mnt/etc/ssh/sshd_config
zfs set mountpoint=legacy zroot

chmod 1777 /mnt/tmp

chroot /mnt passwd
chroot /mnt mount -t devfs devfs /dev

#exit

#et enfin

mount -t devfs devfs /dev

#reboot
