--Criação de INDEX's
CREATE INDEX idx_cnae_principal ON empresas (cnae_principal);
CREATE FULLTEXT INDEX idx_cnae_secundaria ON empresas (cnae_secundaria);
CREATE INDEX idx_cnpj ON empresas (cnpj, ordem_cnpj, dv_cnpj);
CREATE FULLTEXT INDEX idx_nome ON empresas (nome);
CREATE INDEX idx_situacao_cadastral ON empresas (situacao, data_situacao, motivo_situacao);
CREATE INDEX idx_endereco ON empresas (tipo_logradouro, logradouro, numero, bairro, cep, uf, municipio);

-- Velhos
CREATE INDEX idx_nome ON empresas (nome);
CREATE INDEX idx_cnpj ON empresas (cnpj, ordem_cnpj, dv_cnpj);
CREATE INDEX idx_cnae ON empresas (cnae_principal, cnae_secundaria);
CREATE INDEX idx_endereco ON empresas (tipo_logradouro, logradouro ,numero, complemento, bairro, cep, uf, municipio);
CREATE INDEX idx_situacao_cadastral ON empresas (situacao, data_situacao, motivo_situacao);
CREATE INDEX idx_situacao_data_abertura ON empresas (data_inicio);

-- Login para acesso ao MySQL
mysql -u root -p

-- Configurações Iniciais do MySQL

-- Reiniciar o serviço do MySQL
sudo systemctl restart mysql

-- Manipulação do arquivo de configuração do MySQL
sudo nano /etc/mysql/my.cnf
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
sudo nano /etc/my.cnf

-- Exibição de variáveis do MySQL relacionadas a buffer e thread
SHOW VARIABLES LIKE '%buffer%';
SHOW VARIABLES LIKE '%thread%';

-- Configurações para o disco do MySQL
SHOW VARIABLES LIKE 'innodb_io_capacity'; -- exibe a capacidade de I/O do InnoDB
SET GLOBAL innodb_io_capacity = 2000; -- define a capacidade de I/O do InnoDB para 2000

-- Configurações para o buffer pool do MySQL
SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4 * 1.073.741.824 é em bytes.
-- # aumentando o tamanho do buffer pool
innodb_buffer_pool_size = 8G

-- # habilitando o log binário
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 10
max_binlog_size = 100M

-- Configurações para o número de CPUs do MySQL
   innodb_thread_concurrency = 16

-- Configurações para o buffer de registro do MySQL
innodb_log_buffer_size = 256M -- define o tamanho do buffer de registro do InnoDB como 256MB

-- Configurações para o cache de consulta do MySQL
query_cache_size = 512M -- define o tamanho do cache de consulta como 512MB