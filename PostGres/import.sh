#!/bin/bash

# Definir as variáveis de conexão
db_host="127.0.0.1"
db_user="marcelo"
db_password="********"
db_name="empresas"
table_name="empresas"
separator=";"

# Verificar se o comando postgres está instalado
if ! command -v psql &> /dev/null; then
    echo "O comando 'psql' não está instalado na máquina."
    exit 1
fi

# Testar a conexão com o banco de dados
if ! psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -c "" >/dev/null 2>&1; then
    echo -e "\nNão foi possível estabelecer uma conexão com o banco de dados."
    exit 1
fi
echo -e "\nConexão com o banco de dados estabelecida com sucesso!"

# Verificar se a tabela existe no banco de dados
if ! psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -c "\dt $table_name" >/dev/null 2>&1; then
    echo -e "\nA tabela $table_name não existe no banco de dados.\n"
    exit 1
fi
echo -e "\nA tabela $table_name existe no banco de dados.\n"

# Importar os arquivos CSV para o banco de dados
echo -e "Importando os arquivos CSV para o banco de dados $db_name..."
if ! conn=$(psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -q -t -c "BEGIN; COPY $table_name FROM STDIN WITH DELIMITER '$separator' CSV HEADER;" 2>&1); then
    echo -e "\nErro ao iniciar a transação do banco de dados."
    exit 1
fi

file_counter=0
for csv_file in $(pwd)/csv/*.csv; do
    # Importar o arquivo CSV para o banco de dados
    if ! cat "$csv_file" | psql "$conn" >/dev/null 2>&1; then
        echo -e "\nErro ao importar o arquivo $csv_file.\n"
        psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -q -t -c "ROLLBACK;" >/dev/null 2>&1
        exit 1
    fi
    ((file_counter++))
done

# Finalizar a transação
if ! psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -q -t -c "COMMIT;" >/dev/null 2>&1; then
    echo -e "\nErro ao finalizar a transação do banco de dados.\n"
    psql --host="$db_host" --username="$db_user" --password="$db_password" --dbname="$db_name" -q -t -c "ROLLBACK;" >/dev/null 2>&1
    exit 1
fi

echo -e "\nSucesso! $file_counter arquivos CSV importados para o banco de dados $db_name.\n"
exit 0
