import requests
from bs4 import BeautifulSoup
import mysql.connector
import random
import time
import ping3


# Define o CNPJ a ser consultado
cnpj = "30139980000179"

# Define o cabeçalho para a solicitação HTTP
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
}

# Envia a solicitação GET e extrai o HTML da página
try:
    response = requests.get(
        f"https://xxx.com.br/solucao/cnpj?q={cnpj}", headers=headers
    )
    response.raise_for_status()  # Verifica se ocorreu algum erro na solicitação HTTP
    html = response.text
except requests.exceptions.RequestException:
    raise ValueError("Erro: Não foi possível obter a página HTML.")

# Verifica se o conteúdo retornado é um arquivo HTML
if not any(tag in html.lower() for tag in ["<html", "</html>"]):
    raise ValueError("Erro: Não foi possível obter um arquivo HTML válido.")

# Verifica se o elemento <strong> existe no HTML
if not any(tag in html.lower() for tag in ["<strong"]):
    raise ValueError(
        "Erro: Não foi possível encontrar o elemento <strong> no arquivo HTML."
    )

# Extrai o nome da empresa do HTML
soup = BeautifulSoup(html, "html.parser")
strong_tags = soup.find_all("strong")
if len(strong_tags) < 2:
    raise ValueError(
        "Erro: Não foi possível extrair o nome da empresa do arquivo HTML."
    )
nome = strong_tags[1].text.strip()

# Exibe o resultado na tela
print(f"O nome da empresa com CNPJ {cnpj} é: {nome}")
