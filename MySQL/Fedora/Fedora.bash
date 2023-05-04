# Definir a zona de tempo para Buenos Aires
sudo timedatectl set-timezone America/Argentina/Buenos_Aires

# Definir a zona de tempo para São Paulo
sudo timedatectl set-timezone America/Sao_Paulo

# Verificar a configuração atual da zona de tempo
sudo timedatectl

# Listar as portas em uso pelo sistema
sudo netstat -tulpn

# Acessar o diretório de configuração do grub
cd /etc/default/

# Editar o arquivo de configuração do grub
sudo vim grub

# Definir o tempo de boot do grub para 0 segundos
GRUB_TIMEOUT=0

# Gerar a configuração atualizada do grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Instalar o servidor web Apache
sudo dnf install httpd

# Habilitar o serviço do Apache para iniciar automaticamente na inicialização do sistema
sudo systemctl enable httpd.service

# Iniciar o serviço do Apache
sudo systemctl start httpd.service

# Instalar o servidor de banco de dados MariaDB e o cliente
sudo dnf install mariadb mariadb-server

# Habilitar o serviço do MariaDB para iniciar automaticamente na inicialização do sistema
sudo systemctl enable mariadb.service

# Iniciar o serviço do MariaDB
sudo systemctl start mariadb.service

# Instalar o interpretador Python 3 e o gerenciador de pacotes pip
sudo dnf install python3 python3-pip

# Instalar a biblioteca Requests do Python
pip3 install requests

# Instalar o PHPMyAdmin para gerenciamento do banco de dados
sudo dnf install phpMyAdmin

# Editar o arquivo de configuração do PHPMyAdmin para permitir conexões externas
sudo vim /etc/httpd/conf.d/phpMyAdmin.conf

# Editar o arquivo de configuração do Apache
sudo vim /etc/httpd/conf/httpd.conf

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
# Reiniciar o serviço do Apache
sudo systemctl restart httpd.service

# Listar as portas abertas no firewall
sudo firewall-cmd --list-ports

# Listar todas as configurações do firewall
sudo firewall-cmd --list-all

# Permitir o tráfego HTTP e HTTPS no firewall
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload

# Permitir o tráfego do MariaDB no firewall
sudo firewall-cmd --add-port=3306/tcp --permanent
sudo firewall-cmd --reload

# Permitir o tráfego do PostgreSQL no firewall
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload

# Verificar as permissões do diretório do PHPMyAdmin
ls -l /usr/share/phpMyAdmin/

# Conceder permissões de leitura e execução para o diretório do PHPMyAdmin
sudo chmod 755 /usr/share/phpMyAdmin/

# Editar o arquivo de configuração do PHPMyAdmin
sudo vim /etc/httpd/conf.d/phpMyAdmin.conf
Alias /phpMyAdmin /usr/share/phpMyAdmin
<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8
   Require all granted
</Directory>
# Reiniciar o serviço do Apache
sudo systemctl restart httpd.service

# Editar o arquivo de configuração do MariaDB
sudo nano /etc/my.cnf

# Adicionar as seguintes linhas ao arquivo para permitir conexões externas e definir a zona de tempo
[mysqld]
bind-address = 0.0.0.0
local_infile = ON
default-time-zone='-03:00'
# Configurações de memória
innodb_buffer_pool_size = 4G
innodb_log_file_size = 1G

# Reiniciar o serviço do MariaDB
sudo systemctl restart mariadb.service

# Acessar o shell do MariaDB
sudo mysql -u root -p

# Criar um usuário com todos os privilégios e permitir conexões externas
CREATE USER 'marcelo'@'%' IDENTIFIED BY 'q1w2';
GRANT ALL ON *.* TO 'marcelo'@'%';
FLUSH PRIVILEGES;

# Definir a zona de tempo do MariaDB
SET GLOBAL time_zone = '-03:00';

# Reiniciar o serviço do MariaDB
sudo systemctl restart mariadb
