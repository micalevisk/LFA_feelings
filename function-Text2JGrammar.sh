#!/bin/bash
#
#	v1.26-1
#	Text2JGrammar - Parse PLAIN TEXT para JFLAP Grammar (XML)
#
#	USE:	$ Text2JGrammar.sh "<texto formatado>" [output-file]
#	EXAMPLE:$ Text2JGrammar.sh "P > 0P,1P,1A; A > 0B; B > 1; B>0" mygrammar.jff
#
#	Created by Micael Levi on 11/24/2016
#	Copyright (c) 2016 mllc@icomp.ufam.edu.br; All rights reserved.
#

## TODO otimizar para ler da STDIN (leitura de arquivo onde delimitador de regras são as quebras de linha).
## TODO otimizar para identificar se a entrada está correta.
## TODO otimizar para formatar as regras de acordo com um tipo específico de gramática.


## Especificação do Formato:
: '
- As implicações (setas) são indicadas por ">"
- As regras são separadas por ";"
- O pipe (barra vertical) é indicado por ","
- O lambda é indicado por "§"
- Caso algum símbolo seja igual a algum caractere especial, altere a keyword na função principal
'

#function join_by { local IFS="$1"; shift; echo "$*"; }
function skillJFlap_joinBy { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }
function skillJFlap_help {
	local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/${FUNCNAME[1]}.sh"
	grep -m1 -Pzo "(?<=: '\n)[^']*(?=')" "$DIR"
}


#### FUNÇÃO PRINCIPAL ####
function Text2JGrammar
{

	[ $# -lt 1 ] && { skillJFlap_help ; return 1; }
	
	########## [KEYWORDS] ##########
	local IMPLICACAO='>'
	local LAMBDA='§'
	local DELIM_REGRAS=';'
	local DELIM_SEQUENCIAS=','
	################################

	#######################################[ CONSTANTES ]#######################################
	local TOP="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><!--Created with Text2JGrammar--><structure>&#13;\n\t<type>grammar</type>&#13;\n\t<!--The list of productions.-->&#13;"
	local DOWN="</structure>"
	############################################################################################

	entrada="$1"
	saida="${2}"

	[[ -e "$saida" ]] && {
		read -p "Replace '${saida}' (y)? " -n 1 -r
		[[ ! $REPLY =~ ^[Yy]$ ]] && return 2
		echo -e '\033[u'
		echo -en "\ec"
	}

	shopt -s compat31
	IFS_BKP="$IFS"

	BODY=()

	## Removendo nulos da entrada:
	entrada=$(tr -d '[[:blank:]]' <<< ${entrada})

	## Separando as regras(em um array):
	IFS=$DELIM_REGRAS
	read -ra regras <<< "$entrada"

	## Tratando as regras:
	for regra in "${regras[@]}"
	do
		IFS=$DELIM_REGRAS

		## Definindo variaveis e sequências (separa variavel e sequencia):
		regra=$(sed -r "s/^(\w+?)${IMPLICACAO}(.+)$/\1${DELIM_REGRAS}\2/" <<< ${regra})
		read -ra arr_regra <<< "$regra"
		[ ${#arr_regra[@]} -ne 2 ] && return

		## Montando linha do objeto <left> (variaveis)
		variavel="\t\t<left>${arr_regra[0]}</left>&#13;"

		## Montando linha do objeto <right> (forma sentencial):
		## Verificar se possui multiplas sequencias e, caso tenha separa-as num array:
		forma_sentencial="${arr_regra[1]}"
		if [[ $forma_sentencial =~  ${DELIM_SEQUENCIAS} ]]
		then
			IFS=$DELIM_SEQUENCIAS
			## Separando as formas sentenciais (terminais e variaveis) em um array
			read -ra arr_sequencias <<< "$forma_sentencial"

			## Loop para cada sequencia relacionada a mesma variavel
			for i in ${!arr_sequencias[@]}; do
				sequencia="${arr_sequencias[$i]}"
				[[ $sequencia =~ $LAMBDA ]] && sequencia="\t\t<right/>&#13;" || sequencia="\t\t<right>${sequencia}</right>&#13;"
				arr_sequencias[$i]="\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
			done

			REGRA=$(skillJFlap_joinBy $'\\n' ${arr_sequencias[@]})

		else
			sequencia="\t\t<right>${sequencias}</right>&#13;"
			REGRA="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
		fi

		IFS="$IFS_BKP"
		[ "${REGRA}" ] && BODY+=(${REGRA})
	done


	## EXIBIR RESULTADO:
	RESULTADO="$TOP\n${BODY[@]}\n$DOWN"
	echo -e  "${RESULTADO}" | tee ${saida}

	IFS="$IFS_BKP"
}
	


	
	
# (c) http://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
# (c) http://stackoverflow.com/questions/9792702/does-bash-support-word-boundary-regular-expressions
# (c) http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
# (c) http://ahmed.amayem.com/bash-arrays-2-different-methods-for-looping-through-an-array/
# (c) http://stackoverflow.com/questions/1951506/bash-add-value-to-array-without-specifying-a-key
