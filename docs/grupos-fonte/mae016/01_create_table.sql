-- =========================================================
-- Projeto: Sistema de Locadora de Veículos
-- Arquivo: 01_create_table.sql
-- Alunos: Breno Belaid Machado Wanderley - 121122313
---------- Hygor Goulart Knust - 117124785
---------- João Valviesse Peclat Brito - 115065139
-- Descrição: Criação das tabelas base do modelo relacional
-- =========================================================

CREATE TABLE EMPRESA (
    id_empresa INTEGER PRIMARY KEY,
    nome_empresa VARCHAR(100) NOT NULL
);

CREATE TABLE PATIO (
    id_patio INTEGER PRIMARY KEY,
    id_empresa INTEGER NOT NULL,
    nome_patio VARCHAR(100) NOT NULL,
    localizacao VARCHAR(150) NOT NULL,
    codigo_patio VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE GRUPO_VEICULO (
    id_grupo INTEGER PRIMARY KEY,
    nome_grupo VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    faixa_valor_diaria DECIMAL(10,2) NOT NULL
);

CREATE TABLE CLIENTE (
    id_cliente INTEGER PRIMARY KEY,
    tipo_cliente VARCHAR(2) NOT NULL,
    nome_razao_social VARCHAR(150) NOT NULL,
    cpf_cnpj VARCHAR(20) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(100)
);

CREATE TABLE CONDUTOR (
    id_condutor INTEGER PRIMARY KEY,
    nome_condutor VARCHAR(150) NOT NULL,
    cpf VARCHAR(20) NOT NULL,
    numero_cnh VARCHAR(20) NOT NULL,
    categoria_cnh VARCHAR(5) NOT NULL,
    validade_cnh DATE NOT NULL,
    id_cliente INTEGER NOT NULL
);

CREATE TABLE VEICULO (
    id_veiculo INTEGER PRIMARY KEY,
    placa VARCHAR(10) NOT NULL,
    chassi VARCHAR(50) NOT NULL,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    cor VARCHAR(30) NOT NULL,
    mecanizacao VARCHAR(20) NOT NULL,
    ar_condicionado BOOLEAN NOT NULL,
    status VARCHAR(20) NOT NULL,
    id_grupo INTEGER NOT NULL,
    id_empresa INTEGER NOT NULL,
    id_patio_atual INTEGER NOT NULL
);

CREATE TABLE RESERVA (
    id_reserva INTEGER PRIMARY KEY,
    data_reserva DATE NOT NULL,
    data_prev_retirada DATE NOT NULL,
    data_prev_devolucao DATE NOT NULL,
    status_reserva VARCHAR(20) NOT NULL,
    id_cliente INTEGER NOT NULL,
    id_grupo INTEGER NOT NULL,
    id_patio_retirada INTEGER NOT NULL,
    id_patio_devolucao_previsto INTEGER NOT NULL
);

CREATE TABLE LOCACAO (
    id_locacao INTEGER PRIMARY KEY,
    data_hora_retirada TIMESTAMP NOT NULL,
    data_hora_prev_devolucao TIMESTAMP NOT NULL,
    data_hora_real_devolucao TIMESTAMP,
    valor_previsto DECIMAL(10,2) NOT NULL,
    valor_final DECIMAL(10,2),
    status_locacao VARCHAR(20) NOT NULL,
    id_reserva INTEGER,
    id_cliente INTEGER NOT NULL,
    id_condutor INTEGER NOT NULL,
    id_veiculo INTEGER NOT NULL,
    id_patio_retirada INTEGER NOT NULL,
    id_patio_devolucao_previsto INTEGER NOT NULL,
    id_patio_devolucao_real INTEGER
);

CREATE TABLE PAGAMENTO (
    id_pagamento INTEGER PRIMARY KEY,
    data_pagamento DATE NOT NULL,
    valor_pagamento DECIMAL(10,2) NOT NULL,
    forma_pagamento VARCHAR(20) NOT NULL,
    tipo_pagamento VARCHAR(20) NOT NULL,
    id_locacao INTEGER NOT NULL
);

CREATE TABLE MOVIMENTACAO_PATIO (
    id_movimentacao INTEGER PRIMARY KEY,
    data_hora_movimentacao TIMESTAMP NOT NULL,
    motivo_movimentacao VARCHAR(100) NOT NULL,
    id_veiculo INTEGER NOT NULL,
    id_patio_origem INTEGER NOT NULL,
    id_patio_destino INTEGER NOT NULL
);
