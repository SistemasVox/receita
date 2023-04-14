#!/bin/bash# Este script verifica se há novas datas disponíveis para download de um site e, se houver,# executa um script para atualizar os dados. As datas são armazenadas em um arquivo chamado # datas.txt para que possam ser comparadas posteriormente com as novas datas. Se houver diferenças,# o script atualiza o arquivo datas.txt com as novas datas.# Cria o arquivo datas.txt caso ele não existaif [ ! -e datas.txt ]; then    echo "O arquivo datas.txt não existe. Criando novo arquivo vazio."    touch datas.txtfi# Obtém as datas dos estabelecimentoscurl -s https://dadosabertos.rfb.gov.br/CNPJ/ | grep -Po 'Estabelecimentos.*?\K\d{4}-\d{2}-\d{2}' | sort | uniq > novas_datas.txt# Compara as novas datas com as armazenadas no arquivo datas.txtif ! cmp -s novas_datas.txt datas.txt; then    # As datas são diferentes, executa o script att.sh    echo -e "\nAs datas dos estabelecimentos foram atualizadas. Executando o script att.sh..."    ./att.sh    # Substitui o arquivo datas.txt pelas novas datas    mv novas_datas.txt datas.txt    echo -e "\nArquivo datas.txt atualizado."else    echo -e "\nNão foi necessário atualizar pois as datas são as mesmas."fi# Obtém as datas dos estabelecimentos e as compara com as do arquivo datas.txttemp_file=$(mktemp) # cria um arquivo temporáriocurl -s https://dadosabertos.rfb.gov.br/CNPJ/ | grep -Po 'Estabelecimentos.*?\K\d{4}-\d{2}-\d{2}' > "$temp_file" # salva as datas em um arquivo temporárioif ! cmp -s "$temp_file" datas.txt; then    # As datas são diferentes, executa o script att.sh    echo -e "\nAs datas dos estabelecimentos foram atualizadas. Executando o script att.sh..."    ./att.sh    # Substitui o arquivo datas.txt pelas novas datas    mv "$temp_file" datas.txt    echo -e "\nArquivo datas.txt atualizado."else    echo -e "\nNão foi necessário atualizar pois as datas são as mesmas."firm "$temp_file" # remove o arquivo temporário