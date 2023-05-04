-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Tempo de geração: 04/05/2023 às 00:34
-- Versão do servidor: 10.4.28-MariaDB
-- Versão do PHP: 7.2.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `marcelo_cnjp`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `empresas`
--

CREATE TABLE `empresas` (
  `cnpj` varchar(14) DEFAULT NULL,
  `ordem_cnpj` varchar(4) DEFAULT NULL,
  `dv_cnpj` varchar(2) DEFAULT NULL,
  `id_matriz_filial` varchar(1) DEFAULT NULL,
  `nome` varchar(55) DEFAULT NULL,
  `situacao` varchar(2) DEFAULT NULL,
  `data_situacao` varchar(8) DEFAULT NULL,
  `motivo_situacao` varchar(2) DEFAULT NULL,
  `nome_cidade` varchar(52) DEFAULT NULL,
  `pais` varchar(3) DEFAULT NULL,
  `data_inicio` varchar(8) DEFAULT NULL,
  `cnae_principal` varchar(7) DEFAULT NULL,
  `cnae_secundaria` varchar(791) DEFAULT NULL,
  `tipo_logradouro` varchar(20) DEFAULT NULL,
  `logradouro` varchar(60) DEFAULT NULL,
  `numero` varchar(6) DEFAULT NULL,
  `complemento` varchar(156) DEFAULT NULL,
  `bairro` varchar(50) DEFAULT NULL,
  `cep` varchar(8) DEFAULT NULL,
  `uf` varchar(2) DEFAULT NULL,
  `municipio` varchar(4) DEFAULT NULL,
  `ddd_1` varchar(4) DEFAULT NULL,
  `telefone_1` varchar(8) DEFAULT NULL,
  `ddd_2` varchar(4) DEFAULT NULL,
  `telefone_2` varchar(8) DEFAULT NULL,
  `ddd_fax` varchar(4) DEFAULT NULL,
  `fax` varchar(8) DEFAULT NULL,
  `email` varchar(115) DEFAULT NULL,
  `situacao_especial` varchar(25) DEFAULT NULL,
  `data_situacao_especial` varchar(8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Despejando dados para a tabela `empresas`
--

INSERT INTO `empresas` (`cnpj`, `ordem_cnpj`, `dv_cnpj`, `id_matriz_filial`, `nome`, `situacao`, `data_situacao`, `motivo_situacao`, `nome_cidade`, `pais`, `data_inicio`, `cnae_principal`, `cnae_secundaria`, `tipo_logradouro`, `logradouro`, `numero`, `complemento`, `bairro`, `cep`, `uf`, `municipio`, `ddd_1`, `telefone_1`, `ddd_2`, `telefone_2`, `ddd_fax`, `fax`, `email`, `situacao_especial`, `data_situacao_especial`) VALUES
('27459784000177', NULL, NULL, '1', 'IDERLAN ALBERTO', '08', '20191111', '01', '', '', '20170404', '4789004', '5620104,9609207,3832700,4724500,3831999,4721103,4789099,0161001,0159802,4744002', 'AREA', 'RURAL', '0', '', 'AREA RURAL DE LUZIANIA', '72859899', 'GO', '9445', '61', '96446681', '', '', '', '', 'iderlanalberto@hotmail.com', '', '');

--
-- Gatilhos `empresas`
--
DELIMITER $$
CREATE TRIGGER `empresas_juntar_cnpj` BEFORE INSERT ON `empresas` FOR EACH ROW BEGIN
    SET NEW.cnpj = CONCAT(NEW.cnpj, NEW.ordem_cnpj, NEW.dv_cnpj);
    SET NEW.ordem_cnpj = NULL;
    SET NEW.dv_cnpj = NULL;
END
$$
DELIMITER ;

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `empresas`
--
ALTER TABLE `empresas` ADD FULLTEXT KEY `idx_cnpj` (`cnpj`);
ALTER TABLE `empresas` ADD FULLTEXT KEY `idx_cnae` (`cnae_principal`,`cnae_secundaria`);
ALTER TABLE `empresas` ADD FULLTEXT KEY `idx_nome` (`nome`);
ALTER TABLE `empresas` ADD FULLTEXT KEY `idx_fulltext_endereco` (`tipo_logradouro`,`logradouro`,`bairro`,`cep`,`uf`,`municipio`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
