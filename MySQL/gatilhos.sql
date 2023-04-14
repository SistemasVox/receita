/********************************************************/
-- ################### Gatilhos ########################
/********************************************************/

/********************************************************/
-- Para juntar o CNPJ.
/********************************************************/
DROP TRIGGER IF EXISTS empresas_juntar_cnpj;
DELIMITER $$
CREATE TRIGGER empresas_juntar_cnpj BEFORE INSERT ON empresas
FOR EACH ROW
BEGIN
    SET NEW.cnpj = CONCAT(NEW.cnpj, NEW.ordem_cnpj, NEW.dv_cnpj);
    SET NEW.ordem_cnpj = NULL;
    SET NEW.dv_cnpj = NULL;
END$$
DELIMITER ;

/********************************************************/
-- Para juntar o endereço.
/********************************************************/
DROP TRIGGER IF EXISTS empresas_juntar_endereco;
DELIMITER $$
CREATE TRIGGER empresas_juntar_endereco BEFORE INSERT ON empresas
FOR EACH ROW
BEGIN
    SET NEW.endereco = CONCAT(NEW.tipo_logradouro, ' ', NEW.logradouro, ', ', NEW.numero, ', ', NEW.complemento, ', ', NEW.bairro, ', ', NEW.cep);
    SET NEW.tipo_logradouro = NULL;
    SET NEW.logradouro = NULL;
    SET NEW.numero = NULL;
    SET NEW.complemento = NULL;
    SET NEW.bairro = NULL;
    SET NEW.cep = NULL;
END$$
DELIMITER ;

/********************************************************/
-- Para juntar o CNAE.
/********************************************************/
DROP TRIGGER IF EXISTS empresas_juntar_cnae;
DELIMITER $$
CREATE TRIGGER empresas_juntar_cnae BEFORE INSERT ON empresas
FOR EACH ROW
BEGIN
    SET NEW.cnae = CONCAT(NEW.cnae_principal, ', ', NEW.cnae_secundaria);
    SET NEW.cnae_principal = NULL;
    SET NEW.cnae_secundaria = NULL;
END$$
DELIMITER ;
