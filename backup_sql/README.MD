Backup script

Malgré notre système répliqué mariadb master-slave il est malgré tout nécessaire de faire des backups ; le raid, haute disponibilité / continuité de service n'était pas une solution de backup, un script a été implanter en cas de force majeur. Réalisé en bash il permet par le biais d'un cron de dump toutes les données sensibles clientes sur la grappe glusterfs avec encryption, assurant ainsi la réplicité des données inter-datacenter de manière sécurisé. Ensuite les données seront renvoyés sur le serveur d'un contractant externe spécialiste du backup et archivage.

Tout d'abord il nous est nécessaire de générer une paire de clefs afin de permettre l'encryption et décrypter les donnés par la suite. C'est le principe de PKI qui est utilisé, avec une clef privée ( qui doit rester secrete absolument dans tous les cas ; c'est la clef qui est utilisé pour décrypter les données ) et une clef publique que l'on va partager et permettre à ceux qui la détienne d'envoyer des données cryptées ( qui vont être décrypter par la clef privée par la suite, et vice-versa ).

On utilise openssl pour la création de la paire de clefs:

mkdir -p /.dec/$(date +"%F")
openssl genrsa -out /.dec/key.pem 4096
openssl rsa -in /.dec/key.pem -out /.dec/key-public.pem -outform PEM -pubout

Ensuite générons une passphrase aléatoire de 32bits :

openssl rand 32 -out /.dec/$(date + "%F")/randompassphrase.itsnothing.really

Il va falloir créer un utilisateur dédié au backup sur le serveur mysql.

mysql> GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT, SELECT ON *.* TO 'bkpuser'@'172.10.10.20' IDENTIFIED BY 'example';
mysql> FLUSH PRIVILEGES;

Le fichier ~/.my.cnf est a configurer avec les credentials d'accès du backup user ce qui nous evite de renseigner le mot de passe à chaque invocation.
[client]
user=bkpuser
password=example

Voici le script de backup pour l'export des bases de données encryptées.


Pour décrypter la passphrase avec la clef privée on utilise les commandes suivantes :

# decrypts encrypted passphrase with private key

openssl rsautl -decrypt -inkey /.dec/key.pem < enc randompassphrase.itsnothing.really > key.txt

# decrypts file

openssl enc -aes-256-cbc -d -pass file:/.dec/key.txt < /.dec/<date_of_the_day>.dat > UNENCRYPTED_FILE

Avec cron on peut définir une tache planifier en arrière plan à effectuer tous les jours à une horaires précise :

# crontab -e
# 0 4 * * * /var/lib/ecron/<script_name>.sh

Pour résumer :

- les clefs sont garder dans le dossier /.dec/ ;
- les backups se font de manières journalières et compressées en tar.gz dans le dossier de backup prévu à cette effet sur la grappe glusterfs répliquée : /mnt/data/mysqldata ;
- une archives est recrée pour le dossier de backup du jour en tar.gz qui comprend toutes les autres bases de données archivées. Cette archive est présente dans le dossier : /export/<date_du_jour>/<date_du_jour-backup.tar.gz.
- cette archive est encryptée avec notre keypair et passphrase dans le dossier  /export/<date_du_jour>/encrypted.dat ;
- cette passphrase est encryptée à son tour dans le dossier /.dec/ avec la clef publique ;
- enfin cette archives encryptées est envoyé sur le serveur distant de backup du contractant  par le biais d'un secure copy;
- pour décrypter le fichier il est nécessaire décrypter la passphrase ce qui insinue donc qu'il faille être en possession d'un accès distant root à la machine, de la passphrase ET de la paire de clefs.
