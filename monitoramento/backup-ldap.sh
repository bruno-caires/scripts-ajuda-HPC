#! /bin/bash
#backup-ldap.sh  - script para fazer backups da base ldap
#Bruno L. Amadio Caires - bruno @ ft.unicamp.br - 2013
hj=`date +%Y%m%d`

ldapsearch -x -LLL -D "cn=admin,dc=holmes,dc=ft,dc=unicamp,dc=br" -w xxxxxxx -b "dc=holmes,dc=ft,dc=unicamp,dc=br" > /root/bkp/$hj-bkp.ldif
cd /root/bkp
tar -czvf $hj-bkp.tar.gz $hj-bkp.ldif
rm $hj-bkp.ldif
