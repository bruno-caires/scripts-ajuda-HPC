#!/bin/bash
#Funções para gerencia dos usuários do Cluster HPC LaSCADo
# script de cadastro de usuário na base ldap criado por Bruno 22/05/2013

#versão 1.0
# Será necessário criar um arquivo usuarios com os campos user e nome completo
# Ex: usuario2:usuário temporário
#versão 2.0
#adiciona usuarios lendo do teclado e cria termo de uso
#versão 3.0
#Feito melhorias e comentário para tornar script mais legível

#inicializado funções 
suffix="dc=holmes,dc=ft,dc=unicamp,dc=br"
senha="xxxxxx"
passwd="xxxxxx"
imprimi="n"

#função para leitura de dados em caso de cadastro individual de usuários
function ledados {
/bin/rm /root/bin/usuarios 2> /dev/null
read -p "Login desejado                  :" -e login
read -p "Nome completo				:" -e nome
echo -e """\n\nCaso queira receber por e-mail os dados usuário e senha digite um e-mail (necessário ser @ft.unicamp.br)""" 
echo -e "O arquivo pdf ficará salvo em /root/termos\n"
read -p "" -e envia
echo $login":"$nome > /root/bin/usuarios
}

#cria grupo, adiciona no ldap e envia para cluster IBM-AIX através de scp para adição local de grupo
function criagrupo {
read -p "Digite o nome do grupo:   " -e group
echo $group > /root/termos/group.txt
num=$(getent group | awk -F ":" '{ print $3}' | sort -n | tail -n 2 | head -n 1)	
num=$(($num + 1))
echo """
DN: cn=$group,ou=Group,dc=holmes,dc=ft,dc=unicamp,dc=br
gidNumber: $num
cn: $group
objectClass: posixGroup
objectClass: top
""" | ldapadd -x -D "cn=admin,$suffix" -w $senha
scp /root/termos/group.txt 143.106.243.190:/work1/termos
ssh 143.106.243.190 /usr/bin/python /work1/local/bin/cadgroup.py
}

#função deleta usuário, não funciona para cluster IBM-AIX
function deletauser {
read -p "Digite o nome de usuário que será deletado: " -e user
echo "uid=$user,ou=People,$suffix" | ldapdelete -x -D "cn=admin,$suffix" -w $senha
}

# Funcao Adicionar usuario a grupo
function addtogrupo {
    echo -n "Entre com o Login do usuario.: "
    read login
    echo -n "Entre com o Grupo que ele deve ser adicionado.: "
    read Grupo
    echo "dn: cn=$Grupo,ou=Group,dc=holmes,dc=ft,dc=unicamp,dc=br" > /tmp/AddGrupo.ldif
    echo "changetype: modify" >> /tmp/AddGrupo.ldif
    echo "add: Memberuid" >> /tmp/AddGrupo.ldif
    echo "Memberuid: $login" >> /tmp/AddGrupo.ldif
    echo "#===== Mensagens do sistema =====#"
    ldapmodify -x -D "cn=admin,dc=holmes,dc=ft,dc=unicamp,dc=br" -w $passwd -f /tmp/AddGrupo.ldif
    echo
    echo "Pressione qualquer tecla para continuar..."
}

#função para cadastro de usuários
function cadastrauser {
if [ $lotes -eq 0 ]
	then
		ledados
fi
#verifica qual o grupo pertence o usuário, caso não informado o padrão é grupo cluster
passwd="xxxxxx"
read -p "Qual será o grupo que o usuário pertencerá (padrão grupo cluster deixe em branco):     " -e grp
if [ -z "$grp" ]
then
	grp="cluster"
	gidnum=500
else
        gidnum=$(getent group | grep $grp | awk -F ":" '{print $3}')
fi
export gidnum
#LE arquivo com dados dos usuários
cat /root/bin/usuarios | while read x
do
   #na sequencia pega ultimo userid e incrementa em 2 para adição do usuário, pega user testa se já existe
   num=$(getent passwd | tail -n 1 | awk -F ":" '{ print $3}')
   nome=$(echo "$x" | awk -F":" '{print $2}')
   user=$(echo "$x" | awk -F":" '{print $1}')
   teste=$(id $user 2> /dev/null)
   if [ -z "$teste" ]
   then
         num=$(($num +2))
	 echo """
DN: uid=$user,ou=People,dc=holmes,dc=ft,dc=unicamp,dc=br
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
cn: $nome
gecos: $nome
gidNumber: $gidnum
homeDirectory: /home/$user
loginShell: /bin/bash
shadowLastChange: 15812
shadowMax: 99999
shadowWarning: 7
uid: $user
uidNumber: $num
userPassword:: zMDU4cHNMdW8=
""" > /root/bin/usuario-cadastrar.ldap

   senha=$(pwgen -1)

   echo "Adicionando o usuário $user no cluster Beowulf"
   ldapadd -x -D "cn=admin,dc=holmes,dc=ft,dc=unicamp,dc=br" -w $passwd -f /root/bin/usuario-cadastrar.ldap
   ldappasswd -x -h localhost -D "cn=admin,dc=holmes,dc=ft,dc=unicamp,dc=br" -w $passwd -s $senha uid=$user,ou=People,dc=holmes,dc=ft,dc=unicamp,dc=br
   #gera termo de compromisso do usuário
   echo "gerando o termo em /root/termos"
   cp /root/termos/termo/termo.tex /root/termos/$user.tex
   sed -i "s/{user}/$user/g" /root/termos/$user.tex
   sed -i "s/{senha}/$senha/g" /root/termos/$user.tex
   sed -i "s/{nome}/$nome/g" /root/termos/$user.tex
   cd /root/termos
   echo $user:$nome:$senha:$grp > /root/termos/senha.txt
   scp /root/termos/senha.txt 143.106.243.187:/root/termos
   ssh 143.106.243.187 /bin/bash /root/bin/cadastra.sh &
   if [ $lotes -eq 0 ]
	then
   	    scp /root/termos/senha.txt 143.106.243.190:/work1/termos/
   	    ssh 143.106.243.190 /usr/bin/python /work1/local/bin/caduser.py
	else 
	    echo $user:$nome:$senha:$grp >> /root/termos/senha-lote.txt
   fi
   echo "gerando pdf com informações da conta em /root/termos"
   pdflatex $user.tex  > /dev/null

      if [ ! -z "$envia" ]
        then
   	sendemail -f bruno@adm130.ft.unicamp.br -t $envia -u "Usuario de acesso aos ambientes do Lab Lascado" -m "Em anexo informações para o acesso" -a /root/termos/$user.pdf
	#caso queira imprimir descomente a linha abaixo
	#lp -d HP_LaserJet_4250 /root/termos/$user.pdf
      fi
   else
      echo "usuário $user já existe";
      
   fi
done
}

#caso o cadastro seja mais de um usuário pode usar a função lote
function lote {
echo "Para cadastrar em lote adicione em /root/bin/usuarios todos os usuário 1 por linha sendo nome:usuario"
export lotes=1
cadastrauser
scp /root/termos/senha-lote.txt 143.106.243.190:/work1/termos/
ssh 143.106.243.190 /usr/bin/python /work1/local/bin/caduser-lote.py &
rm /root/termos/senha-lote.txt
}
