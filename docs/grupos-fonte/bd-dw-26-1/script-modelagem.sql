-- Ana Clara de Jesus Nascimento, DRE 124388471
-- Mariana Rocha de Moraes, DRE 122147926
-- Matheus Mangia Terra Suzano, DRE 123378716
-- Paulo Henrique Cotta de Assumpção, DRE 122156268
-- Pedro Nunes de Oliveira Pessanha, DRE 123177330
-- Ryan Domingos dos Santos Saraiva, DRE 123137429

DROP DATABASE IF EXISTS locadora_dw;
CREATE DATABASE IF NOT EXISTS locadora_dw CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE locadora_dw;

-- Armazena os locais físicos. Separado em tabela própria para evitar redundância
CREATE TABLE Endereco (
    Id_endereco     INT             NOT NULL AUTO_INCREMENT,
    Uf              CHAR(2)         NULL,
    Cep             VARCHAR(8)      NULL,
    Cidade          VARCHAR(100)    NULL,
    Bairro          VARCHAR(100)    NULL,
    Logradouro      VARCHAR(150)    NULL,
    Numero          VARCHAR(20)     NULL,
    Complemento     VARCHAR(100)    NULL,

    CONSTRAINT PK_Endereco PRIMARY KEY (Id_endereco)
);

CREATE TABLE Empresa (
    Id_empresa      INT             NOT NULL AUTO_INCREMENT,
    Id_endereco     INT             NOT NULL,
    Nome_empresa    VARCHAR(100)    NULL,
    Cnpj_empresa    VARCHAR(14)     NULL,

    CONSTRAINT PK_Empresa       PRIMARY KEY (Id_empresa),
    CONSTRAINT FK_Emp_Endereco  FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

-- Pátios de retirada e devolução
CREATE TABLE Patio (
    Id_patio        INT             NOT NULL AUTO_INCREMENT,
    Id_empresa      INT             NOT NULL,
    Id_endereco     INT             NOT NULL,
    Nome_patio      VARCHAR(100)    NULL,
    Capacidade      INT             NULL,
    Hora_abertura   TIME            NULL,
    Hora_fechamento TIME            NULL,
    Funciona_24h    TINYINT(1)      NULL,

    CONSTRAINT PK_Patio         PRIMARY KEY (Id_patio),
    CONSTRAINT FK_Pat_Empresa   FOREIGN KEY (Id_empresa)  REFERENCES Empresa(Id_empresa),
    CONSTRAINT FK_Pat_Endereco  FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

CREATE TABLE Vaga (
    Id_vaga                 INT             NOT NULL AUTO_INCREMENT,
    Id_patio                INT             NOT NULL,
    Codigo_vaga             VARCHAR(20)     NULL,
    Status_disponibilidade  VARCHAR(20)     NULL,

    CONSTRAINT PK_Vaga      PRIMARY KEY (Id_vaga),
    CONSTRAINT FK_Vag_Patio FOREIGN KEY (Id_patio) REFERENCES Patio(Id_patio)
);

CREATE TABLE Categoria (
    Id_categoria        INT             NOT NULL AUTO_INCREMENT,
    Nome_categoria      VARCHAR(50)     NULL,
    Descricao_categoria TEXT            NULL,
    Valor_diaria_base   DECIMAL(10,2)   NULL,

    CONSTRAINT PK_Categoria PRIMARY KEY (Id_categoria)
);

-- Cadastro da frota
CREATE TABLE Veiculo (
    Id_veiculo              INT             NOT NULL AUTO_INCREMENT,
    Id_empresa              INT             NOT NULL,
    Id_categoria            INT             NOT NULL,
    Id_vaga                 INT             NULL,       -- NULL quando a vaga está livre (veículo locado)
    Placa                   VARCHAR(7)      NULL,
    Chassi                  VARCHAR(17)     NULL,
    Marca                   VARCHAR(50)     NULL,
    Modelo                  VARCHAR(50)     NULL,
    Ano                     INT             NULL,
    Cor                     VARCHAR(20)     NULL,
    Tipo_cambio             VARCHAR(20)     NULL,
    Possui_ar_condicionado  TINYINT(1)      NULL,       -- 0=Não / 1=Sim
    Capacidade_pessoas      INT             NULL,
    Capacidade_porta_malas  INT             NULL,
    Dimensoes               VARCHAR(50)     NULL,
    Km_atual                INT             NULL,
    Status_veiculo          VARCHAR(30)     NULL,

    CONSTRAINT PK_Veiculo           PRIMARY KEY (Id_veiculo),
    CONSTRAINT UQ_Vaga              UNIQUE (Id_vaga),   -- UNIQUE garante relação 1:1 com Vaga
    CONSTRAINT FK_Vei_Empresa       FOREIGN KEY (Id_empresa)   REFERENCES Empresa(Id_empresa),
    CONSTRAINT FK_Vei_Categoria     FOREIGN KEY (Id_categoria) REFERENCES Categoria(Id_categoria),
    CONSTRAINT FK_Vei_Vaga          FOREIGN KEY (Id_vaga)      REFERENCES Vaga(Id_vaga)
);

CREATE TABLE Acessorio (
    Id_acessorio    INT             NOT NULL AUTO_INCREMENT,
    Nome_acessorio  VARCHAR(50)     NULL,
    Tipo_acessorio  VARCHAR(50)     NULL,

    CONSTRAINT PK_Acessorio PRIMARY KEY (Id_acessorio)
);

-- Relacionamento N:M entre Veiculo e Acessorio
CREATE TABLE Veiculo_acessorio (
    Id_veiculo      INT     NOT NULL,
    Id_acessorio    INT     NOT NULL,

    CONSTRAINT PK_Veiculo_acessorio PRIMARY KEY (Id_veiculo, Id_acessorio),
    CONSTRAINT FK_VA_Veiculo        FOREIGN KEY (Id_veiculo)   REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_VA_Acessorio      FOREIGN KEY (Id_acessorio) REFERENCES Acessorio(Id_acessorio)
);

CREATE TABLE Manutencao (
    Id_manutencao       INT             NOT NULL AUTO_INCREMENT,
    Id_veiculo          INT             NOT NULL,
    Data_revisao        DATE            NULL,
    Estado_conservacao  TEXT            NULL,
    Pressao_pneus       VARCHAR(20)     NULL,
    Nivel_oleo          VARCHAR(20)     NULL,
    Km_revisao          INT             NULL,

    CONSTRAINT PK_Manutencao    PRIMARY KEY (Id_manutencao),
    CONSTRAINT FK_Man_Veiculo   FOREIGN KEY (Id_veiculo) REFERENCES Veiculo(Id_veiculo)
);

-- Implementação de Herança. Guarda atributos comuns a PF e PJ.
CREATE TABLE Cliente (
    Id_cliente          INT             NOT NULL AUTO_INCREMENT,
    Id_endereco         INT             NOT NULL,
    Tipo_cliente        CHAR(2)         NULL,           -- Discriminador ('PF' ou 'PJ')
    Email_cliente       VARCHAR(100)    NULL,
    Telefone_cliente    VARCHAR(20)     NULL,

    CONSTRAINT PK_Cliente       PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_Cli_Endereco  FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

CREATE TABLE Cliente_pf (
    Id_cliente              INT             NOT NULL,
    Nome_cliente            VARCHAR(100)    NULL,
    Cpf_cliente             VARCHAR(11)     NULL,
    Data_nascimento_cliente DATE            NULL,
    Genero_cliente          CHAR(1)         NULL,

    CONSTRAINT PK_Cliente_pf PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_PF_Cliente FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Cliente_pj (
    Id_cliente      INT             NOT NULL,
    Razao_social    VARCHAR(100)    NULL,
    Nome_fantasia   VARCHAR(100)    NULL,
    Cnpj_cliente    VARCHAR(14)     NULL,

    CONSTRAINT PK_Cliente_pj PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_PJ_Cliente FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Motorista (
    Id_motorista                INT             NOT NULL AUTO_INCREMENT,
    Id_cliente                  INT             NOT NULL,
    Nome_motorista              VARCHAR(100)    NULL,
    Numero_cnh                  VARCHAR(20)     NULL,
    Categoria_cnh               VARCHAR(3)      NULL,
    Validade_cnh                DATE            NULL,
    Data_nascimento_motorista   DATE            NULL,
    Email_motorista             VARCHAR(100)    NULL,
    Telefone_motorista          VARCHAR(20)     NULL,
    Genero_motorista            CHAR(1)         NULL,
    Relacao_motorista_cliente   VARCHAR(50)     NULL,

    CONSTRAINT PK_Motorista     PRIMARY KEY (Id_motorista),
    CONSTRAINT FK_Mot_Cliente   FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Dados_cobranca (
    Id_dados_cobranca   INT             NOT NULL AUTO_INCREMENT,
    Id_cliente          INT             NOT NULL,
    Numero_cartao       VARCHAR(20)     NULL,
    Nome_titular_cartao VARCHAR(100)    NULL,
    Validade_cartao     VARCHAR(5)      NULL,
    Cpf_titular_cartao  VARCHAR(11)     NULL,

    CONSTRAINT PK_Dados_cobranca    PRIMARY KEY (Id_dados_cobranca),
    CONSTRAINT FK_Dados_Cliente     FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Protecao_seguro (
    Id_protecao         INT             NOT NULL AUTO_INCREMENT,
    Nome_protecao       VARCHAR(100)    NULL,
    Descricao_cobertura TEXT            NULL,
    Valor_adicional     DECIMAL(10,2)   NULL,

    CONSTRAINT PK_Protecao_seguro PRIMARY KEY (Id_protecao)
);

CREATE TABLE Reserva (
    Id_reserva                  INT             NOT NULL AUTO_INCREMENT,
    Id_cliente                  INT             NOT NULL,
    Id_categoria                INT             NOT NULL,
    Id_patio_previsto_retirada  INT             NOT NULL,
    Id_patio_previsto_devolucao INT             NOT NULL,
    Data_hora_reserva           DATETIME        NULL,
    Data_previsao_retirada      DATETIME        NULL,
    Data_previsao_devolucao     DATETIME        NULL,
    Valor_previsto              DECIMAL(10,2)   NULL,
    Status_reserva              VARCHAR(30)     NULL,

    CONSTRAINT PK_Reserva               PRIMARY KEY (Id_reserva),
    CONSTRAINT FK_Res_Cliente           FOREIGN KEY (Id_cliente)                  REFERENCES Cliente(Id_cliente),
    CONSTRAINT FK_Res_Categoria         FOREIGN KEY (Id_categoria)                REFERENCES Categoria(Id_categoria),
    CONSTRAINT FK_Res_Patio_Retirada    FOREIGN KEY (Id_patio_previsto_retirada)  REFERENCES Patio(Id_patio),
    CONSTRAINT FK_Res_Patio_Devolucao   FOREIGN KEY (Id_patio_previsto_devolucao) REFERENCES Patio(Id_patio)
);

CREATE TABLE Reserva_acessorio (
    Id_reserva      INT     NOT NULL,
    Id_acessorio    INT     NOT NULL,

    CONSTRAINT PK_Reserva_acessorio PRIMARY KEY (Id_reserva, Id_acessorio),
    CONSTRAINT FK_RA_Reserva        FOREIGN KEY (Id_reserva)   REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_RA_Acessorio      FOREIGN KEY (Id_acessorio) REFERENCES Acessorio(Id_acessorio)
);

CREATE TABLE Reserva_protecao (
    Id_reserva      INT     NOT NULL,
    Id_protecao     INT     NOT NULL,

    CONSTRAINT PK_Reserva_protecao  PRIMARY KEY (Id_reserva, Id_protecao),
    CONSTRAINT FK_RP_Reserva        FOREIGN KEY (Id_reserva)  REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_RP_Protecao       FOREIGN KEY (Id_protecao) REFERENCES Protecao_seguro(Id_protecao)
);

CREATE TABLE Locacao (
    Id_locacao                  INT             NOT NULL AUTO_INCREMENT,
    Id_reserva                  INT             NOT NULL,
    Id_veiculo                  INT             NOT NULL,
    Id_motorista                INT             NOT NULL,
    Id_patio_real_retirada      INT             NOT NULL,
    Id_patio_real_devolucao     INT             NOT NULL,
    Data_hora_retirada_real     DATETIME        NULL,
    Data_hora_devolucao_real    DATETIME        NULL,
    Estado_veiculo_retirada     TEXT            NULL,
    Estado_veiculo_devolucao    TEXT            NULL,
    Km_retirada                 INT             NULL,
    Km_devolucao                INT             NULL,
    Valor_total_final           DECIMAL(10,2)   NULL,
    Status_locacao              VARCHAR(30)     NULL,

    CONSTRAINT PK_Locacao               PRIMARY KEY (Id_locacao),
    CONSTRAINT UQ_Loc_Reserva           UNIQUE (Id_reserva),
    CONSTRAINT FK_Loc_Reserva           FOREIGN KEY (Id_reserva)              REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_Loc_Veiculo           FOREIGN KEY (Id_veiculo)              REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_Loc_Motorista         FOREIGN KEY (Id_motorista)            REFERENCES Motorista(Id_motorista),
    CONSTRAINT FK_Loc_Patio_Retirada    FOREIGN KEY (Id_patio_real_retirada)  REFERENCES Patio(Id_patio),
    CONSTRAINT FK_Loc_Patio_Devolucao   FOREIGN KEY (Id_patio_real_devolucao) REFERENCES Patio(Id_patio)
);

CREATE TABLE Locacao_protecao (
    Id_locacao      INT     NOT NULL,
    Id_protecao     INT     NOT NULL,

    CONSTRAINT PK_Locacao_protecao  PRIMARY KEY (Id_locacao, Id_protecao),
    CONSTRAINT FK_LP_Locacao        FOREIGN KEY (Id_locacao)  REFERENCES Locacao(Id_locacao),
    CONSTRAINT FK_LP_Protecao       FOREIGN KEY (Id_protecao) REFERENCES Protecao_seguro(Id_protecao)
);

CREATE TABLE Cobranca (
    Id_cobranca         INT             NOT NULL AUTO_INCREMENT,
    Id_locacao          INT             NOT NULL,
    Id_dados_cobranca   INT             NOT NULL,
    Valor_cobrado       DECIMAL(10,2)   NULL,
    Data_cobranca       DATETIME        NULL,
    Motivo_cobranca     VARCHAR(100)    NULL,
    Status_pagamento    VARCHAR(30)     NULL,

    CONSTRAINT PK_Cobranca      PRIMARY KEY (Id_cobranca),
    CONSTRAINT FK_Cob_Locacao   FOREIGN KEY (Id_locacao)        REFERENCES Locacao(Id_locacao),
    CONSTRAINT FK_Cob_Dados     FOREIGN KEY (Id_dados_cobranca) REFERENCES Dados_cobranca(Id_dados_cobranca)
);

CREATE TABLE Foto (
    Id_foto         INT             NOT NULL AUTO_INCREMENT,
    Id_veiculo      INT             NOT NULL,
    Id_locacao      INT             NULL,       -- Permite NULL caso a foto seja só de propaganda/catálogo
    Url_imagem      VARCHAR(255)    NULL,
    Finalidade_foto VARCHAR(50)     NULL,
    Data_registro   DATETIME        NULL,

    CONSTRAINT PK_Foto          PRIMARY KEY (Id_foto),
    CONSTRAINT FK_Foto_Veiculo  FOREIGN KEY (Id_veiculo) REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_Foto_Locacao  FOREIGN KEY (Id_locacao) REFERENCES Locacao(Id_locacao)
);