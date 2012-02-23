#!/bin/bash - 
#===============================================================================
#
#          FILE: udown.sh
# 
#         USAGE: ./udown.sh file.conf 
# 
#   DESCRIPTION: Baixa arquivos através do proxy, gerando log
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nilson Pena (), nilsonpena@gmail.com
#  ORGANIZATION: 
#       CREATED: 22-02-2012 18:36:13 BRT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error




# Armazena o nome do arquivo onde o script está salvo
DIR_SCRIPT=$(dirname $0)
# Coloca o path no nome do arquivo passado como parâmetro
CONFIG_FILE="$DIR_SCRIPT/$1"

# garante que o script seja inicializado com um parâmetro de configuração existente e não vazio
if [ ! -e $CONFIG_FILE ] || [ -z $1 ]
	  then
			 	echo "Parâmetro inexistente ou nulo. Rotina abortada"     
				exit
fi

# Remove a extenção do arquivo de configuração, guardando apenas a parte principal do nome
CONFIG_NAME=$(echo $1 | cut -f1 -d.)

# Array que armazena os nomes das variáveis que vão ser buscadas no
# arquivo de configuração
CHAVES=( PROXY_U PROXY_P PROXY_ADDRESS PROXY_PORT URL_DOWN SAVE_TO MAIL_TO FILE_NAME )

# Armazena a quantidade de elementos existentes na array CHAVES
QTD_CHAVES=${#CHAVES[*]}
# Percorre o arquivo de configuração $CONFIG_FILE buscando os valores das variáveis setadas na Array CHAVES
for ((i=0; i<"$QTD_CHAVES"; i++))
	do
		# Seta os valores vindos do arquivo de configuração nas variáveis que vão ser utilizadas no script
		eval ${CHAVES[$i]}=\"$(cat $CONFIG_FILE | egrep ^${CHAVES[$i]}= | cut -f2 -d\")\"
	done																												   

# Local e arquivo de log gerado pelo wget
LOG_WGET="$DIR_SCRIPT/$CONFIG_NAME.log"

LOG_MAIL="$DIR_SCRIPT/$CONFIG_NAME.mail.log"

# Seta a variável de ambiente do proxy do squid
export http_proxy=http://$PROXY_U:$PROXY_P@$PROXY_ADDRESS:$PROXY_PORT

# Pega o nome do servidor
SERVER_NAME=$(hostname)



#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  EmailLog
#   DESCRIPTION:  Envia email preenchendo o corpo com o conteudo de um arquivo
#    PARAMETERS:  nenhum
#       RETURNS:  nada
#-------------------------------------------------------------------------------

EmailLog() {

# Deleta o arquivo de LOG_MAIL anterior
rm -f $LOG_MAIL

# Cabeçalho do arquivo LOG_MAIL
echo "Rotina de Download iniciada em $(date +%F' '%T)" >> $LOG_MAIL
echo "= = = = = = = = = = = = = = = = = = = = = = =" >> $LOG_MAIL
echo " " >> $LOG_MAIL

# Anexa o conteúdo do arquivo LOG_WGET ao fim do arquivo LOG_MAIL
cat $LOG_WGET >> $LOG_MAIL

# Envia email com conteúdo do arquivo de log
ASSUNTO="Download no Servidor $SERVER_NAME em $(date +%F' '%T)"
cat $LOG_MAIL | mail  -s "$ASSUNTO" $MAIL_TO

} 

# -c faz o resume do download se necessário
# -t n Estabelece a quantidade de tentativas de download
# -o local e nome do log gerado pelo wget
# -user-agent Mozilla/4.0 Simula se tratar de um browser Mozilla
# -N Só baixa o arquivo se ele for diferente do que está no servidor, comparando o timestamp e tamanho
# -v modo verboso. Adiciona a barra de progresso ao loss outras informações ao log
# -P Especifica o local onde será salvo o arquivo 
wget -c -v --progress=dot:mega --user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" –proxy=on -o $LOG_WGET -t 8 $URL_DOWN -P $SAVE_TO -O $SAVE_TO/$FILE_NAME

# Envia email com o log do wget
EmailLog

