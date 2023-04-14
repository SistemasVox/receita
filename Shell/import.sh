#!/bin/bash
# Este script tem como objetivo importar arquivos CSV para o banco de dados. Antes de iniciar o processo de importação, ele verifica se o comando mysql está instalado na máquina e testa a conexão com o banco de dados informado pelo usuário. Em seguida, ele verifica se a tabela existe no banco de dados e pergunta ao usuário se ele deseja importar os arquivos CSV da pasta informada.

# Caso o usuário escolha importar os arquivos, o script percorre os arquivos da pasta CSV, verifica se eles existem e têm permissão de acesso e, em seguida, os importa para a tabela no banco de dados informado pelo usuário. Ao final do processo, o script informa quantos arquivos foram importados com sucesso e quantas linhas foram importadas no total.

clear
# Verificar se o comando mysql está instalado
if ! command -v mysql &> /dev/null; then
    echo "O comando 'mysql' não está instalado na máquina."
    exit 1
fi

# informações de acesso ao banco de dados
db_host="127.0.0.1"
db_user="marcelo"
db_password="***********"
db_name="empresas"
table_name="empresas"

# Obter o caminho absoluto da pasta CSV
csv_path="$PWD/csv"
echo "Caminho absoluto da pasta CSV: $csv_path"

# Inicializar variável de contador
file_counter=0
total_rows=0

# Inicializar variável de importação
separator=";"
delimiter="\""

# Função para testar a conexão com o banco de dados
test_db_connection() {
    if mysql --host="$db_host" --user="$db_user" --password="$db_password" --execute="use $db_name" >/dev/null 2>&1; then
        echo -e "\nConexão com o banco de dados estabelecida com sucesso!"
        return 0
    else
        echo -e "\nNão foi possível estabelecer uma conexão com o banco de dados."
		echo -e "\nErro:\n$(mysql --host="$db_host" --user="$db_user" --password="$db_password" --execute="use $db_name" 2>&1)"
        return 1
    fi
}

# Função para verificar se a tabela existe no banco de dados
check_table_existence() {
    if mysql --host="$db_host" --user="$db_user" --password="$db_password" --execute="use $db_name; describe $table_name" >/dev/null 2>&1; then
        echo -e "\nA tabela $table_name existe no banco de dados.\n"
        return 0
    else
        echo -e "\nA tabela $table_name não existe no banco de dados.\n"
        return 1
    fi
}

# Perguntar ao usuário se ele deseja importar os arquivos csv para o banco de dados
echo -e "Este script importa arquivos CSV para o banco de dados $db_name.\n"
while true; do
	sudo rm -rf /tmp/*
    read -r -p "Deseja importar os arquivos CSV da pasta $csv_path para o banco de dados? [s/N] " sn
    case $sn in
        [Ss]* )
            # Verificar se a pasta existe e tem permissão de acesso
            if [ -e "$csv_path" ]; then
                # Testar a conexão com o banco de dados
                if test_db_connection; then
                    # Verificar se a tabela existe no banco de dados
                    if check_table_existence; then

						# Pedir ao usuário para informar o separador e o delimitador
						read -r -p "Informe o separador do arquivo CSV [;]: " separator
						separator="${separator:-;}"
						read -r -p "Informe o delimitador do arquivo CSV [\"]: " delimiter
						delimiter="${delimiter:-\"}"

						# Percorrer os arquivos CSV da pasta 
						for csv_file in "$csv_path"/*; do
							# Verificar se o arquivo existe e tem permissão de acesso
							if [ -e "$csv_file" ]; then
								# Importar o arquivo CSV para o banco de dados
								echo -e "Importando o arquivo $csv_file para o banco de dados $db_name...\n($(wc -l < "$csv_file") linhas, $(du -h "$csv_file" | awk '{print $1 "GB"}'))" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
								echo -e
								if mysql --host="$db_host" --user="$db_user" --password="$db_password" --execute="use $db_name; set foreign_key_checks=0; load data local infile '$csv_file' into table $table_name fields terminated by '$separator' enclosed by '$delimiter';" >/dev/null 2>&1; then
									echo "Arquivo $csv_file importado com sucesso!"
									# Incrementar o contador
									((file_counter++))
									# Contabilizar o número de linhas
									total_rows=$((total_rows + $(wc -l < "$csv_file")))
								else
									echo -e "\nErro ao importar o arquivo $csv_file.\n"
								fi
							else
								echo -e "\nO arquivo $csv_file não existe ou não tem permissão de acesso.\n"
							fi
						done
						# Mensagem de conclusão
						echo -e "\n$file_counter arquivo(s) CSV importado(s) com sucesso para o banco de dados $db_name.\nForam importados um total de $(echo "$total_rows" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta') linhas.\n"
					else
						echo -e "\nO script será abortado.\n"
						exit 1
					fi
				else
					echo -e "\nO script será abortado.\n"
					exit 1
				fi
			else
				echo -e "\nA pasta $csv_path não existe ou não tem permissão de acesso.\n"
				echo -e "\nO script será abortado.\n"
				exit 1
			fi
            break
            ;;
        [Nn]* )
            echo -e "\nO script será abortado.\n"
            exit
            ;;
        * )
            echo -e "\nResponda apenas 's' ou 'N'.\n"
            ;;
    esac
done