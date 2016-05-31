#!/bin/bash
#interface gráfica para interação com usuário para gerenciamento de usuários nos Ambientes do laboratório HPC LaSCADo
#criado por Bruno L. Amadio Caires - bruno@ft.unicamp.br
#versão 1.0

#importa as funções utilizadas para gerenciamento das bases dos usuários
source /root/bin/funcoes.sh


function principal {
#clear
echo ""
echo "A autenticação das máquinas do laboratório Lascado é realizada em duas bases:"
echo "Uma base local no Cluster IBM-AIX onde é feita a autenticação do mesmo"
echo "Uma base ldap na máquina Holmes onde é feita a autenticação do 'cluster Beowulf', 'cluster IBM-Suse' e 'servidor de SSH' (143.106.243.187)"
echo "A criação de usuários é feita nas duas bases"
echo "Durante a execução será pedido um e-mail (@ft) para ser enviado o termo com usuário e senha criado"
echo "*******************************************************************************************************************************************"


echo "-------------------"
echo "Escolha uma opção:"
echo "------------------"
echo " "
echo "1 ------ cadastro de usuário"
echo "2 ------ cadastro de grupo"
echo "3 ------ excluir usuário (Para o cluster IBM conectar em 143.106.243.190 e excluir localmente)"
echo "4 ------ adiciona usuario para grupo (não realizado no cluster IBM)"
echo "5 ------ Cadastrar usuários em lote"
echo "6 ------ Sair"
echo ""
read -p " " -e escolha
     case $escolha in
	1)
	  export lotes=0
	  cadastrauser
	  principal
  	  ;;
	2)
	  criagrupo
	  principal
	  ;;
	3)
	  deletauser
	  principal
	  ;;
	4)	
	  addtogrupo
	  principal
	  ;;
	5)
	  lote 
	  principal
  	  ;;
	6) 
	  exit
	  ;;
	*)
	  echo "é necessário escolher uma opção"
	  ;;
       esac
}
principal
