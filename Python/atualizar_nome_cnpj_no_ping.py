import httpx
from bs4 import BeautifulSoup
import mysql.connector
import random
import time
import ping3
import os
import platform
import requests
import datetime
import re

operating_system = platform.system()
if operating_system == "Windows":
    os.system("cls")
else:
    os.system("clear")
    
if os.path.exists('atualizacoes.sql'):
    os.remove('atualizacoes.sql')


def get_cnpjs():
    try:
        db = mysql.connector.connect(
            host="127.0.0.1", user="marcelo", password="xxx", database="empresas"
        )
        cursor = db.cursor()
        cursor.execute("SELECT cnpj FROM empresas WHERE nome IS NULL OR nome = '';")
        cnpjs = [row[0] for row in cursor.fetchall()]
        db.close()
        return cnpjs
    except mysql.connector.Error as error:
        print("Erro ao conectar ao banco de dados:", error)
        return []

def update_nome_cnpj(cnpj, nome):
    try:
        if len(nome) > 1:
            nome = re.sub(r'\s+', ' ', nome).strip()
            query = "UPDATE empresas SET nome = '{}' WHERE cnpj = '{}';\n".format(
                nome, cnpj
            )
            with open("atualizacoes.sql", "a") as arquivo:
                arquivo.write(query)

            return "Instrução de atualização salva com sucesso no arquivo atualizacoes.sql."

    except Exception as e:
        return "Erro ao salvar instrução de atualização: {}".format(e)

def get_nome_cnpj(cnpj):
    host = "xxx.com.br"
    try:
        url = f"https://{host}/solucao/cnpj?q={cnpj}"
        print(url)
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
        }
        attempts = 3
        for i in range(attempts):
            try:
                response = requests.get(url, headers=headers, timeout=30)
                response.raise_for_status()
                soup = BeautifulSoup(response.content, "html.parser")
                strong_tags = soup.find_all("strong")
                if len(strong_tags) >= 2:
                    nome = strong_tags[1].text.strip()
                else:
                    nome = ""
                return nome
            except requests.exceptions.HTTPError as error:
                print(f"Tentativa {i+1}/{attempts} falhou: {error}")
                if i == attempts - 1:
                    raise
                else:
                    print(f"Tentando novamente em 5 segundos...")
                    time.sleep(5)
            except requests.exceptions.ConnectionError as error:
                print(f"Erro de conexão: {error}")
                time.sleep(5)
            except requests.exceptions.Timeout as error:
                print(f"Tempo limite atingido: {error}")
                time.sleep(5)
            except requests.exceptions.RequestException as error:
                print(f"Erro de rede: {error}")
                time.sleep(5)
    except (
        requests.exceptions.HTTPError,
        requests.exceptions.ConnectionError,
        requests.exceptions.Timeout,
        requests.exceptions.RequestException,
    ) as error:
        print(f"Erro ao obter arquivo HTML para CNPJ {cnpj}: {error}")
        return ""

def format_timedelta(td):
    days = td.days
    hours, r = divmod(td.seconds, 3600)
    minutes, seconds = divmod(r, 60)
    return f"{days} dias, {hours:02d}:{minutes:02d}:{seconds:02d}"

def update_cnpj_names():
    delay_min = 0
    delay_max = 0
    cnpjs = get_cnpjs()
    random.shuffle(cnpjs)
    total = len(cnpjs)
    segundos = 10  # atualiza tempo_medio a cada 10 segundos
    tempo_medio = 0  # inicialmente, consideramos 0 segundos por CNPJ
    cnpj_times = []
    start_time = time.time()
    last_update_time = start_time
    for i, cnpj in enumerate(cnpjs):
        delay = random.uniform(delay_min, delay_max)
        time.sleep(delay)
        nome = get_nome_cnpj(cnpj)
        if nome:
            update_nome_cnpj(cnpj, nome)
            now = datetime.datetime.now()
            cnpj_times.append(now.timestamp())
            progress = (i+1)/total*100
            tempo_restante = datetime.timedelta(seconds=(total-i-1) * tempo_medio)
            conclusao = datetime.datetime.now() + tempo_restante
            print(
                f"Atualizando...\nCNPJ: {cnpj}\nNome: {nome}.\nProgresso: ({i+1}/{total}).\nPorcentagem: {progress:.2f}% concluído.\nTempo restante estimado: {format_timedelta(tempo_restante)}\nHora de conclusão estimada: {conclusao.strftime('%Y-%m-%d %H:%M:%S')}\n"
            )
        else:
            now = datetime.datetime.now()
            cnpj_times.append(now.timestamp())
            progress = (i+1)/total*100
            tempo_restante = datetime.timedelta(seconds=(total-i-1) * tempo_medio)
            conclusao = datetime.datetime.now() + tempo_restante
            print(
                f"<<<FALHA AO ATUALIZAR>>>\nCNPJ: {cnpj}\nNome: {nome}.\nProgresso: ({i+1}/{total}).\nPorcentagem: {progress:.2f}% concluído.\nTempo restante estimado: {format_timedelta(tempo_restante)}\nHora de conclusão estimada: {conclusao.strftime('%Y-%m-%d %H:%M:%S')}\n"
            )

        # atualiza tempo_medio a cada 10 segundos
        current_time = time.time()
        if current_time - last_update_time >= segundos:
            elapsed_time = current_time - start_time
            num_cnpjs_processed = i + 1
            tempo_medio = elapsed_time / num_cnpjs_processed
            last_update_time = current_time

    print("Atualização concluída.")
    
update_cnpj_names()
