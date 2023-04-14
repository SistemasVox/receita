/********************************************************/
-- ################ Procedimentos #####################
/********************************************************/

/********************************************************/
-- Importar dados de arquivos CSV de um determinado DIR.
/********************************************************/

DELIMITER $$
DROP PROCEDURE IF EXISTS import_csv_files$$
CREATE PROCEDURE import_csv_files(directory_path VARCHAR(255), table_name VARCHAR(255))
BEGIN
  DECLARE file_name VARCHAR(255);
  DECLARE import_statement VARCHAR(1000);
  DECLARE done INT DEFAULT FALSE;
  DECLARE files_count INT DEFAULT 0;
  DECLARE imported_files VARCHAR(1000) DEFAULT '';

  -- cursor para ler os arquivos do diretório
  DECLARE file_cursor CURSOR FOR SELECT file_name FROM (SELECT SUBSTRING_INDEX(file_path, '/', -1) AS file_name FROM (SELECT CONCAT(directory_path, '/', file_name) AS file_path FROM (SELECT SUBSTRING_INDEX(@@global.secure_file_priv, '/', -1) AS secure_file_priv) AS secure_file_priv JOIN (SELECT CONCAT(directory_path, '/*.csv') AS file_name) AS file_name ON 1=1) AS file_path WHERE file_name LIKE '%.csv') AS csv_files;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  -- loop para importar cada arquivo CSV
  OPEN file_cursor;
  import_files: LOOP
    FETCH file_cursor INTO file_name;
    IF done THEN
      LEAVE import_files;
    END IF;
    SET @import_statement = CONCAT("LOAD DATA INFILE '", directory_path, "/", file_name, "' INTO TABLE ", table_name, " FIELDS TERMINATED BY ';' ENCLOSED BY '\"' LINES TERMINATED BY '\n';");
    BEGIN
      DECLARE EXIT HANDLER FOR SQLEXCEPTION
      BEGIN
        SELECT CONCAT('Erro ao importar o arquivo ', file_name, ': ', SQLERRM);
      END;
      PREPARE import_statement FROM @import_statement;
      EXECUTE import_statement;
      DEALLOCATE PREPARE import_statement;
    END;
    SET files_count = files_count + 1;
    SET imported_files = CONCAT(imported_files, file_name, ',');
  END LOOP import_files;
  CLOSE file_cursor;

  IF files_count > 0 THEN
    SELECT CONCAT(files_count, ' arquivos CSV importados com sucesso para a tabela ', table_name, ': ', SUBSTRING(imported_files, 1, LENGTH(imported_files) - 1)) AS 'Importação realizada';
  ELSE
    SELECT CONCAT('Não foi encontrado nenhum arquivo CSV no diretório ', directory_path);
  END IF;
END$$
DELIMITER ;

CALL import_csv_files('/root/site/script/csv', 'empresas');
-- ---------------------------------------------

/********************************************************/
-- Criar tabelas por ESTADO, da tabela EMRPESAS. OLD VER
/********************************************************/

DROP PROCEDURE IF EXISTS criar_tabelas_empresas_por_uf;
DELIMITER $$
CREATE PROCEDURE criar_tabelas_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(2);
    DECLARE error_msg VARCHAR(255);
    DECLARE cur CURSOR FOR SELECT DISTINCT uf FROM empresas WHERE uf IS NOT NULL AND uf != '';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
    
        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @table_name = CONCAT('empresas_uf_', @uf);
        SET @query = CONCAT('CREATE TABLE ', @table_name, ' AS SELECT * FROM empresas WHERE uf = "', @uf, '";');
        
        PREPARE stmt FROM @query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    
    CLOSE cur;
END$$
DELIMITER ;

/********************************************************/
-- Criar tabelas por ESTADO, da tabela EMRPESAS. <== MELHOR
/********************************************************/

DROP PROCEDURE IF EXISTS criar_tabelas_empresas_por_uf;
DELIMITER $$
CREATE PROCEDURE criar_tabelas_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(2);
    DECLARE error_msg VARCHAR(255);
    DECLARE success_msg VARCHAR(2000) DEFAULT '';
    DECLARE cur CURSOR FOR SELECT DISTINCT e.uf FROM empresas e WHERE e.uf REGEXP '^[[:alpha:]]+$' AND e.uf IS NOT NULL AND e.uf != '' ORDER BY e.uf ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
    
        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @table_name = CONCAT('empresas_uf_', uf);
        SET @query = CONCAT('DROP TABLE IF EXISTS ', @table_name, ';');
        
        BEGIN
            DECLARE error_code INT DEFAULT 0;
            
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
            BEGIN
                GET DIAGNOSTICS CONDITION 1 error_code = MYSQL_ERRNO, error_msg = MESSAGE_TEXT;
                SET error_msg = CONCAT('Erro encontrado: ', error_msg);
            END;
        
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END;
        
        SET @query = CONCAT('CREATE TABLE ', @table_name, ' AS SELECT * FROM empresas WHERE uf = "', uf, '";');
        
        BEGIN
            DECLARE error_code INT DEFAULT 0;
            
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
            BEGIN
                GET DIAGNOSTICS CONDITION 1 error_code = MYSQL_ERRNO, error_msg = MESSAGE_TEXT;
                SET error_msg = CONCAT('Erro encontrado: ', error_msg);
            END;
        
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            IF error_code = 0 THEN
                SET success_msg = CONCAT_WS('\n', success_msg, CONCAT('Tabela ', @table_name, ' criada com sucesso.'));
            END IF;
        END;
        
    END LOOP;
    
    CLOSE cur;
    
    IF success_msg = '' THEN
        SELECT error_msg;
    ELSE
        SELECT success_msg;
    END IF;
END$$
DELIMITER ;

/********************************************************/
-- Adicionar índice nas empresas por estado MOD DIFF.
/********************************************************/

DROP PROCEDURE IF EXISTS adicionar_indices_empresas_por_uf;
DELIMITER $$

CREATE PROCEDURE adicionar_indices_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(2);
    DECLARE cur CURSOR FOR SELECT DISTINCT e.uf FROM empresas e WHERE e.uf REGEXP '^[[:alpha:]]+$' AND e.uf IS NOT NULL AND e.uf != '' ORDER BY e.uf ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP

        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET @table_name = CONCAT('empresas_uf_', uf);
        
        -- Índices a serem adicionados
        SET @index_nome = CONCAT('CREATE INDEX idx_nome ON ', @table_name, ' (nome);');
        SET @index_cnpj = CONCAT('CREATE INDEX idx_cnpj ON ', @table_name, ' (cnpj, ordem_cnpj, dv_cnpj);');
        SET @index_cnae = CONCAT('CREATE INDEX idx_cnae ON ', @table_name, ' (cnae_principal, cnae_secundaria);');
        SET @index_endereco = CONCAT('CREATE INDEX idx_endereco ON ', @table_name, ' (tipo_logradouro, logradouro, bairro, cep, municipio);');
        SET @index_endereco = CONCAT('CREATE INDEX idx_endereco ON ', @table_name, ' (bairro, cep, municipio);');
        SET @index_situacao_cadastral = CONCAT('CREATE INDEX idx_situacao_cadastral ON ', @table_name, ' (situacao, data_situacao, motivo_situacao);');
        SET @index_situacao_data_abertura = CONCAT('CREATE INDEX idx_situacao_data_abertura ON ', @table_name, ' (data_inicio);');

        -- Executar os comandos SQL para criar os índices
        PREPARE stmt FROM @index_nome;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @index_cnpj;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @index_cnae;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @index_endereco;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @index_situacao_cadastral;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @index_situacao_data_abertura;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;


/********************************************************/
-- Adicionar índice nas empresas por estado LIGHT.
/********************************************************/

DROP PROCEDURE IF EXISTS adicionar_indices_empresas_por_uf;
DELIMITER $$
CREATE PROCEDURE adicionar_indices_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(2);
    DECLARE error_msg VARCHAR(255);
    DECLARE success_msg VARCHAR(2000) DEFAULT '';
    DECLARE cur CURSOR FOR SELECT DISTINCT e.uf FROM empresas e WHERE e.uf REGEXP '^[[:alpha:]]+$' AND e.uf IS NOT NULL AND e.uf != '' ORDER BY e.uf ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
    
        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @table_name = CONCAT('empresas_uf_', uf);
        SET @query = CONCAT('ALTER TABLE ', @table_name, ' 
            ADD INDEX idx_nome (nome), 
            ADD INDEX idx_cnpj (cnpj, ordem_cnpj, dv_cnpj), 
            ADD INDEX idx_cnae (cnae_principal), 
            ADD INDEX idx_endereco (bairro, cep, municipio), 
            ADD INDEX idx_situacao_cadastral (situacao, data_situacao, motivo_situacao), 
            ADD INDEX idx_situacao_data_abertura (data_inicio);
        ');
        
        BEGIN
            DECLARE error_code INT DEFAULT 0;
            
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
            BEGIN
                GET DIAGNOSTICS CONDITION 1 error_code = MYSQL_ERRNO, error_msg = MESSAGE_TEXT;
                SET error_msg = CONCAT('Erro encontrado: ', error_msg);
            END;
        
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            IF error_code = 0 THEN
                SET success_msg = CONCAT_WS('\n', success_msg, CONCAT('Índices adicionados na tabela ', @table_name, ' com sucesso.'));
            END IF;
        END;
        
    END LOOP;
    
    CLOSE cur;
    
    IF success_msg = '' THEN
        SELECT error_msg;
    ELSE
        SELECT success_msg;
    END IF;
END$$
DELIMITER ;

/********************************************************/
-- Excluir índices das empresas por estado. <== MELHOR
/********************************************************/

DROP PROCEDURE IF EXISTS excluir_indices_empresas_por_uf;
DELIMITER $$
CREATE PROCEDURE excluir_indices_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(255);
    DECLARE error_msg VARCHAR(255);
    DECLARE success_msg VARCHAR(2000) DEFAULT '';
    DECLARE cur CURSOR FOR SELECT DISTINCT TABLE_NAME 
                             FROM INFORMATION_SCHEMA.TABLES 
                             WHERE TABLE_NAME LIKE 'empresas_uf_%';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
    
        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @table_name = uf;
        SET @query_drop = CONCAT('ALTER TABLE ', @table_name, ' 
            DROP INDEX IF EXISTS idx_nome, 
            DROP INDEX IF EXISTS idx_cnpj, 
            DROP INDEX IF EXISTS idx_cnae, 
            DROP INDEX IF EXISTS idx_cnae_secundaria, 
            DROP INDEX IF EXISTS idx_endereco, 
            DROP INDEX IF EXISTS idx_situacao_cadastral, 
            DROP INDEX IF EXISTS idx_situacao_data_abertura;
        ');
        
        BEGIN
            DECLARE error_code INT DEFAULT 0;
            
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
            BEGIN
                GET DIAGNOSTICS CONDITION 1 error_code = MYSQL_ERRNO, error_msg = MESSAGE_TEXT;
                SET error_msg = CONCAT('Erro encontrado: ', error_msg);
                ROLLBACK;
            END;
        
            START TRANSACTION;
            PREPARE stmt_drop FROM @query_drop;
            EXECUTE stmt_drop;
            DEALLOCATE PREPARE stmt_drop;
            COMMIT;
            
            IF error_code = 0 THEN
                SET success_msg = CONCAT_WS('\n', success_msg, CONCAT('Índices excluídos da tabela ', @table_name, ' com sucesso.'));
            END IF;
        END;
        
    END LOOP;
    
    CLOSE cur;
    
    IF success_msg = '' THEN
        SELECT error_msg;
    ELSE
        SELECT success_msg;
    END IF;
END$$
DELIMITER ;

/********************************************************/
-- Adicionar índice nas empresas por estado. <== MELHOR
/********************************************************/

DROP PROCEDURE IF EXISTS adicionar_indices_empresas_por_uf;
DELIMITER $$
CREATE PROCEDURE adicionar_indices_empresas_por_uf()
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE uf VARCHAR(255);
    DECLARE error_msg VARCHAR(255);
    DECLARE success_msg VARCHAR(2000) DEFAULT '';
    DECLARE cur CURSOR FOR SELECT DISTINCT TABLE_NAME 
                             FROM INFORMATION_SCHEMA.TABLES 
                             WHERE TABLE_NAME LIKE 'empresas_uf_%';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
    
        FETCH cur INTO uf;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @table_name = uf;
        SET @query = CONCAT('ALTER TABLE ', @table_name, ' 
            ADD FULLTEXT INDEX idx_nome (nome), 
            ADD INDEX idx_cnpj (cnpj, ordem_cnpj, dv_cnpj), 
            ADD INDEX idx_cnae (cnae_principal), 
            ADD FULLTEXT INDEX idx_cnae_secundaria (cnae_secundaria), 
            ADD INDEX idx_endereco (cep, municipio), 
            ADD INDEX idx_situacao_cadastral (situacao, data_situacao, motivo_situacao), 
            ADD INDEX idx_situacao_data_abertura (data_inicio);
        ');
        
        BEGIN
            DECLARE error_code INT DEFAULT 0;
            
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
            BEGIN
                GET DIAGNOSTICS CONDITION 1 error_code = MYSQL_ERRNO, error_msg = MESSAGE_TEXT;
                SET error_msg = CONCAT('Erro encontrado: ', error_msg);
            END;
        
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            IF error_code = 0 THEN
                SET success_msg = CONCAT_WS('\n', success_msg, CONCAT('Índices adicionados na tabela ', @table_name, ' com sucesso às ', TIME_FORMAT(NOW(), '%H:%i:%s'), '.'));
                SELECT CONCAT_WS('\n', CONCAT('Índices adicionados na tabela ', @table_name, ' com sucesso às ', TIME_FORMAT(NOW(), '%H:%i:%s'), '.'));
            END IF;
        END;
        
    END LOOP;
    
    CLOSE cur;
    
    IF success_msg = '' THEN
        SELECT error_msg;
    ELSE
        SELECT success_msg;
    END IF;
END$$
DELIMITER ;


/********************************************************/
-- Atualizar campos LIGHT de uma determinada tabela.
/********************************************************/

DELIMITER $$

DROP PROCEDURE IF EXISTS atualizar_todos_campos_maximo_tabela $$
CREATE PROCEDURE atualizar_todos_campos_maximo_tabela(tabela VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE campo_atualizado VARCHAR(255);
    DECLARE campo VARCHAR(255);
    DECLARE tamanho_maximo INT DEFAULT 0;
    DECLARE tipo VARCHAR(255);
    DECLARE cur_nomes_campos CURSOR FOR SELECT COLUMN_NAME, DATA_TYPE
                                      FROM INFORMATION_SCHEMA.COLUMNS
                                      WHERE TABLE_NAME = tabela
                                        AND TABLE_SCHEMA = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Percorrer os nomes dos campos e atualizá-los para seus respectivos valores máximos
    OPEN cur_nomes_campos;
    nomes_campos_loop: LOOP
        FETCH cur_nomes_campos INTO campo, tipo;
        IF done THEN
            CLOSE cur_nomes_campos;
            LEAVE nomes_campos_loop;
        END IF;
        
        IF tipo = 'text' THEN
            -- busca o tamanho máximo do campo
            SET @query = CONCAT('SELECT MAX(LENGTH(', campo, ')) INTO @tamanho_maximo FROM ', tabela);
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            -- atualiza o campo com o valor máximo encontrado
            IF @tamanho_maximo > 0 THEN
                SET @query = CONCAT('ALTER TABLE ', tabela, ' MODIFY COLUMN ', campo, ' VARCHAR(', @tamanho_maximo, ')');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;

                -- captura o campo atualizado
                SET campo_atualizado = CONCAT(tabela, '.', campo);
                SELECT CONCAT('O campo ', campo_atualizado, ' foi atualizado para VARCHAR(', @tamanho_maximo, ').') AS mensagem;
            ELSE
                -- o campo é vazio, não precisa atualizar
                SET campo_atualizado = CONCAT(tabela, '.', campo);
                SELECT CONCAT('O campo ', campo_atualizado, ' está vazio, não precisa ser atualizado.') AS mensagem;
            END IF;
        ELSE
            -- não é um campo do tipo text, não precisa atualizar
            SET campo_atualizado = CONCAT(tabela, '.', campo);
            SELECT CONCAT('O campo ', campo_atualizado, ' não é do tipo TEXT, não precisa ser atualizado.') AS mensagem;
        END IF;
    END LOOP nomes_campos_loop;
    
    SELECT CONCAT('A atualização de todos os campos TEXT da tabela ', tabela, ' foi concluída.') AS mensagem;
    
END $$

DELIMITER ;
CALL atualizar_todos_campos_maximo_tabela("empresas");

/********************************************************/
-- Criar uma tabela nova com campos atualizados. <== MELHOR
/********************************************************/

DELIMITER $$

DROP PROCEDURE IF EXISTS criar_tabela_nova $$
CREATE PROCEDURE criar_tabela_nova(tabela VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE campo_atualizado VARCHAR(255);
    DECLARE campo VARCHAR(255);
    DECLARE tamanho_maximo INT DEFAULT 0;
    DECLARE tipo VARCHAR(255);
    DECLARE colunas_atualizadas TEXT DEFAULT '';
    DECLARE cur_nomes_campos CURSOR FOR SELECT COLUMN_NAME, DATA_TYPE
                                      FROM INFORMATION_SCHEMA.COLUMNS
                                      WHERE TABLE_NAME = tabela
                                        AND TABLE_SCHEMA = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Cria uma nova tabela com os campos atualizados
    SET @query = CONCAT('CREATE TABLE ', tabela, '_atualizada LIKE ', tabela);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Percorrer os nomes dos campos e atualizá-los para seus respectivos valores máximos
    OPEN cur_nomes_campos;
    nomes_campos_loop: LOOP
        FETCH cur_nomes_campos INTO campo, tipo;
        IF done THEN
            CLOSE cur_nomes_campos;
            LEAVE nomes_campos_loop;
        END IF;
        
        IF tipo = 'text' THEN
            -- busca o tamanho máximo do campo
            SET @query = CONCAT('SELECT MAX(LENGTH(', campo, ')) INTO @tamanho_maximo FROM ', tabela);
            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            -- atualiza o campo com o valor máximo encontrado
            IF @tamanho_maximo > 0 THEN
                SET @query = CONCAT('ALTER TABLE ', tabela, '_atualizada MODIFY COLUMN ', campo, ' VARCHAR(', @tamanho_maximo, ')');
                PREPARE stmt FROM @query;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;

                -- captura o campo atualizado
                SET campo_atualizado = CONCAT(tabela, '.', campo);
                SET colunas_atualizadas = CONCAT(colunas_atualizadas, campo_atualizado, ' atualizado para VARCHAR(', @tamanho_maximo, ').\n');
            ELSE
                -- o campo é vazio, não precisa atualizar
                SET campo_atualizado = CONCAT(tabela, '.', campo);
                SET colunas_atualizadas = CONCAT(colunas_atualizadas, campo_atualizado, ' está vazio, não precisa ser atualizado.\n');
            END IF;
        ELSE
            -- não é um campo do tipo text, não precisa atualizar
            SET campo_atualizado = CONCAT(tabela, '.', campo);
            SET colunas_atualizadas = CONCAT(colunas_atualizadas, campo_atualizado, ' não é do tipo TEXT, não precisa ser atualizado.\n');
        END IF;
    END LOOP nomes_campos_loop;
    
    SELECT CONCAT('A nova tabela ', tabela, '_atualizada foi criada com sucesso.\n\nOs seguintes campos foram atualizados:\n', colunas_atualizadas) AS mensagem;
    
END $$

DELIMITER ;


CALL criar_tabela_nova('empresas');

/********************************************************/
-- Remover espaços vazios dos Campos de uma Tabela. <== MELHOR
/********************************************************/

DELIMITER //

DROP PROCEDURE IF EXISTS remove_espacos_extras //

CREATE PROCEDURE remove_espacos_extras(IN tabela VARCHAR(255))
BEGIN
    DECLARE coluna VARCHAR(255);
    DECLARE fim INT DEFAULT 0;
    DECLARE qtd_colunas INT DEFAULT 0;
    DECLARE qtd_atualizada INT DEFAULT 0;
    DECLARE hora_atual VARCHAR(255);
    DECLARE tempo_medio INT DEFAULT 0;
    DECLARE tempo_restante INT DEFAULT 0;
    DECLARE cur CURSOR FOR 
        SELECT column_name FROM information_schema.columns
        WHERE table_name = tabela;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET fim = 1;
 
    SELECT COUNT(*) INTO qtd_colunas FROM information_schema.columns WHERE table_name = tabela;
    SET hora_atual = CONCAT('Hora atual: ', NOW());
    SELECT CONCAT('Iniciando atualização de tabela: ', tabela, ', ', hora_atual) AS 'Mensagem';
 
    OPEN cur;
 
    ler_colunas: LOOP
        FETCH cur INTO coluna;
        IF fim = 1 THEN
            LEAVE ler_colunas;
        END IF;
        SET hora_atual = CONCAT('Hora atual: ', NOW());
        SELECT CONCAT('Atualizando coluna: ', coluna, ', ', hora_atual) AS 'Mensagem';
        SET @query = CONCAT('UPDATE ', tabela, ' SET ', coluna, ' = TRIM(REPLACE(REPLACE(', coluna, ', ''\t'', '' ''), ''  '', '' '')) WHERE ', coluna, ' IS NOT NULL;');
        SET tempo_medio = 0;
        SET tempo_restante = 0;
        PREPARE stmt FROM @query;
        SET @start = UNIX_TIMESTAMP();
        EXECUTE stmt;
        SET @end = UNIX_TIMESTAMP();
        DEALLOCATE PREPARE stmt;
        SET qtd_atualizada = qtd_atualizada + 1;
        SET tempo_medio = (@end - @start) / qtd_atualizada;
        SET tempo_restante = tempo_medio * (qtd_colunas - qtd_atualizada);
        SET hora_atual = CONCAT('Hora atual: ', NOW());
        SELECT CONCAT('Coluna atualizada: ', coluna, ', ', hora_atual, ', tempo restante: ', SEC_TO_TIME(tempo_restante), ', ', qtd_atualizada, '/', qtd_colunas, ' colunas atualizadas') AS 'Mensagem';
    END LOOP ler_colunas;

    CLOSE cur;
    SET hora_atual = CONCAT('Hora atual: ', NOW());
    SELECT CONCAT('Atualização concluída em tabela: ', tabela, ', ', hora_atual, ', ', qtd_atualizada, '/', qtd_colunas, ' colunas atualizadas') AS 'Mensagem';
END //

DELIMITER ;


/********************************************************/
-- Atualizar Campos vazios para nulo de uma tabela.
/********************************************************/

DELIMITER //

DROP PROCEDURE IF EXISTS atualiza_tabela_campos_nulos //
CREATE PROCEDURE atualiza_tabela_campos_nulos(IN nome_tabela VARCHAR(255))
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE coluna VARCHAR(255);
  DECLARE cur CURSOR FOR SELECT COLUMN_NAME FROM information_schema.columns WHERE table_name = nome_tabela;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  SET @q1 = CONCAT('UPDATE ', nome_tabela, ' SET ');

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO coluna;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SET @q1 = CONCAT(@q1, coluna, ' = NULL, ');
  END LOOP;

  CLOSE cur;

  SET @q1 = SUBSTRING(@q1, 1, LENGTH(@q1) - 2);

  SET @q2 = CONCAT(@q1, ' WHERE ');

  SET @q3 = CONCAT('TRIM(', coluna, ') = '''' OR ', coluna, ' IS NULL OR LENGTH(TRIM(', coluna, ')) = 0');

  SET @q2 = CONCAT(@q2, @q3);

  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      SELECT CONCAT('Erro ao atualizar a tabela ', nome_tabela, ': ', SQLERRM) AS mensagem;
    END;

    PREPARE stmt FROM @q2;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Atualização da tabela ', nome_tabela, ' concluída.') AS mensagem;
  END;
END//

DELIMITER ;
CALL atualiza_tabela_campos_nulos('empresas');

/********************************************************/
-- Atualizar Campos vazios para nulo de uma tabela. TIME
/********************************************************/


DELIMITER //

DROP PROCEDURE IF EXISTS atualiza_tabela_campos_nulos //

CREATE PROCEDURE atualiza_tabela_campos_nulos(IN nome_tabela VARCHAR(255))
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE coluna VARCHAR(255);
  DECLARE contador INT DEFAULT 0;
  DECLARE total INT DEFAULT 0;
  DECLARE tempo_inicio DATETIME;
  DECLARE tempo_execucao INT DEFAULT 0;
  DECLARE cur CURSOR FOR SELECT COLUMN_NAME FROM information_schema.columns WHERE table_name = nome_tabela;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  SET @q1 = CONCAT('UPDATE ', nome_tabela, ' SET ');

  OPEN cur;

  read_loop: LOOP
    FETCH cur INTO coluna;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SET @q1 = CONCAT(@q1, coluna, ' = NULL, ');
  END LOOP;

  CLOSE cur;

  SET @q1 = SUBSTRING(@q1, 1, LENGTH(@q1) - 2);

  SET @q2 = CONCAT(@q1, ' WHERE ');

  SET @q3 = CONCAT('TRIM(', coluna, ') = '''' OR ', coluna, ' IS NULL OR LENGTH(TRIM(', coluna, ')) = 0');

  SET @q2 = CONCAT(@q2, @q3);

  SET @q4 = CONCAT('SELECT COUNT(*) INTO @total FROM ', nome_tabela, ';');
  PREPARE stmt FROM @q4;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET tempo_inicio = NOW();

  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      SELECT CONCAT('Erro ao atualizar a tabela ', nome_tabela, ': ', SQLERRM) AS mensagem;
    END;
    
    OPEN cur;

    read_loop2: LOOP
      FETCH cur INTO coluna;
      IF done THEN
        LEAVE read_loop2;
      END IF;

      SET @query = CONCAT('UPDATE ', nome_tabela, ' SET ', coluna, ' = NULL WHERE TRIM(', coluna, ') = '''' OR ', coluna, ' IS NULL OR LENGTH(TRIM(', coluna, ')) = 0;');

      SET contador = contador + 1;

      SET tempo_execucao = TIMESTAMPDIFF(SECOND, tempo_inicio, NOW());

      SELECT CONCAT('Atualizando tabela: ', nome_tabela, ', coluna: ', coluna, ', faltam ', total - contador, ' de ', total, ', previsão de término: ', DATE_ADD(NOW(), INTERVAL (contador/total) * (tempo_execucao - tempo_inicio) SECOND)) AS 'Mensagem';

      PREPARE stmt FROM @query;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;

    END LOOP;

    CLOSE cur;

    SELECT CONCAT('Atualização da tabela ', nome_tabela, ' concluída.') AS mensagem;
  END;
END//
DELIMITER ;

/********************************************************/
-- Atualizar Campos vazios para nulo de uma tabela. TIME <== MELHOR
/********************************************************/

DELIMITER //

DROP PROCEDURE IF EXISTS limpar_tabela //

CREATE PROCEDURE limpar_tabela(IN tabela VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE coluna TEXT;
    DECLARE total INT;
    DECLARE count INT DEFAULT 0;
    DECLARE percent INT DEFAULT 0;
    DECLARE start_time TIMESTAMP DEFAULT NOW();
    DECLARE time_remaining INT;
    DECLARE message VARCHAR(255);
    DECLARE col_count INT DEFAULT 0;
    DECLARE db_name VARCHAR(255);
        DECLARE cur CURSOR FOR 
        SELECT column_name FROM information_schema.columns
        WHERE table_name = tabela;
    
    SELECT DATABASE() INTO db_name;
    SELECT COUNT(*) INTO col_count FROM information_schema.columns WHERE table_name = tabela LIMIT 1;

    IF col_count > 0 THEN
        SET total = col_count;
        
        OPEN cur;

        read_loop: LOOP
            FETCH cur INTO coluna;

            IF done THEN
                LEAVE read_loop;
            END IF;

            SET @query = CONCAT('UPDATE ', db_name, '.', tabela, ' SET ', coluna, ' = NULL WHERE LENGTH(TRIM(', coluna, ')) = 0');

            SET count = count + 1;
            SET percent = CEIL((count / total) * 100);
            SET time_remaining = CEIL((NOW() - start_time) / count * (total - count));

            SET message = CONCAT('Atualizando coluna ', coluna, ' (', count, '/', total, ', ', percent, '%) - Tempo restante: ', SEC_TO_TIME(time_remaining), ' - Estimativa de término: ', DATE_ADD(NOW(), INTERVAL time_remaining SECOND));
            SELECT message AS 'MENSAGEM';

            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END LOOP read_loop;

        CLOSE cur;

        SET message = CONCAT('Atualização de ', tabela, ' concluída com sucesso!');
        SELECT message AS 'MENSAGEM';
    ELSE
        SET message = CONCAT('Não há colunas a serem atualizadas na tabela ', tabela, '.');
        SELECT message AS 'MENSAGEM';
    END IF;
END //

DELIMITER ;

/********************************************************/
-- Atualizar Campos vazios para nulo de uma tabela. TIME/MED
/********************************************************/

DELIMITER //

DROP PROCEDURE IF EXISTS limpar_tabela //

CREATE PROCEDURE limpar_tabela(IN tabela VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE coluna TEXT;
    DECLARE total INT;
    DECLARE count INT DEFAULT 0;
    DECLARE percent INT DEFAULT 0;
    DECLARE start_time TIMESTAMP DEFAULT NOW();
    DECLARE time_remaining INT;
    DECLARE message VARCHAR(255);
    DECLARE col_count INT DEFAULT 0;
    DECLARE db_name VARCHAR(255);
	DECLARE total_time INT DEFAULT 0;
	DECLARE time_spent INT DEFAULT 0;
	DECLARE time_per_update INT DEFAULT 0;
    DECLARE total_updates INT DEFAULT 0;
    DECLARE cur CURSOR FOR 
        SELECT column_name FROM information_schema.columns
        WHERE table_name = tabela;

    
    SELECT DATABASE() INTO db_name;
    SELECT COUNT(*) INTO col_count FROM information_schema.columns WHERE table_name = tabela LIMIT 1;

    IF col_count > 0 THEN
        SET total = col_count;
        
        OPEN cur;

        read_loop: LOOP
            FETCH cur INTO coluna;

            IF done THEN
                LEAVE read_loop;
            END IF;

            SET @query = CONCAT('UPDATE ', db_name, '.', tabela, ' SET ', coluna, ' = NULL WHERE LENGTH(TRIM(', coluna, ')) = 0');

            SET count = count + 1;
            SET percent = CEIL((count / total) * 100);
            SET time_spent = TIME_TO_SEC(TIMEDIFF(NOW(), start_time));
            SET total_time = total_time + time_spent;
            SET total_updates = total_updates + 1;
            SET time_per_update = total_time / total_updates;
            SET time_remaining = CEIL(time_per_update * (total - count));
            
            SET message = CONCAT('Atualizando coluna ', coluna, ' (', count, '/', total, ', ', percent, '%) - Tempo restante: ', SEC_TO_TIME(time_remaining), ' - Estimativa de término: ', DATE_ADD(NOW(), INTERVAL time_remaining SECOND));
            SELECT message AS 'MENSAGEM';

            PREPARE stmt FROM @query;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END LOOP read_loop;

        CLOSE cur;

        SET message = CONCAT('Atualização de ', tabela, ' concluída com sucesso!');
        SELECT message AS 'MENSAGEM';
    ELSE
        SET message = CONCAT('Não há colunas a serem atualizadas na tabela ', tabela, '.');
        SELECT message AS 'MENSAGEM';
    END IF;
END //

DELIMITER ;

