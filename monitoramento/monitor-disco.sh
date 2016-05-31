#!/bin/bash
#script verificação partição, caso maior que 90% de lotação envia e-mail
#criado por Bruno L. Amadio Caires - bruno@ft.unicamp.br - 2014
#colocar na crontab 0 8 * * * /root/bin/monitor-disco.sh 
#versão 1.0


lot=`df -lah /home | grep /home | awk -F " " '{print $5}' | tr % " "`
if [ $lot -gt 90 ]
then 
printf "Subject: disco cheio
              From: bruno@adm130.ft.unicamp.br
              To: bruno@ft.unicamp.br\n
              Ola,\n
              Particao Home do server Holmes cheio.\n
              att,\n
              Bruno" | /usr/sbin/sendmail -f bruno@adm130.ft.unicamp.br bruno@ft.unicamp.br
else 
echo "part ok"
fi

