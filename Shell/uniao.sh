#!/bin/bash

# Define o caminho para a pasta CSV
CSV_PATH="${PWD}/csv"

# Define o nome do arquivo de saída
OUTPUT_FILE="uniao.csv"

# Remove arquivos temporários
rm -f "${CSV_PATH}"/*.tmp

# Verifica se há espaço suficiente em disco
AVAILABLE_SPACE=$(df -BG "${CSV_PATH}" | awk 'NR==2{print $4}')
if [ "${AVAILABLE_SPACE%G}" -lt 100 ]; then
    echo "Erro: espaço insuficiente em disco (${AVAILABLE_SPACE}). O processo foi interrompido."
    exit 1
fi

# Junta os arquivos CSV em um arquivo de saída
cat "${CSV_PATH}"/*.csv > "${CSV_PATH}/${OUTPUT_FILE}"

# Remove linhas em branco do arquivo de saída
sed -i '/^$/d' "${CSV_PATH}/${OUTPUT_FILE}"
