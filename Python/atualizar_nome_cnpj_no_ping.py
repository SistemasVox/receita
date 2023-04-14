# Importação da biblioteca httpx para realizar requisições HTTP
import httpx 

# Importação da biblioteca BeautifulSoup para fazer o parseamento de HTML e XML
from bs4 import BeautifulSoup 

# Importação da biblioteca mysql.connector para se conectar e manipular banco de dados MySQL
import mysql.connector 

# Importação da biblioteca random para gerar números aleatórios
import random 

# Importação da biblioteca time para lidar com funções relacionadas ao tempo
import time 

# Importação da biblioteca ping3 para fazer ping em endereços IP
import ping3 

# Importação da biblioteca os para lidar com funções relacionadas ao sistema operacional
import os 

# Importação da biblioteca platform para lidar com informações do sistema operacional em que o código está sendo executado
import platform 

# Importação da biblioteca requests para realizar requisições HTTP
import requests 

# Importação da biblioteca datetime para lidar com funções relacionadas a data e hora
import datetime 

# Importação da biblioteca re para lidar com expressões regulares
import re


# Obtém o nome do sistema operacional atual.
operating_system = platform.system()

# Verifica se o sistema operacional é Windows.
if operating_system == "Windows":
    # Se for Windows, usa o comando "cls" para limpar a tela.
    os.system("cls")
else:
    # Caso contrário, usa o comando "clear".
    os.system("clear")

# Verifica se existe um arquivo chamado 'atualizacoes.sql' no diretório atual.
if os.path.exists('atualizacoes.sql'):
    # Se o arquivo existir, usa o comando "os.remove" para excluí-lo.
    os.remove('atualizacoes.sql')


def get_cnpjs():
    try:
        # Faz a conexão com o banco de dados usando as credenciais fornecidas.
        db = mysql.connector.connect(
            host="127.0.0.1", user="marcelo", password="xxx", database="empresas"
        )
        
        # Cria um objeto cursor para executar comandos SQL no banco de dados.
        cursor = db.cursor()
        
        # Executa a consulta SQL para obter os CNPJs de empresas que não possuem nome.
        cursor.execute("SELECT cnpj FROM empresas WHERE nome IS NULL OR nome = '';")
        
        # Recupera os resultados da consulta e armazena os CNPJs em uma lista.
        cnpjs = [row[0] for row in cursor.fetchall()]
        
        # Fecha a conexão com o banco de dados.
        db.close()
        
        # Retorna a lista de CNPJs.
        return cnpjs
    
    # Se ocorrer um erro durante a conexão com o banco de dados, imprime uma mensagem de erro.
    except mysql.connector.Error as error:
        print("Erro ao conectar ao banco de dados:", error)
        return []

def update_nome_cnpj(cnpj, nome):
    try:
        # Verifica se o nome tem mais de 1 caracter.
        if len(nome) > 1:
            # Remove espaços em branco extras e substitui sequências de espaços por um único espaço.
            nome = re.sub(r'\s+', ' ', nome).strip()
            
            # Cria uma string de consulta SQL para atualizar o nome da empresa com o CNPJ fornecido.
            query = "UPDATE empresas SET nome = '{}' WHERE cnpj = '{}';\n".format(
                nome, cnpj
            )
            
            # Abre o arquivo 'atualizacoes.sql' em modo de adição e escreve a consulta SQL nele.
            with open("atualizacoes.sql", "a") as arquivo:
                arquivo.write(query)

            # Retorna uma mensagem de sucesso.
            return "Instrução de atualização salva com sucesso no arquivo atualizacoes.sql."

    # Se ocorrer um erro, retorna uma mensagem de erro.
    except Exception as e:
        return "Erro ao salvar instrução de atualização: {}".format(e)

def get_nome_cnpj(cnpj):
    # Endereço do host do website.
    host = "xxx.com.br"
    
    try:
        # Monta a URL de consulta do CNPJ.
        url = f"https://{host}/solucao/cnpj?q={cnpj}"
        print(url)
        
        # Define o cabeçalho da requisição HTTP.
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
        }
        
        # Define o número de tentativas para obter a resposta HTTP.
        attempts = 3
        for i in range(attempts):
            try:
                # Faz a requisição HTTP para obter a resposta HTML.
                response = requests.get(url, headers=headers, timeout=30)
                
                # Verifica se a resposta é bem-sucedida.
                response.raise_for_status()
                
                # Faz o parsing do HTML e encontra as tags "strong".
                soup = BeautifulSoup(response.content, "html.parser")
                strong_tags = soup.find_all("strong")
                
                # Verifica se há pelo menos duas tags "strong" para pegar o nome da empresa.
                if len(strong_tags) >= 2:
                    nome = strong_tags[1].text.strip()
                else:
                    nome = ""
                return nome
            
            # Trata os erros HTTP.
            except requests.exceptions.HTTPError as error:
                print(f"Tentativa {i+1}/{attempts} falhou: {error}")
                if i == attempts - 1:
                    raise
                else:
                    print(f"Tentando novamente em 5 segundos...")
                    time.sleep(5)
                    
            # Trata os erros de conexão.
            except requests.exceptions.ConnectionError as error:
                print(f"Erro de conexão: {error}")
                time.sleep(5)
                
            # Trata os erros de tempo limite.
            except requests.exceptions.Timeout as error:
                print(f"Tempo limite atingido: {error}")
                time.sleep(5)
                
            # Trata os erros de rede.
            except requests.exceptions.RequestException as error:
                print(f"Erro de rede: {error}")
                time.sleep(5)
                
    # Trata os erros gerais.
    except (
        requests.exceptions.HTTPError,
        requests.exceptions.ConnectionError,
        requests.exceptions.Timeout,
        requests.exceptions.RequestException,
    ) as error:
        print(f"Erro ao obter arquivo HTML para CNPJ {cnpj}: {error}")
        return ""

def format_timedelta(td):
    # Extrai a quantidade de dias da duração
    days = td.days
    
    # Extrai a quantidade de horas e minutos restantes da duração, e converte para string formatada
    hours, r = divmod(td.seconds, 3600)
    minutes, seconds = divmod(r, 60)
    
    # Retorna a string formatada com a duração completa
    return f"{days} dias, {hours:02d}:{minutes:02d}:{seconds:02d}"


# função para atualizar nomes de CNPJ
def update_cnpj_names():

    delay_min = 0 # define o atraso mínimo
    delay_max = 0 # define o atraso máximo

    cnpjs = get_cnpjs() # obtém uma lista de CNPJs
    random.shuffle(cnpjs) # embaralha a lista de CNPJs
    total = len(cnpjs) # obtém o número total de CNPJs
    segundos = 10  # atualiza tempo_medio a cada 10 segundos
    tempo_medio = 0  # inicialmente, consideramos 0 segundos por CNPJ
    cnpj_times = [] # lista para guardar os timestamps de cada CNPJ processado
    start_time = time.time() # obtém o tempo de início do processamento
    last_update_time = start_time # define o tempo da última atualização como o tempo de início

    # loop através de cada CNPJ
    for i, cnpj in enumerate(cnpjs):

        delay = random.uniform(delay_min, delay_max) # define um atraso aleatório
        time.sleep(delay) # aguarda um tempo antes de prosseguir

        nome = get_nome_cnpj(cnpj) # obtém o nome associado ao CNPJ

        # se o nome existir
        if nome:
            update_nome_cnpj(cnpj, nome) # atualiza o nome associado ao CNPJ
            now = datetime.datetime.now() # obtém o timestamp atual
            cnpj_times.append(now.timestamp()) # adiciona o timestamp na lista de timestamps
            progress = (i+1)/total*100 # calcula a porcentagem de conclusão
            tempo_restante = datetime.timedelta(seconds=(total-i-1) * tempo_medio) # calcula o tempo restante estimado
            conclusao = datetime.datetime.now() + tempo_restante # calcula a hora de conclusão estimada
            # imprime informações sobre a atualização
            print(
                f"Atualizando...\nCNPJ: {cnpj}\nNome: {nome}.\nProgresso: ({i+1}/{total}).\nPorcentagem: {progress:.2f}% concluído.\nTempo restante estimado: {format_timedelta(tempo_restante)}\nHora de conclusão estimada: {conclusao.strftime('%Y-%m-%d %H:%M:%S')}\n"
            )

        # se o nome não existir
        else:
            now = datetime.datetime.now() # obtém o timestamp atual
            cnpj_times.append(now.timestamp()) # adiciona o timestamp na lista de timestamps
            progress = (i+1)/total*100 # calcula a porcentagem de conclusão
            tempo_restante = datetime.timedelta(seconds=(total-i-1) * tempo_medio) # calcula o tempo restante estimado
            conclusao = datetime.datetime.now() + tempo_restante # calcula a hora de conclusão estimada
            # imprime informações sobre a falha na atualização
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
