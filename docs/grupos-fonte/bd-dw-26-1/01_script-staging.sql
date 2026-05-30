-- Ana Clara de Jesus Nascimento, DRE 124388471
-- Mariana Rocha de Moraes, DRE 122147926
-- Matheus Mangia Terra Suzano, DRE 123378716
-- Paulo Henrique Cotta de Assumpção, DRE 122156268
-- Pedro Nunes de Oliveira Pessanha, DRE 123177330
-- Ryan Domingos dos Santos Saraiva, DRE 123137429

DROP DATABASE IF EXISTS locadora_dw_staging;
CREATE DATABASE IF NOT EXISTS locadora_dw_staging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE locadora_dw_staging;

-- TABELAS DE STAGING

CREATE TABLE Stg_patio (
    Sistema_Origem              VARCHAR(50)     NULL, -- Identificação da base de dados de origem
    Id_patio_oltp               INT             NULL,
    Nome_patio                  VARCHAR(100)    NULL,
    Cidade                      VARCHAR(100)    NULL,
    Uf                          CHAR(2)         NULL,
    Capacidade                  INT             NULL,
    Data_Carga                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Stg_veiculo (
    Sistema_Origem              VARCHAR(50)     NULL, -- Identificação da base de dados de origem
    Id_veiculo_oltp             INT             NULL,
    Placa                       VARCHAR(10)     NULL,
    Marca                       VARCHAR(50)     NULL,
    Modelo                      VARCHAR(50)     NULL,
    Categoria_Nome              VARCHAR(50)     NULL,
    Ano                         INT             NULL,
    Tipo_Cambio                 VARCHAR(20)     NULL,
    Empresa_Dona                VARCHAR(100)    NULL,
    Data_Carga                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Stg_cliente (
    Sistema_Origem              VARCHAR(50)     NULL, -- Identificação da base de dados de origem
    Id_cliente_oltp             INT             NULL,
    Tipo_Cliente                CHAR(2)         NULL,
    Nome_ou_Razao_Social        VARCHAR(100)    NULL,
    Cidade                      VARCHAR(100)    NULL,
    Uf                          CHAR(2)         NULL,
    Data_Carga                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Stg_motorista (
    Sistema_Origem              VARCHAR(50)     NULL, -- Identificação da base de dados de origem
    Id_motorista_oltp           INT             NULL,
    Nome_motorista              VARCHAR(100)    NULL,
    Categoria_Cnh               VARCHAR(3)      NULL,
    Genero_motorista            CHAR(1)         NULL,
    Data_Nascimento             DATE            NULL, -- Mantido para calcular a Faixa_Etaria no DW
    Data_Carga                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Stg_locacao (
    Sistema_Origem              VARCHAR(50)     NULL, -- Identificação da base de dados de origem
    Id_locacao_oltp             INT             NULL,
    Id_patio_retirada_oltp      INT             NULL,
    Id_patio_devolucao_oltp     INT             NULL,
    Id_veiculo_oltp             INT             NULL,
    Id_cliente_oltp             INT             NULL,
    Id_motorista_oltp           INT             NULL,
    Data_Retirada               DATETIME        NULL,
    Data_Devolucao              DATETIME        NULL,
    Km_Retirada                 INT             NULL,
    Km_Devolucao                INT             NULL,
    Valor_Total                 DECIMAL(10,2)   NULL,
    Data_Carga                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
);