-- ÍNDICES --
CREATE INDEX idx_nome ON empresas (nome);
CREATE INDEX idx_cnpj ON empresas (cnpj, ordem_cnpj, dv_cnpj);
CREATE INDEX idx_cnae ON empresas (cnae_principal, cnae_secundaria);
CREATE INDEX idx_endereco ON empresas (tipo_logradouro, logradouro ,numero, complemento, bairro, cep, uf, municipio);
CREATE INDEX idx_situacao_cadastral ON empresas (situacao, data_situacao, motivo_situacao);
CREATE INDEX idx_situacao_data_abertura ON empresas (data_inicio);


-- Excluir todos...
ALTER TABLE empresas DROP INDEX;
ALTER TABLE nome_da_tabela DROP INDEX idx_nome_do_indice1, DROP INDEX idx_nome_do_indice2, ...;
-- ---------------------------------------------------------------------------------------------------

-- CONSULTAS SQL para a tabela "empresas"
-- Contar o número de registros que têm CNPJ nulo ou vazio
SELECT COUNT(*) FROM empresas WHERE cnpj IS NULL OR cnpj LIKE '';
-- Contar o número de registros que têm nome nulo ou vazio
SELECT REPLACE(FORMAT(COUNT(*), 0), ',', '.') as nome_vazio FROM empresas WHERE nome IS NULL OR nome LIKE ''

-- Seleciona o CNPJ completo concatenando as colunas cnpj, ordem_cnpj e dv_cnpj em uma única string.
SELECT CONCAT(cnpj, ordem_cnpj, dv_cnpj) as cnpj_completo FROM empresas;
-- Seleciona o CNPJ formatado concatenando as substrings do CNPJ original e adicionando os caracteres especiais de formatação (/ e -).
SELECT CONCAT(SUBSTR(cnpj, 1, 2), '.', SUBSTR(cnpj, 3, 3), '.', SUBSTR(cnpj, 6, 3), '', SUBSTR(cnpj, 9, 4), '/', ordem_cnpj, '-', dv_cnpj) AS cnpj_formatado FROM empresas LIMIT 10;
--  obter a quantidade de CEPs sem repetição 
SELECT COUNT(DISTINCT cep) AS qtd_ceps FROM empresas;


-- -------------------------------------------------------------------------------------------------------------------------------------------
-- VIEW's
CREATE VIEW vw_cnpj AS
-- cria uma VIEW chamada vw_cnpj que irá formatar o CNPJ a partir das colunas cnpj, ordem_cnpj e dv_cnpj da tabela empresas
SELECT CONCAT(
  -- concatena o primeiro bloco do CNPJ, que são os dois primeiros dígitos, separados por ponto (.)
  SUBSTR(cnpj, 1, 2), '.', 
  -- concatena o segundo bloco do CNPJ, que são os três dígitos seguintes, separados por ponto (.)
  SUBSTR(cnpj, 3, 3), '.', 
  -- concatena o terceiro bloco do CNPJ, que são os três dígitos seguintes, separados por ponto (.)
  SUBSTR(cnpj, 6, 3), '', 
  -- concatena o quarto bloco do CNPJ, que são os quatro últimos dígitos, separados por barra (/)
  SUBSTR(cnpj, 9, 4), '/', 
  -- concatena a ordem do CNPJ, que são os quatro primeiros dígitos da coluna ordem_cnpj, separados por hífen (-)
  ordem_cnpj, '-', 
  -- concatena o dígito verificador do CNPJ, que são os dois primeiros dígitos da coluna dv_cnpj
  dv_cnpj
) AS cnpj_formatado
FROM empresas;


-- Este comando seleciona a visualização (view) "vw_cnpj" que contém os CNPJs formatados das empresas.
SELECT * FROM vw_cnpj;
-- Este comando renomeia a visualização (view) "nome_atual" para "vw_empresas_cnpj".
RENAME VIEW nome_atual TO vw_empresas_cnpj;

-- Cria uma view chamada vw_cnpj_numeros que retorna o número completo do CNPJ (incluindo ordem e dígito verificador)
-- a partir dos campos cnpj, ordem_cnpj e dv_cnpj da tabela empresas.
CREATE VIEW vw_cnpj_numeros AS
SELECT CONCAT(cnpj, ordem_cnpj, dv_cnpj) as cnpj_numeros FROM empresas;

-- Criação de view parametrizada para retornar CNPJ formatado de empresas que possuem um nome específico
CREATE VIEW vw_empresas_cnpj_por_nome AS
SELECT CONCAT(SUBSTR(cnpj, 1, 2), '.', SUBSTR(cnpj, 3, 3), '.', SUBSTR(cnpj, 6, 3), '', SUBSTR(cnpj, 9, 4), '/', ordem_cnpj, '-', dv_cnpj) AS cnpj_formatado
FROM empresas
WHERE nome = ?; -- Parâmetro para filtrar empresas pelo nome

-- Exemplo de uso da view parametrizada para buscar o CNPJ formatado de uma empresa específica
SELECT * FROM vw_empresas_cnpj_por_nome WHERE nome = 'Minha Empresa';


-- Cria uma view que formata o CNPJ das empresas, além de selecionar outras informações como nome, CNAE principal e situação, permitindo filtrar por esses campos.
CREATE VIEW vw_empresas_cnpj AS
SELECT CONCAT(SUBSTR(cnpj, 1, 2), '.', SUBSTR(cnpj, 3, 3), '.', SUBSTR(cnpj, 6, 3), '', SUBSTR(cnpj, 9, 4), '/', ordem_cnpj, '-', dv_cnpj)as cnpj_formatado, nome, cnae_principal, situacao FROM empresas
WHERE (:nome IS NULL OR nome LIKE CONCAT('%', :nome, '%'))
AND (:cnae_principal IS NULL OR cnae_principal = :cnae_principal)
AND (:situacao IS NULL OR situacao = :situacao)
ORDER BY cnpj_formatado ASC;
-- Seleciona as empresas que possuem "Apple" no nome e CNAE principal igual a "6201-5/00" na view criada anteriormente.
SELECT * FROM vw_empresas_cnpj WHERE nome LIKE '%Apple%' AND cnae_principal = '6201-5/00';


-- FUNÇÕES:
-- Essa função recebe o código do município como uma string e retorna o nome do município correspondente. Caso o código seja inválido, a função retorna a mensagem "Valor inválido".
DELIMITER $$
DROP FUNCTION IF EXISTS get_nome_municipio $$
CREATE FUNCTION get_nome_municipio (cod_muni VARCHAR(255))
RETURNS VARCHAR(255)
BEGIN
  DECLARE municipio_nome VARCHAR(255);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22007' SET municipio_nome = 'Valor inválido';
  SET cod_muni = CAST(cod_muni AS UNSIGNED);
  SELECT nome INTO municipio_nome FROM municipios WHERE cod = cod_muni;
  RETURN municipio_nome;
END $$
DELIMITER ;

-- Função que recebe parte de um nome de município e retorna o código do primeiro município encontrado que contém essa parte no nome. Se nenhum município for encontrado, a função retorna 0.
DELIMITER $$
DROP FUNCTION IF EXISTS get_cod_municipio $$
CREATE FUNCTION get_cod_municipio (parte_nome VARCHAR(255))
RETURNS INT(11)
BEGIN
  DECLARE cod_municipio INT(11);
  SELECT cod INTO cod_municipio FROM municipios WHERE nome LIKE CONCAT('%', parte_nome, '%') LIMIT 1;
  IF (cod_municipio IS NULL) THEN
    SET cod_municipio = 0;
  END IF;
  -- RETURN IFNULL(cod_municipio, 0);
  RETURN cod_municipio;
END $$
DELIMITER ;

/* Essa função é chamada "get_descricao_cnae". Ela recebe um parâmetro "cod_cnae" do tipo VARCHAR(255) que é convertido para inteiro (UNSIGNED) através da função CAST(). Em seguida, é declarada uma variável "cnae_descricao" do tipo VARCHAR(255) que será utilizada para armazenar a descrição do CNAE correspondente ao código informado.

Caso o código informado não exista na tabela "cnae", o código retorna a mensagem "Código não encontrado". Para tratar a exceção, é declarado um manipulador de exceções que é ativado quando ocorre um erro ao converter o código informado para inteiro (SQLSTATE '22007').

Por fim, é feita uma consulta na tabela "cnae" buscando a descrição do CNAE correspondente ao código informado e o resultado é armazenado na variável "cnae_descricao". Essa descrição é retornada como resultado da função. */

DELIMITER $$
DROP FUNCTION IF EXISTS get_descricao_cnae $$
CREATE FUNCTION get_descricao_cnae (cod_cnae VARCHAR(255))
RETURNS VARCHAR(255)
BEGIN
  DECLARE cnae_descricao VARCHAR(255);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22007' SET cnae_descricao = 'Valor inválido';
  SET cod_cnae = CAST(cod_cnae AS UNSIGNED);
  SELECT descricao INTO cnae_descricao FROM cnae WHERE cod = cod_cnae;
  IF cnae_descricao IS NULL THEN
    SET cnae_descricao = 'Código não encontrado';
  END IF;
  RETURN cnae_descricao;
END $$
DELIMITER ;

-- Essa função chamada get_descricao_cnae recebe como parâmetro um código de CNAE no formato string e retorna a descrição correspondente na tabela cnae. Se o código fornecido for inválido, a função retorna a string "Valor inválido". Se o código não for encontrado na tabela, a função retorna a string "Código não encontrado". A função utiliza um manipulador de exceção para lidar com valores inválidos, converte o parâmetro para inteiro e faz uma consulta na tabela cnae.
DELIMITER $$
DROP FUNCTION IF EXISTS get_descricao_motivo $$
CREATE FUNCTION get_descricao_motivo (cod_motivo INT(11))
RETURNS VARCHAR(255)
BEGIN
  DECLARE motivo_descricao VARCHAR(255);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22003' SET motivo_descricao = 'Valor inválido';
  SELECT descricao INTO motivo_descricao FROM motivos WHERE cod = cod_motivo;
  RETURN motivo_descricao;
END $$
DELIMITER ;

-- Essa função recebe um código de motivo como entrada e retorna a descrição correspondente na tabela "motivos". Ela utiliza a cláusula "DECLARE CONTINUE HANDLER" para lidar com o caso em que o valor de entrada não é um inteiro válido, atribuindo a mensagem "Valor inválido" à variável "motivo_descricao". Caso a consulta SQL não encontre um valor correspondente na tabela, a função retorna NULL.
DELIMITER $$
DROP FUNCTION IF EXISTS get_cod_motivo $$
CREATE FUNCTION get_cod_motivo (parte_descricao VARCHAR(255))
RETURNS INT(11)
BEGIN
  DECLARE cod_motivo INT(11);
  SELECT cod INTO cod_motivo FROM motivos WHERE descricao LIKE CONCAT('%', parte_descricao, '%') LIMIT 1;
  IF (cod_motivo IS NULL) THEN
    SET cod_motivo = 0;
  END IF;
  -- RETURN IFNULL(cod_motivo, 0);
  RETURN cod_motivo;
END $$
DELIMITER ;

-- Esta função recebe uma parte da descrição do CNAE (Classificação Nacional de Atividades Econômicas) e retorna o código correspondente na tabela CNAE. A função começa definindo uma variável cod_cnae para armazenar o código a ser retornado. Em seguida, é executada uma consulta SQL que seleciona o código na tabela CNAE onde a descrição contém a parte passada como parâmetro, limitando a um resultado. Se não for encontrado nenhum resultado, a variável cod_cnae é definida como 0. Por fim, o código é retornado. A função usa a mesma estrutura usada na função get_cod_municipio, adaptada para a tabela CNAE.
DELIMITER $$
DROP FUNCTION IF EXISTS get_cod_cnae $$
CREATE FUNCTION get_cod_cnae (parte_descricao VARCHAR(255))
RETURNS INT(11)
BEGIN
  DECLARE cod_cnae INT(11);
  SELECT cod INTO cod_cnae FROM cnae WHERE descricao LIKE CONCAT('%', parte_descricao, '%') LIMIT 1;
  IF (cod_cnae IS NULL) THEN
    SET cod_cnae = 0;
  END IF;
  -- RETURN IFNULL(cod_cnae, 0);
  RETURN cod_cnae;
END $$
DELIMITER ;