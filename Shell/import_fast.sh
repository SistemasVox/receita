#!/bin/bash

# Nome do script: script_importacao_csv.sh
# Descrição: Este script importa arquivos CSV para uma tabela em um banco de dados MySQL.
# Autor: Marcelo Vieira
# Data de criação: [Data de criação aqui]
# Versão: 1.0

# Histórico de versões:
# 1.0 [29/03/2023]: Versão inicial do script.

# Uso: ./script_importacao_csv.sh

# Requisitos:
# - MySQL deve estar instalado e configurado.
# - O usuário do banco de dados deve ter as permissões necessárias para executar o script e importar dados para a tabela.
# - Os arquivos CSV devem estar na pasta 'csv' no mesmo diretório do script.

# Notas:
# - Este script não lida com possíveis erros de formato ou conteúdo dos arquivos CSV.
# - Este script não faz backup do banco de dados antes de executar a importação. Certifique-se de ter um backup recente antes de executar o script.

# Limitações conhecidas:
# - Este script não lida com caracteres especiais em nomes de arquivos ou dados dentro dos arquivos CSV.
# - Este script não suporta arquivos CSV com delimitadores ou separadores diferentes dos definidos nas variáveis 'separator' e 'delimiter'.

#--------------------------------------- Início do script ---------------------------------------#

# Função para manipulação do sinal SIGINT (Ctrl + C)
function on_sigint {
    echo -e "\n\nA importação foi interrompida pelo usuário."
    exit 1
}

# Configurar o manipulador de sinais para o sinal SIGINT
trap on_sigint SIGINT

# Verificar se o comando mysql está instalado
if ! command -v mysql &> /dev/null; then
  echo "O comando 'mysql' não está instalado. Instale o MySQL e tente novamente."
  exit 1
fi

clear

# Verificar se a pasta CSV existe
if [ ! -d "csv" ]; then
  echo "A pasta CSV não existe."
  exit 1
fi

# informações de acesso ao banco de dados
db_host="localhost"
db_user="marcelo"
db_password="xxx"
db_name="empresas"
table_name="empresas"

# Verificar se a conexão com o banco de dados foi bem sucedida
if ! mysql --host="$db_host" --user="$db_user" --password="$db_password" -e "SHOW DATABASES;" &> /dev/null; then
  echo "Não foi possível conectar ao banco de dados. Verifique as informações de acesso e tente novamente."
  exit 1
fi

# Obter o caminho absoluto da pasta CSV
csv_path="$PWD/csv"
echo "Caminho absoluto da pasta CSV: $csv_path"

# Inicializar variável de importação
separator=";"
delimiter="\""

# Verificar se há arquivos CSV para importar
if ! ls "$csv_path"/*.csv &> /dev/null; then
  echo "Não há arquivos CSV na pasta $csv_path."
  exit 1
fi

# Obter o número total de linhas dos arquivos CSV
total_num_lines=0
for file in $csv_path/*.csv; do
  num_lines=$(wc -l "$file" | awk '{print $1}')
  total_num_lines=$((total_num_lines + num_lines))
done

echo -e "Total de linhas nos arquivos CSV: $(printf "%'d" $total_num_lines)\n"

# Importar os arquivos CSV para o banco de dados
for file in $csv_path/*.csv; do
  echo -e "$(date +%T) Importando o arquivo CSV: $(basename "$file")..."
  
  # Corrigir o arquivo
  echo -e "$(date +%T) Corrigindo o arquivo CSV: $(basename "$file")..."
  sed -i 's/\\//g' "$file"
  echo -e "$(date +%T) Arquivo $(basename "$file") corrigido com sucesso."
  
  # Importar os dados para a tabela
  echo -e "Importando o arquivo $(basename "$file") para a tabela $table_name..."
  if mysql --host="$db_host" --user="$db_user" --password="$db_password" --local-infile=1 --max_allowed_packet=1G -e "USE $db_name; LOAD DATA LOCAL INFILE '$file' INTO TABLE $table_name FIELDS TERMINATED BY '$separator' ENCLOSED BY '$delimiter' LINES TERMINATED BY '\n';"; then
    # Mensagem de sucesso
    echo -e "$(date +%T) Arquivo CSV $(basename "$file") importado com sucesso para a tabela $table_name.\n"
  else
    # Mensagem de erro
    echo -e "\n$(date +%T) Erro ao importar o arquivo CSV $(basename "$file") para a tabela $table_name. Verifique a mensagem de erro acima.\n"
    continue
  fi
done

# Comparar o número total de linhas importadas com o número total de linhas nos arquivos CSV
total_rows=$(echo "SELECT COUNT(*) FROM $table_name;" | mysql -h"$db_host" -u"$db_user" -p"$db_password" "$db_name" | awk 'NR==2{print $1}')

# Verificar se a importação foi bem sucedida
if [ $? -eq 0 ]; then
  # Mensagem de sucesso
  echo -e "\nForam importados um total de $(echo "$total_rows" | sed ':a;s/\B[0-9]\{3\}\>/.&/;ta') linhas dos arquivos CSV para a tabela $table_name."
  # Calcular a diferença de linhas entre os arquivos CSV e a tabela
  diff_lines=$((total_num_lines - total_rows))
  if (( diff_lines == 0 )); then
    echo -e "Não há diferença de linhas entre os arquivos CSV e a tabela."
  else
    echo -e "\nA diferença total de linhas entre os arquivos CSV e a tabela é de $(printf "%'d" $diff_lines) linhas."
  fi
else
  echo -e "\nFalha na importação dos arquivos CSV para o banco de dados."
fi
exit 0
