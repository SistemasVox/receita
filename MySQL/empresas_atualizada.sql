-- phpMyAdmin SQL Dump
-- version 5.2.1-1.fc37
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Tempo de geração: 06/04/2023 às 17:27
-- Versão do servidor: 10.5.18-MariaDB
-- Versão do PHP: 8.1.17

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: empresas
--

-- --------------------------------------------------------

--
-- Estrutura para tabela empresas_atualizada
--

CREATE TABLE empresas_atualizada (
  cnpj varchar(8) DEFAULT NULL,
  ordem_cnpj varchar(4) DEFAULT NULL,
  dv_cnpj varchar(2) DEFAULT NULL,
  id_matriz_filial varchar(1) DEFAULT NULL,
  nome varchar(55) DEFAULT NULL,
  situacao varchar(2) DEFAULT NULL,
  data_situacao varchar(8) DEFAULT NULL,
  motivo_situacao varchar(2) DEFAULT NULL,
  nome_cidade varchar(52) DEFAULT NULL,
  pais varchar(3) DEFAULT NULL,
  data_inicio varchar(8) DEFAULT NULL,
  cnae_principal varchar(7) DEFAULT NULL,
  cnae_secundaria varchar(791) DEFAULT NULL,
  tipo_logradouro varchar(20) DEFAULT NULL,
  logradouro varchar(60) DEFAULT NULL,
  numero varchar(6) DEFAULT NULL,
  complemento varchar(156) DEFAULT NULL,
  bairro varchar(50) DEFAULT NULL,
  cep varchar(8) DEFAULT NULL,
  uf varchar(2) DEFAULT NULL,
  municipio varchar(4) DEFAULT NULL,
  ddd_1 varchar(4) DEFAULT NULL,
  telefone_1 varchar(8) DEFAULT NULL,
  ddd_2 varchar(4) DEFAULT NULL,
  telefone_2 varchar(8) DEFAULT NULL,
  ddd_fax varchar(4) DEFAULT NULL,
  fax varchar(8) DEFAULT NULL,
  email varchar(115) DEFAULT NULL,
  situacao_especial varchar(25) DEFAULT NULL,
  data_situacao_especial varchar(8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
