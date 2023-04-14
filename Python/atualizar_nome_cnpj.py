import subprocess

libraries = ['httpx', 'beautifulsoup4', 'mysql-connector-python', 'random', 'ping3', 'requests']

for lib in libraries:
    try:
        importlib.import_module(lib)
    except ImportError:
        subprocess.check_call(['pip', 'install', lib])


import httpx
from bs4 import BeautifulSoup
import mysql.connector
import random
import time
import ping3
import os
import platform
import requests

operating_system = platform.system()
if operating_system == "Windows":
    os.system("cls")
else:
    os.system("clear")


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
        db = mysql.connector.connect(
            host="127.0.0.1", user="marcelo", password="xxx", database="empresas"
        )
        cursor = db.cursor()
        query = "UPDATE empresas SET nome = %s WHERE cnpj = %s"
        values = (nome, cnpj)
        cursor.execute(query, values)
        db.commit()
        db.close()
    except mysql.connector.Error as error:
        print("Erro ao atualizar nome do CNPJ", cnpj, "no banco de dados:", error)


def ping(host):
    for i in range(3):
        try:
            response = ping3.ping(host)
            if response is not None:
                print(f"{host} está online.")
                return True
            else:
                print(f"{host} está offline.")
                return False
        except ping3.exceptions.TimeoutException:
            print(
                f"Tentativa {i+1}/3 de ping falhou. Tentando novamente em 5 segundos..."
            )
            time.sleep(5)
    print(f"Todas as tentativas de ping falharam para {host}.")
    return False


def get_nome_cnpj(cnpj):
    host = "xxx.com.br"
    if ping(host):
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
                    nome = strong_tags[1].text.strip()
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
    else:
        print(f"{host} está offline. Não foi possível obter o nome do CNPJ.")
        return ""


def update_cnpj_names():
    delay_min = 1
    delay_max = 9
    cnpjs = get_cnpjs()
    random.shuffle(cnpjs)
    total = len(cnpjs)
    for i, cnpj in enumerate(cnpjs):
        delay = random.uniform(delay_min, delay_max)
        time.sleep(delay)
        nome = get_nome_cnpj(cnpj)
        if nome:
            update_nome_cnpj(cnpj, nome)
            now = datetime.datetime.now().strftime("%H:%M:%S")
            print(
                f"Atualizando CNPJ {cnpj} - Nome: {nome} ({i+1}/{total}) - {(i+1)/total*100:.2f}% concluído. Hora de conclusão: {now}\n"
            )
        else:
            now = datetime.datetime.now().strftime("%H:%M:%S")
            print(
                f"Falha ao atualizar CNPJ {cnpj} ({i+1}/{total}) - {(i+1)/total*100:.2f}% concluído.\n Hora de conclusão: {now}\n"
            )


update_cnpj_names()
