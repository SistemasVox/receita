#!/bin/bash

# informações de acesso ao banco de dados
db_host="127.0.0.1"
db_user="marcelo"
db_password="xxx"
db_name="empresas"
table_name="empresas"

# Obter o caminho absoluto do arquivo CSV
csv_path="$PWD/uniao_utf8.csv"
#echo -e "\nCaminho absoluto do arquivo CSV: $csv_path"

# Função para testar a conexão com o banco de dados
test_db_connection() {
    local connection_status=$(psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" --command="\q" 2>&1)
    
    if echo "$connection_status" | grep -q "FATAL:"; then
        echo -e "\nNão foi possível estabelecer uma conexão com o banco de dados: $connection_status"
        return 1
    elif echo "$connection_status" | grep -q "Is the server running on host"; then
        echo -e "\nNão foi possível estabelecer uma conexão com o banco de dados: $connection_status"
        return 1
    else
        echo -e "\nConexão com o banco de dados estabelecida com sucesso!"
        return 0
    fi
}

# Perguntar ao usuário se ele deseja importar o arquivo csv para o banco de dados
while true; do
    read -r -p "Deseja importar o arquivo $csv_path para o banco de dados? [s/N] " sn
    case $sn in
        [Ss]* )
            # Verificar se o arquivo existe e tem permissão de acesso
            if [ -e "$csv_path" ]; then
                # Testar a conexão com o banco de dados
                if test_db_connection; then
                    # Importar o arquivo csv para o banco de dados
					invalid_rows_path="$(pwd)/invalid_rows.txt"
					echo -e "\nComeçando a importar o arquivo $csv_path..."					
					PGPASSWORD="$db_password" psql --host="$db_host" --username="$db_user" --dbname="$db_name" -v ON_ERROR_STOP=1 -c "\COPY $table_name FROM '$(pwd)/uniao_utf8.csv' WITH (FORMAT CSV, DELIMITER ';', HEADER false);" || true
					
                    psql_exit_code=$?
                    if [ $psql_exit_code -eq 0 ]; then
                        echo -e "\nArquivo $csv_path importado para o banco de dados com sucesso!"
                        break
                    else
                        echo -e "\nOcorreu um erro durante a importação do arquivo $csv_path para o banco de dados."
                        echo -e "\nCódigo de saída do comando psql: $psql_exit_code"
                    fi
                fi
            else
                echo -e "\nO arquivo $csv_path não existe ou não tem permissão de acesso."
            fi
        ;;
        [Nn]* )
            echo -e "\nImportação do arquivo $csv_path cancelada pelo usuário."
            break
        ;;
        * )
            echo -e "\nPor favor, responda s ou n."
        ;;
    esac
done
