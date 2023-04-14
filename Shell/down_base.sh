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
if [ ! -d "$csv_dir" ]
then
    mkdir "$csv_dir"
fi

# Verificar se a URL está corretamente formatada
if ! curl -s --head "$url" | grep -q "200 OK"; then
    echo -e "\nErro: URL mal formatada"
    exit 1
fi

# Exibir todos os links dos arquivos zip relacionados aos estabelecimentos
echo -e "\nLinks dos arquivos zip relacionados aos estabelecimentos:"
curl -s "$url" | awk -F 'href="' '/Estabelecimentos/ && /zip"/ {print $2}' | cut -d '"' -f 1
echo -e "\n"

# Baixar cada arquivo zip
downloaded_files=0
for file in $(curl -s "$url" | awk -F 'href="' '/Estabelecimentos/ && /zip"/ {print $2}' | cut -d '"' -f 1)
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

    # # Descompactar o arquivo zip e renomear o arquivo resultante
    # if unzip -q "$filename" -d "$csv_dir"; then
        # for csv_file in "$csv_dir"/*.ESTABELE; do
            # if [[ -f "$csv_file" ]]; then
                # new_filename="${csv_file%.ESTABELE}.csv"
                # mv "$csv_file" "$new_filename"
                # downloaded_files=$((downloaded_files+1))
            # fi
        # done
    # else
        # echo -e "\nErro ao abrir o arquivo $filename"
        # continue
    # fi

done

echo -e "\nBaixados $downloaded_files arquivos com sucesso."


# Verificar se pelo menos um arquivo csv foi descompactado
if ! ls "$csv_dir"/*.csv >/dev/null 2>&1; then
    echo -e "\nErro: Não foi possível encontrar nenhum arquivo CSV."
    exit 1
fi

# echo -e "\nComeçando a importar os srquivos para o MySQL...\n"
# bash import_psl.sh

# echo -e "\nExcluindo diretórios zip e csv..."
# rm -rf "$dir" "$csv_dir"

#Armazenar a hora de término
end_time=$(date +%s)

# Calcular o tempo de execução em segundos
execution_time=$((end_time - start_time))

# Converter o tempo de execução para um formato legível
formatted_time=$(date -u -d @$execution_time +'%H:%M:%S')

# Mostrar o tempo de execução ao usuário
echo -e "\n\nTempo de execução do script: $formatted_time"