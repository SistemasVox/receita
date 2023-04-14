/********************************************************/
-- ################### Funções ########################
/********************************************************/


/********************************************************/
-- Função para validar CNPJ. <== MELHOR
/********************************************************/

DELIMITER $$
DROP FUNCTION IF EXISTS validar_cnpj $$
CREATE FUNCTION validar_cnpj(cnpj VARCHAR(14)) RETURNS VARCHAR(100)
BEGIN
    DECLARE msg VARCHAR(100);
    IF LENGTH(cnpj) <> 14 THEN
        SET msg = 'O tamanho do CNPJ está incorreto.';
    ELSEIF NOT cnpj REGEXP '^[0-9]+$' THEN
        SET msg = 'O CNPJ deve conter apenas números.';
    ELSE
        SET msg = '';
    END IF;
    RETURN msg;
END$$
DELIMITER ;

SELECT * FROM empresas WHERE validar_cnpj(cnpj) = '' AND cnpj = '12345678901234';

SELECT * FROM empresas WHERE validar_cnpj(cnpj) = '' AND cnpj = '123456789012345';
/********************************************************/
-- FIM>>>> Função para validar CNPJ.
/********************************************************/

DELIMITER $$
DROP PROCEDURE IF EXISTS busca_empresa_por_cnpj $$
CREATE PROCEDURE busca_empresa_por_cnpj(IN cnpj VARCHAR(100))
BEGIN
    DECLARE msg VARCHAR(100);
    -- Valida o tamanho do CNPJ
    IF LENGTH(cnpj) <> 14 THEN
        SET msg = 'O tamanho do CNPJ está incorreto.';
    -- Verifica se o CNPJ contém apenas números
    ELSEIF NOT cnpj REGEXP '^[0-9]+$' THEN
        SET msg = 'O CNPJ deve conter apenas números.';
    ELSE
        -- Faz a busca no banco de dados
        SELECT * FROM empresas WHERE cnpj = cnpj;
    END IF;
    -- Retorna a mensagem de erro
    SELECT msg;
END $$
DELIMITER ;
CALL busca_empresa_por_cnpj('aaaaaaaaaaaaaa');