#!/bin/bash
clear

ZIP_DIR="./zip"
CSV_DIR="./csv"

# Verificar se a pasta zip existe
if [ ! -d "$ZIP_DIR" ]; then
    echo "A pasta $ZIP_DIR não existe."
    exit 1
fi

# Verificar se existem arquivos .zip dentro da pasta zip
shopt -s nullglob
zip_files=("$ZIP_DIR"/*.zip)
if [ ${#zip_files[@]} -eq 0 ]; then
    echo "Não há arquivos .zip dentro da pasta $ZIP_DIR."
    exit 1
fi

# Função para manipulação do sinal SIGINT (Ctrl + C)
function on_sigint {
    echo -e "\n\nO download foi interrompido pelo usuário."
    exit 1
}

# Configurar o manipulador de sinais para o sinal SIGINT
trap on_sigint SIGINT

# Excluir pasta csv_dir se já existir
if [ -d "$CSV_DIR" ]; then
    echo "Excluindo pasta $CSV_DIR"
    rm -rf "$CSV_DIR"
fi

# Criar pasta csv_dir
echo "Criando pasta $CSV_DIR"
mkdir "$CSV_DIR"

# Contador para nomeação sequencial dos arquivos
i=0
# Definir variáveis de controle de tempo
start_time=$(date +"%Y-%m-%d %H:%M:%S")
total_time=0

# Loop pelos arquivos zip
for zip_file in "${zip_files[@]}"; do
    # Descompactar o arquivo zip e renomear os arquivos resultantes
    echo -e "Começando a descompactar o arquivo $zip_file."
    unzip_output=$(unzip -q "$zip_file" -d "$CSV_DIR" 2>&1)
    unzip_exit_code=$?
    
    if [ $unzip_exit_code -eq 0 ]; then
        csv_files=("$CSV_DIR"/*.ESTABELE)
        
        for csv_file in "${csv_files[@]}"; do
            if [ -f "$csv_file" ]; then
                # Adicionar permissão de leitura e escrita ao arquivo, se necessário
                chmod +rw "$csv_file"
                
                new_filename="$CSV_DIR/$i.csv"
                mv -f "$csv_file" "$new_filename"
                i=$((i+1))
            fi
        done
        
        unzip_time=$(echo "$unzip_output" | awk '/in / {print $2}')
        echo -e "Arquivo $zip_file descompactado com sucesso em $unzip_time.\n"
    elif [ $unzip_exit_code -eq 9 ]; then
        echo -e "\nErro ao abrir o arquivo $zip_file: O arquivo está corrompido.\n"
    elif [ $unzip_exit_code -eq 1 ]; then
        echo -e "\nErro ao abrir o arquivo $zip_file: Permissão negada para ler o arquivo.\n"
        ls -l "$zip_file"
    else
        echo -e "\nErro ao abrir o arquivo $zip_file: Código de saída $unzip_exit_code.\n"
    fi
done

echo -e "Todos os arquivos zip foram descompactados e renomeados para nomes sequenciais.\nForam renomeados um total de $i arquivos."
# Calcular o tempo total gasto em horas, minutos e segundos
total_hours=$((total_time / 3600))
total_minutes=$((total_time % 3600 / 60))
total_seconds=$((total_time % 60))

# Imprimir o tempo total gasto
end_time=$(date +"%Y-%m-%d %H:%M:%S")
echo -e "Tempo total gasto: ${total_hours}h ${total_minutes}m ${total_seconds}s"
echo -e "Começou em: ${start_time}"
echo -e "Terminou em: ${end_time}"