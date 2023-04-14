#!/bin/bash

# -------------------------
# Script de importação de arquivos CSV para o MySQL
# -------------------------

# Verificar se o comando mysql está instalado
if ! command -v mysql &> /dev/null
then
    echo "O comando 'mysql' não foi encontrado. Por favor, instale o MySQL antes de executar este script."
    exit
fi

# Definir opções padrão
db_host="127.0.0.1"
db_user="marcelo"
db_password="****"
db_name="empresas"
table_name="empresas"
csv_path=""
separator=";"
delimiter="\""

# Mostrar como usar o script
function show_usage {
    echo -e "Uso: $0 [opções] <arquivos_csv>\n"
    echo -e "Opções:"
    echo -e "  -h, --host\t\tEndereço IP ou nome de host do servidor MySQL (padrão: localhost)"
    echo -e "  -u, --user\t\tNome de usuário do MySQL (padrão: root)"
    echo -e "  -p, --password\tSenha do MySQL (padrão: '')"
    echo -e "  -d, --database\tNome do banco de dados do MySQL (obrigatório)"
    echo -e "  -t, --table\t\tNome da tabela do MySQL (obrigatório)"
    echo -e "  -s, --separator\tSeparador de campo do arquivo CSV (padrão: ;)"
    echo -e "  -l, --delimiter\tDelimitador de campo do arquivo CSV (padrão: \")"
    echo -e "  -h, --help\t\tMostrar esta mensagem de ajuda\n"
    echo -e "Exemplos:"
    echo -e "  $0 -d empresas -t empresas *.csv"
    echo -e "  $0 -h 192.168.0.1 -u admin -p password -d empresas -t empresas -s , -l \"\" *.csv"
}

# Tratar os argumentos de linha de comando
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--host)
        db_host="$2"
        shift
        shift
        ;;
        -u|--user)
        db_user="$2"
        shift
        shift
        ;;
        -p|--password)
        db_password="$2"
        shift
        shift
        ;;
        -d|--database)
        db_name="$2"
        shift
        shift
        ;;
        -t|--table)
        table_name="$2"
        shift
        shift
        ;;
        -s|--separator)
        separator="$2"
        shift
        shift
        ;;
        -l|--delimiter)
        delimiter="$2"
        shift
        shift
        ;;
        -h|--help)
        show_usage
        exit
        ;;
        *)
        csv_path="$1"
        shift
        ;;
    esac
done

# Verificar se foram fornecidos os argumentos obrigatórios
if [ -z "$db_name" ] || [ -z "$table_name" ] || [ -z "$csv_path" ]
then
    echo -e "Erro: faltam argumentos obrigatórios.\n"
    show_usage
    exit 1
fi

# Verificar se a pasta CSV existe e tem permissão de acesso
if [ ! -d "$csv_path" ]
then
    echo -e "Erro:
    \tA pasta '$csv_path' não foi encontrada ou não tem permissão de acesso.\n"
    exit 1
fi

# Importar arquivos CSV para o banco de dados
files=$(find "$csv_path" -type f -name '*.csv')
for file in $files
do
    echo "Importando o arquivo $file ..."
    mysql --host="$db_host" --user="$db_user" --password="$db_password" \
        --database="$db_name" --execute="LOAD DATA INFILE '$file' \
        INTO TABLE $table_name FIELDS TERMINATED BY '$separator' \
        ENCLOSED BY '$delimiter' LINES TERMINATED BY '\n';"
done

echo "Importação concluída!"