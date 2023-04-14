#!/bin/bash

# Definir função de manipulador de sinais
function on_sigint {
    echo -e "\n\nO download foi interrompido pelo usuário."
    exit 1
}

# Configurar o manipulador de sinais para o sinal SIGINT (Ctrl + C)
trap on_sigint SIGINT

# Armazenar a hora de início
start_time=$(date +%s)

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


url="https://dadosabertos.rfb.gov.br/CNPJ/"
echo "URL: $url"

# Criar um diretório para armazenar os arquivos zip
dir="zip"
if [ ! -d "$dir" ]
then
    mkdir "$dir"
fi

# Criar um diretório para armazenar os arquivos csv
csv_dir="csv"
if [ -d "$csv_dir" ]; then
  rm -rf "$csv_dir"
fi
mkdir "$csv_dir"

# Verificar se a URL está corretamente formatada
if ! curl -s --head "$url" | grep -q "200 OK"; then
    echo -e "\nErro: URL mal formatada"
    exit 1
fi

# Exibir todos os links dos arquivos zip relacionados aos Motivos
echo -e "\nLinks dos arquivos zip relacionados aos Motivos:"
curl -s "$url" | awk -F 'href="' '/Motivos/ && /zip"/ {print $2}' | cut -d '"' -f 1
echo -e "\n"

# Baixar cada arquivo zip
downloaded_files=0
for file in $(curl -s "$url" | awk -F 'href="' '/Motivos/ && /zip"/ {print $2}' | cut -d '"' -f 1)
do
    filename="$dir/$(basename "$file")"
    if [ -f "$filename" ]
    then
        rm "$filename"
    fi
    echo -e "\nBaixando $file...\n"
    
    downloaded_successfully=false
    tries=0
    while [ "$downloaded_successfully" = false ] && [ "$tries" -lt 3 ]; do
        echo -e "Tentativa $((tries+1)) de 3: Baixando $file\n"
        if ! wget -c "$url$file" -O "$filename"; then
            echo -e "\n\nErro ao baixar o arquivo $file"
            tries=$((tries+1))
        else
            downloaded_successfully=true
        fi
    done

    # Verificar se o arquivo zip foi baixado corretamente
    if [ "$(stat -c%s "$filename")" -lt 1000 ]; then
        echo -e "\nErro: O arquivo $filename parece estar vazio ou incompleto."
        continue
    fi

    # Descompactar o arquivo zip e renomear o arquivo resultante
    if unzip -q "$filename" -d "$csv_dir"; then
			for csv_file in "$csv_dir"/*; do
				if [[ -f "$csv_file" ]]; then
					# Armazenar o nome do arquivo descompactado em uma variável
					file_extension=$(echo "$csv_file" | awk -F . '{print $NF}')
					if [ "$file_extension" != "csv" ]; then
						new_filename="$csv_dir/motivos.csv"
						mv "$csv_file" "$new_filename"
						downloaded_files=$((downloaded_files+1))
					fi
				fi
			done

		else
		echo -e "\nErro ao abrir o arquivo $filename"
		continue
    fi

done

echo -e "\nBaixados $downloaded_files arquivos com sucesso."

# Verificar se pelo menos um arquivo csv foi descompactado
if ! ls "$csv_dir"/*.csv >/dev/null 2>&1; then
    echo -e "\nErro: Não foi possível encontrar nenhum arquivo CSV."
    exit 1
fi

file="$csv_dir/motivos.csv"
# Importar os dados para a tabela
if mysql --host="$db_host" --user="$db_user" --password="$db_password" --local-infile=1 --max_allowed_packet=1G -e "USE $db_name; DROP TABLE IF EXISTS motivos; CREATE TABLE motivos (motivos INT, descricao VARCHAR(255)); LOAD DATA LOCAL INFILE '$file' INTO TABLE motivos FIELDS TERMINATED BY '$separator' ENCLOSED BY '$delimiter' LINES TERMINATED BY '\n';"; then
  # Mensagem de sucesso
  echo -e "Arquivo CSV $(basename "$file") importado com sucesso para a tabela $table_name.\n"
else
  # Mensagem de erro
  echo -e "\nErro ao importar o arquivo CSV $(basename "$file") para a tabela $table_name. Verifique a mensagem de erro acima.\n"
fi


#Armazenar a hora de término
end_time=$(date +%s)

# Calcular o tempo de execução em segundos
execution_time=$((end_time - start_time))

# Converter o tempo de execução para um formato legível
formatted_time=$(date -u -d @$execution_time +'%H:%M:%S')

# Mostrar o tempo de execução ao usuário
echo -e "\n\nTempo de execução do script: $formatted_time"