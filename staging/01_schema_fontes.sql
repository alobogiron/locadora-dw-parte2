-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: staging/01_schema_fontes.sql
--  Objetivo: DDL das 5 fontes OLTP em schemas Postgres separados.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Conteudo:
--    1. CREATE SCHEMA src_andre_gustavo  — Parte I do proprio grupo (Postgres)
--    2. CREATE SCHEMA src_mae016         — Breno, Hygor, Joao (MySQL -> Postgres)
--    3. CREATE SCHEMA src_locadora_db    — Tadeu, Vicente (Postgres)
--    4. CREATE SCHEMA src_bd_dw_26_1     — Ana, Mariana, Matheus, Paulo, Pedro, Ryan (MySQL -> Postgres)
--    5. CREATE SCHEMA src_bigdata        — bigdata (ANSI -> Postgres)
--
--  Idempotente: DROP SCHEMA IF EXISTS ... CASCADE no inicio.
--  Nomes de tabelas/colunas preservados conforme as DDLs originais.
-- =====================================================================

DROP SCHEMA IF EXISTS src_andre_gustavo CASCADE;
DROP SCHEMA IF EXISTS src_mae016        CASCADE;
DROP SCHEMA IF EXISTS src_locadora_db   CASCADE;
DROP SCHEMA IF EXISTS src_bd_dw_26_1    CASCADE;
DROP SCHEMA IF EXISTS src_bigdata       CASCADE;

CREATE SCHEMA src_andre_gustavo;
CREATE SCHEMA src_mae016;
CREATE SCHEMA src_locadora_db;
CREATE SCHEMA src_bd_dw_26_1;
CREATE SCHEMA src_bigdata;


-- =====================================================================
-- 1. SCHEMA src_andre_gustavo
--    Fonte: locadora-dw-parte1 (Postgres original do proprio grupo).
--    Reproduz integralmente o schema.sql da Parte I (Gustavo + Andre).
-- =====================================================================

SET search_path = src_andre_gustavo;

CREATE TABLE patio (
    id_patio          SERIAL       PRIMARY KEY,
    nome              VARCHAR(100) NOT NULL,
    endereco          VARCHAR(200) NOT NULL,
    capacidade_vagas  INTEGER      NOT NULL CHECK (capacidade_vagas >= 0)
);

CREATE TABLE vaga (
    patio_id  INTEGER     NOT NULL REFERENCES patio(id_patio) ON DELETE CASCADE,
    codigo    VARCHAR(20) NOT NULL,
    setor     VARCHAR(30),
    ocupada   BOOLEAN     NOT NULL DEFAULT FALSE,
    PRIMARY KEY (patio_id, codigo)
);

CREATE TABLE grupo (
    id_grupo            SERIAL        PRIMARY KEY,
    codigo              VARCHAR(10)   NOT NULL UNIQUE,
    nome                VARCHAR(50)   NOT NULL,
    classe_luxo         VARCHAR(20)   NOT NULL,
    valor_diaria        NUMERIC(10,2) NOT NULL CHECK (valor_diaria >= 0),
    franquia_km_diaria  INTEGER       NOT NULL CHECK (franquia_km_diaria >= 0)
);

CREATE TABLE veiculo (
    id_veiculo           SERIAL        PRIMARY KEY,
    grupo_id             INTEGER       NOT NULL REFERENCES grupo(id_grupo) ON DELETE RESTRICT,
    patio_origem_id      INTEGER       NOT NULL REFERENCES patio(id_patio) ON DELETE RESTRICT,
    placa                VARCHAR(8)    NOT NULL UNIQUE,
    chassi               VARCHAR(17)   NOT NULL UNIQUE,
    renavam              VARCHAR(11)   NOT NULL UNIQUE,
    marca                VARCHAR(30)   NOT NULL,
    modelo               VARCHAR(50)   NOT NULL,
    cor                  VARCHAR(20)   NOT NULL,
    ano_fabricacao       INTEGER       NOT NULL,
    mecanizacao          VARCHAR(10)   NOT NULL CHECK (mecanizacao IN ('MANUAL','AUTOMATICA')),
    tem_ar_condicionado  BOOLEAN       NOT NULL DEFAULT TRUE,
    km_atual             INTEGER       NOT NULL CHECK (km_atual >= 0),
    situacao             VARCHAR(15)   NOT NULL CHECK (situacao IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO'))
);

CREATE TABLE cliente (
    id_cliente      SERIAL       PRIMARY KEY,
    tipo_pessoa     VARCHAR(2)   NOT NULL CHECK (tipo_pessoa IN ('PF','PJ')),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    cidade_origem   VARCHAR(80)  NOT NULL,
    data_cadastro   DATE         NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE cliente_pf (
    cliente_id       INTEGER     PRIMARY KEY REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    cpf              VARCHAR(11) NOT NULL UNIQUE,
    rg               VARCHAR(15),
    data_nascimento  DATE        NOT NULL,
    cnh_numero       VARCHAR(15) NOT NULL UNIQUE,
    cnh_categoria    VARCHAR(2)  NOT NULL CHECK (cnh_categoria IN ('A','B','AB','C','AC','D','AD','E','AE')),
    cnh_validade     DATE        NOT NULL
);

CREATE TABLE cliente_pj (
    cliente_id       INTEGER      PRIMARY KEY REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    cnpj             VARCHAR(14)  NOT NULL UNIQUE,
    nome_fantasia    VARCHAR(150),
    responsavel      VARCHAR(150) NOT NULL
);

CREATE TABLE condutor (
    cliente_pj_id  INTEGER      NOT NULL REFERENCES cliente_pj(cliente_id) ON DELETE CASCADE,
    cpf            VARCHAR(11)  NOT NULL,
    nome           VARCHAR(150) NOT NULL,
    cnh_numero     VARCHAR(15)  NOT NULL UNIQUE,
    cnh_categoria  VARCHAR(2)   NOT NULL CHECK (cnh_categoria IN ('A','B','AB','C','AC','D','AD','E','AE')),
    cnh_validade   DATE         NOT NULL,
    PRIMARY KEY (cliente_pj_id, cpf)
);

CREATE TABLE reserva (
    id_reserva               SERIAL    PRIMARY KEY,
    cliente_id               INTEGER   NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    grupo_id                 INTEGER   NOT NULL REFERENCES grupo(id_grupo) ON DELETE RESTRICT,
    patio_retirada_id        INTEGER   NOT NULL REFERENCES patio(id_patio) ON DELETE RESTRICT,
    patio_devolucao_id       INTEGER   NOT NULL REFERENCES patio(id_patio) ON DELETE RESTRICT,
    data_reserva             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_retirada_prevista   TIMESTAMP NOT NULL,
    data_devolucao_prevista  TIMESTAMP NOT NULL,
    estado                   VARCHAR(20) NOT NULL CHECK (estado IN ('CONFIRMADA','EM_FILA_ESPERA','CANCELADA','CONCRETIZADA')),
    CHECK (data_devolucao_prevista > data_retirada_prevista)
);

CREATE TABLE locacao (
    id_locacao             SERIAL        PRIMARY KEY,
    numero_contrato        VARCHAR(30)   NOT NULL UNIQUE,
    reserva_id             INTEGER       UNIQUE REFERENCES reserva(id_reserva) ON DELETE RESTRICT,
    cliente_id             INTEGER       NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    veiculo_id             INTEGER       NOT NULL REFERENCES veiculo(id_veiculo) ON DELETE RESTRICT,
    patio_retirada_id      INTEGER       NOT NULL REFERENCES patio(id_patio) ON DELETE RESTRICT,
    patio_devolucao_id     INTEGER       NOT NULL REFERENCES patio(id_patio) ON DELETE RESTRICT,
    data_retirada_real     TIMESTAMP     NOT NULL,
    data_devolucao_real    TIMESTAMP,
    km_saida               INTEGER       NOT NULL CHECK (km_saida >= 0),
    km_chegada             INTEGER       CHECK (km_chegada IS NULL OR km_chegada >= km_saida),
    valor_diaria_aplicada  NUMERIC(10,2) NOT NULL CHECK (valor_diaria_aplicada >= 0),
    status                 VARCHAR(15)   NOT NULL CHECK (status IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA')),
    CHECK (data_devolucao_real IS NULL OR data_devolucao_real > data_retirada_real)
);

-- R03: um veiculo so pode ter uma locacao EM_ANDAMENTO por vez.
CREATE UNIQUE INDEX uq_locacao_veiculo_em_andamento
    ON locacao (veiculo_id)
    WHERE status = 'EM_ANDAMENTO';

CREATE TABLE cobranca (
    id_cobranca   SERIAL        PRIMARY KEY,
    locacao_id    INTEGER       NOT NULL REFERENCES locacao(id_locacao) ON DELETE RESTRICT,
    data_emissao  DATE          NOT NULL DEFAULT CURRENT_DATE,
    valor_total   NUMERIC(10,2) NOT NULL CHECK (valor_total >= 0),
    status        VARCHAR(15)   NOT NULL CHECK (status IN ('PENDENTE','PAGA','CANCELADA'))
);

CREATE INDEX ix_veiculo_grupo          ON veiculo(grupo_id);
CREATE INDEX ix_veiculo_situacao       ON veiculo(situacao);
CREATE INDEX ix_reserva_cliente        ON reserva(cliente_id);
CREATE INDEX ix_reserva_grupo_estado   ON reserva(grupo_id, estado);
CREATE INDEX ix_locacao_cliente        ON locacao(cliente_id);
CREATE INDEX ix_locacao_veiculo_status ON locacao(veiculo_id, status);
CREATE INDEX ix_cobranca_locacao       ON cobranca(locacao_id);


-- =====================================================================
-- 2. SCHEMA src_mae016
--    Fonte original: MySQL (Breno, Hygor, Joao).
--    Conversoes mecanicas: INT->INTEGER, TINYINT(1)->BOOLEAN, DATETIME->TIMESTAMP,
--                          CHAR_LENGTH()->LENGTH(), nomes em UPPERCASE preservados.
--    Constraints originalmente em arquivo separado foram inseridas no DDL.
-- =====================================================================

SET search_path = src_mae016;

CREATE TABLE EMPRESA (
    id_empresa   INTEGER PRIMARY KEY,
    nome_empresa VARCHAR(100) NOT NULL
);

CREATE TABLE PATIO (
    id_patio     INTEGER PRIMARY KEY,
    id_empresa   INTEGER NOT NULL,
    nome_patio   VARCHAR(100) NOT NULL,
    localizacao  VARCHAR(150) NOT NULL,
    codigo_patio VARCHAR(20)  NOT NULL UNIQUE,
    CONSTRAINT fk_patio_empresa FOREIGN KEY (id_empresa) REFERENCES EMPRESA (id_empresa)
);

CREATE TABLE GRUPO_VEICULO (
    id_grupo           INTEGER PRIMARY KEY,
    nome_grupo         VARCHAR(50)  NOT NULL,
    descricao          VARCHAR(200),
    faixa_valor_diaria DECIMAL(10,2) NOT NULL,
    CONSTRAINT ck_grupo_valor_diaria CHECK (faixa_valor_diaria > 0)
);

CREATE TABLE CLIENTE (
    id_cliente        INTEGER PRIMARY KEY,
    tipo_cliente      VARCHAR(2)   NOT NULL,
    nome_razao_social VARCHAR(150) NOT NULL,
    cpf_cnpj          VARCHAR(20)  NOT NULL,
    cidade            VARCHAR(50)  NOT NULL,
    estado            VARCHAR(2)   NOT NULL,
    telefone          VARCHAR(20),
    email             VARCHAR(100),
    CONSTRAINT uq_cliente_cpf_cnpj UNIQUE (cpf_cnpj),
    CONSTRAINT ck_cliente_tipo CHECK (tipo_cliente IN ('PF', 'PJ')),
    -- Original MySQL: CHAR_LENGTH(estado) = 2 -> Postgres: LENGTH(estado) = 2
    CONSTRAINT ck_cliente_estado CHECK (LENGTH(estado) = 2)
);

CREATE TABLE CONDUTOR (
    id_condutor   INTEGER PRIMARY KEY,
    nome_condutor VARCHAR(150) NOT NULL,
    cpf           VARCHAR(20)  NOT NULL,
    numero_cnh    VARCHAR(20)  NOT NULL,
    categoria_cnh VARCHAR(5)   NOT NULL,
    validade_cnh  DATE         NOT NULL,
    id_cliente    INTEGER      NOT NULL,
    CONSTRAINT fk_condutor_cliente   FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT uq_condutor_cpf       UNIQUE (cpf),
    CONSTRAINT uq_condutor_numero_cnh UNIQUE (numero_cnh)
    -- Original MySQL: CHECK (validade_cnh >= CURRENT_DATE) — relaxado no seed (dados sinteticos passados/futuros).
);

CREATE TABLE VEICULO (
    id_veiculo      INTEGER PRIMARY KEY,
    placa           VARCHAR(10) NOT NULL,
    chassi          VARCHAR(50) NOT NULL,
    marca           VARCHAR(50) NOT NULL,
    modelo          VARCHAR(50) NOT NULL,
    cor             VARCHAR(30) NOT NULL,
    mecanizacao     VARCHAR(20) NOT NULL,
    -- Original MySQL: TINYINT(1) -> Postgres: BOOLEAN
    ar_condicionado BOOLEAN     NOT NULL,
    status          VARCHAR(20) NOT NULL,
    id_grupo        INTEGER     NOT NULL,
    id_empresa      INTEGER     NOT NULL,
    id_patio_atual  INTEGER     NOT NULL,
    CONSTRAINT fk_veiculo_grupo       FOREIGN KEY (id_grupo)       REFERENCES GRUPO_VEICULO (id_grupo),
    CONSTRAINT fk_veiculo_empresa     FOREIGN KEY (id_empresa)     REFERENCES EMPRESA (id_empresa),
    CONSTRAINT fk_veiculo_patio_atual FOREIGN KEY (id_patio_atual) REFERENCES PATIO (id_patio),
    CONSTRAINT uq_veiculo_placa       UNIQUE (placa),
    CONSTRAINT uq_veiculo_chassi      UNIQUE (chassi),
    CONSTRAINT ck_veiculo_mecanizacao CHECK (mecanizacao IN ('MANUAL', 'AUTOMATICO')),
    CONSTRAINT ck_veiculo_status      CHECK (status IN ('DISPONIVEL', 'ALUGADO', 'MANUTENCAO', 'RESERVADO'))
);

CREATE TABLE RESERVA (
    id_reserva                  INTEGER PRIMARY KEY,
    data_reserva                DATE NOT NULL,
    data_prev_retirada          DATE NOT NULL,
    data_prev_devolucao         DATE NOT NULL,
    status_reserva              VARCHAR(20) NOT NULL,
    id_cliente                  INTEGER NOT NULL,
    id_grupo                    INTEGER NOT NULL,
    id_patio_retirada           INTEGER NOT NULL,
    id_patio_devolucao_previsto INTEGER NOT NULL,
    CONSTRAINT fk_reserva_cliente            FOREIGN KEY (id_cliente)                  REFERENCES CLIENTE (id_cliente),
    CONSTRAINT fk_reserva_grupo              FOREIGN KEY (id_grupo)                    REFERENCES GRUPO_VEICULO (id_grupo),
    CONSTRAINT fk_reserva_patio_retirada     FOREIGN KEY (id_patio_retirada)           REFERENCES PATIO (id_patio),
    CONSTRAINT fk_reserva_patio_devolucao_prev FOREIGN KEY (id_patio_devolucao_previsto) REFERENCES PATIO (id_patio),
    CONSTRAINT ck_reserva_status        CHECK (status_reserva IN ('ATIVA', 'CANCELADA', 'CONVERTIDA')),
    CONSTRAINT ck_reserva_datas         CHECK (data_prev_devolucao >= data_prev_retirada),
    CONSTRAINT ck_reserva_data_registro CHECK (data_reserva <= data_prev_retirada)
);

CREATE TABLE LOCACAO (
    id_locacao                  INTEGER PRIMARY KEY,
    data_hora_retirada          TIMESTAMP NOT NULL,
    data_hora_prev_devolucao    TIMESTAMP NOT NULL,
    data_hora_real_devolucao    TIMESTAMP,
    valor_previsto              DECIMAL(10,2) NOT NULL,
    valor_final                 DECIMAL(10,2),
    status_locacao              VARCHAR(20) NOT NULL,
    id_reserva                  INTEGER,
    id_cliente                  INTEGER NOT NULL,
    id_condutor                 INTEGER NOT NULL,
    id_veiculo                  INTEGER NOT NULL,
    id_patio_retirada           INTEGER NOT NULL,
    id_patio_devolucao_previsto INTEGER NOT NULL,
    id_patio_devolucao_real     INTEGER,
    CONSTRAINT fk_locacao_reserva              FOREIGN KEY (id_reserva)                  REFERENCES RESERVA (id_reserva),
    CONSTRAINT fk_locacao_cliente              FOREIGN KEY (id_cliente)                  REFERENCES CLIENTE (id_cliente),
    CONSTRAINT fk_locacao_condutor             FOREIGN KEY (id_condutor)                 REFERENCES CONDUTOR (id_condutor),
    CONSTRAINT fk_locacao_veiculo              FOREIGN KEY (id_veiculo)                  REFERENCES VEICULO (id_veiculo),
    CONSTRAINT fk_locacao_patio_retirada       FOREIGN KEY (id_patio_retirada)           REFERENCES PATIO (id_patio),
    CONSTRAINT fk_locacao_patio_devolucao_prev FOREIGN KEY (id_patio_devolucao_previsto) REFERENCES PATIO (id_patio),
    CONSTRAINT fk_locacao_patio_devolucao_real FOREIGN KEY (id_patio_devolucao_real)     REFERENCES PATIO (id_patio),
    CONSTRAINT ck_locacao_status          CHECK (status_locacao IN ('ATIVA', 'FINALIZADA', 'CANCELADA')),
    CONSTRAINT ck_locacao_valor_previsto  CHECK (valor_previsto > 0),
    CONSTRAINT ck_locacao_valor_final     CHECK (valor_final IS NULL OR valor_final >= 0),
    CONSTRAINT ck_locacao_datas_previstas CHECK (data_hora_prev_devolucao >= data_hora_retirada),
    CONSTRAINT ck_locacao_data_real       CHECK (data_hora_real_devolucao IS NULL OR data_hora_real_devolucao >= data_hora_retirada)
);

CREATE TABLE PAGAMENTO (
    id_pagamento    INTEGER PRIMARY KEY,
    data_pagamento  DATE NOT NULL,
    valor_pagamento DECIMAL(10,2) NOT NULL,
    forma_pagamento VARCHAR(20) NOT NULL,
    tipo_pagamento  VARCHAR(20) NOT NULL,
    id_locacao      INTEGER NOT NULL,
    CONSTRAINT fk_pagamento_locacao FOREIGN KEY (id_locacao) REFERENCES LOCACAO (id_locacao),
    CONSTRAINT ck_pagamento_valor CHECK (valor_pagamento > 0),
    CONSTRAINT ck_pagamento_forma CHECK (forma_pagamento IN ('DINHEIRO', 'CARTAO', 'PIX', 'BOLETO')),
    CONSTRAINT ck_pagamento_tipo  CHECK (tipo_pagamento  IN ('ENTRADA', 'PARCIAL', 'FINAL'))
);

CREATE TABLE MOVIMENTACAO_PATIO (
    id_movimentacao        INTEGER PRIMARY KEY,
    -- Original MySQL: DATETIME -> Postgres: TIMESTAMP
    data_hora_movimentacao TIMESTAMP NOT NULL,
    motivo_movimentacao    VARCHAR(100) NOT NULL,
    id_veiculo             INTEGER NOT NULL,
    id_patio_origem        INTEGER NOT NULL,
    id_patio_destino       INTEGER NOT NULL,
    CONSTRAINT fk_movimentacao_veiculo       FOREIGN KEY (id_veiculo)       REFERENCES VEICULO (id_veiculo),
    CONSTRAINT fk_movimentacao_patio_origem  FOREIGN KEY (id_patio_origem)  REFERENCES PATIO (id_patio),
    CONSTRAINT fk_movimentacao_patio_destino FOREIGN KEY (id_patio_destino) REFERENCES PATIO (id_patio),
    CONSTRAINT ck_movimentacao_patio_diferente CHECK (id_patio_origem <> id_patio_destino)
);


-- =====================================================================
-- 3. SCHEMA src_locadora_db
--    Fonte original: Postgres (Tadeu, Vicente). Replicada com adaptacao
--    minima (created_at TIMESTAMP DEFAULT now() preservado).
-- =====================================================================

SET search_path = src_locadora_db;

CREATE TABLE empresa_locadora (
    id   SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cnpj VARCHAR(20)  NOT NULL UNIQUE
);

CREATE TABLE cliente (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    tipo   VARCHAR(2)   NOT NULL CHECK (tipo IN ('PF','PJ')),
    cidade VARCHAR(50)  NOT NULL
);

CREATE TABLE condutor (
    id         SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    nome       VARCHAR(100) NOT NULL,
    cnh        VARCHAR(20)  NOT NULL UNIQUE,
    validade   DATE         NOT NULL,
    categoria  VARCHAR(5)   NOT NULL,
    telefone   VARCHAR(20),
    FOREIGN KEY (cliente_id) REFERENCES cliente(id) ON DELETE RESTRICT
);

CREATE TABLE grupo_veiculo (
    id        SERIAL PRIMARY KEY,
    nome      VARCHAR(50) NOT NULL,
    categoria VARCHAR(50) NOT NULL
);

CREATE TABLE patio (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL
);

-- ---------------------------------------------------------------------
-- EXTENSAO DE INTEGRACAO (vide modelo-dimensional.md, P-09):
-- A fonte original `locadora-db` NAO modela amarracao veiculo-->patio
-- (a tabela `vaga` so registra status livre/ocupada sem FK para veiculo).
-- Para suportar `dw.fato_patio_diario` (grao: 1 veiculo x 1 dia), adicionamos
-- a coluna `id_patio_origem INTEGER REFERENCES patio(id)` em `veiculo`.
-- A coluna eh populada no seed (`staging/02_seed_fontes.sql`) com a atribuicao
-- inicial de cada veiculo ao patio da sua empresa proprietaria.
-- Nao inventa regra de negocio nova: apenas materializa relacao implicita
-- (veiculo esta em pátio) que a fonte original deixou nao-modelada.
-- ---------------------------------------------------------------------
CREATE TABLE veiculo (
    id                  SERIAL PRIMARY KEY,
    placa               VARCHAR(10) NOT NULL UNIQUE,
    chassi              VARCHAR(30) NOT NULL UNIQUE,
    modelo              VARCHAR(50) NOT NULL,
    marca               VARCHAR(50) NOT NULL,
    cor                 VARCHAR(30) NOT NULL,
    tipo_mecanizacao    VARCHAR(20) NOT NULL CHECK (tipo_mecanizacao IN ('manual','automatico')),
    ar_condicionado     BOOLEAN     NOT NULL DEFAULT FALSE,
    status              VARCHAR(20) NOT NULL DEFAULT 'disponivel' CHECK (status IN ('disponivel','alugado','manutencao')),
    adaptado_cadeirante BOOLEAN     NOT NULL DEFAULT FALSE,
    grupo_id            INTEGER     NOT NULL,
    empresa_id          INTEGER     NOT NULL,
    id_patio_origem     INTEGER     NOT NULL,  -- EXTENSAO DE INTEGRACAO (P-09)
    FOREIGN KEY (grupo_id)        REFERENCES grupo_veiculo(id)    ON DELETE RESTRICT,
    FOREIGN KEY (empresa_id)      REFERENCES empresa_locadora(id) ON DELETE RESTRICT,
    FOREIGN KEY (id_patio_origem) REFERENCES patio(id)            ON DELETE RESTRICT
);

CREATE TABLE acessorio (
    id   SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE veiculo_acessorio (
    veiculo_id   INTEGER NOT NULL,
    acessorio_id INTEGER NOT NULL,
    PRIMARY KEY (veiculo_id, acessorio_id),
    FOREIGN KEY (veiculo_id)   REFERENCES veiculo(id)   ON DELETE CASCADE,
    FOREIGN KEY (acessorio_id) REFERENCES acessorio(id) ON DELETE CASCADE
);

CREATE TABLE vaga (
    codigo   VARCHAR(10) NOT NULL,
    patio_id INTEGER NOT NULL,
    status   VARCHAR(20) NOT NULL DEFAULT 'livre' CHECK (status IN ('livre','ocupada')),
    PRIMARY KEY (codigo, patio_id),
    FOREIGN KEY (patio_id) REFERENCES patio(id) ON DELETE CASCADE
);

CREATE TABLE reserva (
    id                 SERIAL PRIMARY KEY,
    cliente_id         INTEGER NOT NULL,
    grupo_id           INTEGER NOT NULL,
    patio_retirada_id  INTEGER NOT NULL,
    patio_devolucao_id INTEGER NOT NULL,
    data_inicio        DATE NOT NULL,
    data_fim           DATE NOT NULL,
    status             VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa','confirmada','cancelada','espera')),
    FOREIGN KEY (cliente_id)         REFERENCES cliente(id)        ON DELETE RESTRICT,
    FOREIGN KEY (grupo_id)           REFERENCES grupo_veiculo(id)  ON DELETE RESTRICT,
    FOREIGN KEY (patio_retirada_id)  REFERENCES patio(id)          ON DELETE RESTRICT,
    FOREIGN KEY (patio_devolucao_id) REFERENCES patio(id)          ON DELETE RESTRICT,
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE locacao (
    id                       SERIAL PRIMARY KEY,
    reserva_id               INTEGER UNIQUE,
    veiculo_id               INTEGER NOT NULL,
    condutor_id              INTEGER NOT NULL,
    patio_retirada_id        INTEGER NOT NULL,
    patio_devolucao_id       INTEGER NOT NULL,
    data_retirada_prevista   TIMESTAMP NOT NULL,
    data_retirada_realizada  TIMESTAMP,
    data_devolucao_prevista  TIMESTAMP NOT NULL,
    data_devolucao_realizada TIMESTAMP,
    estado_entrega           TEXT,
    estado_devolucao         TEXT,
    km_entrega               INTEGER,
    km_devolucao             INTEGER,
    created_at               TIMESTAMP NOT NULL DEFAULT now(),
    updated_at               TIMESTAMP,
    FOREIGN KEY (reserva_id)         REFERENCES reserva(id)   ON DELETE SET NULL,
    FOREIGN KEY (veiculo_id)         REFERENCES veiculo(id)   ON DELETE RESTRICT,
    FOREIGN KEY (condutor_id)        REFERENCES condutor(id)  ON DELETE RESTRICT,
    FOREIGN KEY (patio_retirada_id)  REFERENCES patio(id)     ON DELETE RESTRICT,
    FOREIGN KEY (patio_devolucao_id) REFERENCES patio(id)     ON DELETE RESTRICT,
    CHECK (
        data_devolucao_realizada IS NULL
        OR (data_retirada_realizada IS NOT NULL AND data_devolucao_realizada >= data_retirada_realizada)
    ),
    CHECK (
        data_retirada_realizada IS NULL
        OR (km_entrega IS NOT NULL AND km_entrega >= 0)
    ),
    CHECK (
        data_devolucao_realizada IS NULL
        OR (km_devolucao IS NOT NULL AND km_devolucao >= 0)
    ),
    CHECK (data_devolucao_prevista >= data_retirada_prevista)
);

CREATE TABLE cobranca (
    id             SERIAL PRIMARY KEY,
    locacao_id     INTEGER UNIQUE,
    valor          DECIMAL(10,2) NOT NULL CHECK (valor >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','pago','cancelado')),
    data_pagamento DATE,
    FOREIGN KEY (locacao_id) REFERENCES locacao(id) ON DELETE SET NULL
);

CREATE TABLE seguro (
    id    SERIAL PRIMARY KEY,
    tipo  VARCHAR(50) NOT NULL,
    valor DECIMAL(10,2) NOT NULL CHECK (valor >= 0)
);

CREATE TABLE locacao_seguro (
    locacao_id INTEGER NOT NULL,
    seguro_id  INTEGER NOT NULL,
    PRIMARY KEY (locacao_id, seguro_id),
    FOREIGN KEY (locacao_id) REFERENCES locacao(id) ON DELETE CASCADE,
    FOREIGN KEY (seguro_id)  REFERENCES seguro(id)  ON DELETE RESTRICT
);

CREATE TABLE foto (
    id         SERIAL PRIMARY KEY,
    veiculo_id INTEGER NOT NULL,
    url        TEXT NOT NULL,
    tipo       VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    FOREIGN KEY (veiculo_id) REFERENCES veiculo(id) ON DELETE CASCADE
);

CREATE TABLE manutencao (
    id         SERIAL PRIMARY KEY,
    veiculo_id INTEGER NOT NULL,
    data       DATE   NOT NULL,
    descricao  TEXT   NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    FOREIGN KEY (veiculo_id) REFERENCES veiculo(id) ON DELETE CASCADE
);

CREATE TABLE movimentacao_patio (
    id                SERIAL PRIMARY KEY,
    veiculo_id        INTEGER NOT NULL,
    origem_patio_id   INTEGER NOT NULL,
    destino_patio_id  INTEGER NOT NULL,
    data_movimentacao TIMESTAMP NOT NULL DEFAULT now(),
    motivo            VARCHAR(100),
    FOREIGN KEY (veiculo_id)       REFERENCES veiculo(id) ON DELETE RESTRICT,
    FOREIGN KEY (origem_patio_id)  REFERENCES patio(id)   ON DELETE RESTRICT,
    FOREIGN KEY (destino_patio_id) REFERENCES patio(id)   ON DELETE RESTRICT,
    CHECK (origem_patio_id <> destino_patio_id)
);

CREATE INDEX idx_veiculo_grupo            ON veiculo(grupo_id);
CREATE INDEX idx_veiculo_empresa          ON veiculo(empresa_id);
CREATE INDEX idx_reserva_periodo          ON reserva(grupo_id, data_inicio, data_fim);
CREATE INDEX idx_reserva_patio_retirada   ON reserva(patio_retirada_id, data_inicio);
CREATE INDEX idx_locacao_devolucao        ON locacao(patio_devolucao_id, data_devolucao_realizada);
CREATE INDEX idx_locacao_veiculo_retirada ON locacao(veiculo_id, data_retirada_realizada);


-- =====================================================================
-- 4. SCHEMA src_bd_dw_26_1
--    Fonte original: MySQL (Ana, Mariana, Matheus, Paulo, Pedro, Ryan).
--    Conversoes mecanicas:
--      INT NOT NULL AUTO_INCREMENT -> INTEGER GENERATED ALWAYS AS IDENTITY
--      TINYINT(1) -> BOOLEAN
--      DATETIME -> TIMESTAMP
--      DROP DATABASE / CREATE DATABASE / USE ... -> removidos.
--    Preservei CapsCase original (Id_patio, Nome_patio, etc.).
-- =====================================================================

SET search_path = src_bd_dw_26_1;

CREATE TABLE Endereco (
    Id_endereco INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Uf          CHAR(2),
    Cep         VARCHAR(8),
    Cidade      VARCHAR(100),
    Bairro      VARCHAR(100),
    Logradouro  VARCHAR(150),
    Numero      VARCHAR(20),
    Complemento VARCHAR(100),
    CONSTRAINT PK_Endereco PRIMARY KEY (Id_endereco)
);

CREATE TABLE Empresa (
    Id_empresa   INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_endereco  INTEGER NOT NULL,
    Nome_empresa VARCHAR(100),
    Cnpj_empresa VARCHAR(14),
    CONSTRAINT PK_Empresa      PRIMARY KEY (Id_empresa),
    CONSTRAINT FK_Emp_Endereco FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

CREATE TABLE Patio (
    Id_patio        INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_empresa      INTEGER NOT NULL,
    Id_endereco     INTEGER NOT NULL,
    Nome_patio      VARCHAR(100),
    Capacidade      INTEGER,
    Hora_abertura   TIME,
    Hora_fechamento TIME,
    -- Original MySQL: TINYINT(1) -> Postgres: BOOLEAN
    Funciona_24h    BOOLEAN,
    CONSTRAINT PK_Patio        PRIMARY KEY (Id_patio),
    CONSTRAINT FK_Pat_Empresa  FOREIGN KEY (Id_empresa)  REFERENCES Empresa(Id_empresa),
    CONSTRAINT FK_Pat_Endereco FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

CREATE TABLE Vaga (
    Id_vaga                INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_patio               INTEGER NOT NULL,
    Codigo_vaga            VARCHAR(20),
    Status_disponibilidade VARCHAR(20),
    CONSTRAINT PK_Vaga      PRIMARY KEY (Id_vaga),
    CONSTRAINT FK_Vag_Patio FOREIGN KEY (Id_patio) REFERENCES Patio(Id_patio)
);

CREATE TABLE Categoria (
    Id_categoria        INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Nome_categoria      VARCHAR(50),
    Descricao_categoria TEXT,
    Valor_diaria_base   DECIMAL(10,2),
    CONSTRAINT PK_Categoria PRIMARY KEY (Id_categoria)
);

CREATE TABLE Veiculo (
    Id_veiculo             INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_empresa             INTEGER NOT NULL,
    Id_categoria           INTEGER NOT NULL,
    Id_vaga                INTEGER,
    Placa                  VARCHAR(7),
    Chassi                 VARCHAR(17),
    Marca                  VARCHAR(50),
    Modelo                 VARCHAR(50),
    Ano                    INTEGER,
    Cor                    VARCHAR(20),
    Tipo_cambio            VARCHAR(20),
    Possui_ar_condicionado BOOLEAN,
    Capacidade_pessoas     INTEGER,
    Capacidade_porta_malas INTEGER,
    Dimensoes              VARCHAR(50),
    Km_atual               INTEGER,
    Status_veiculo         VARCHAR(30),
    CONSTRAINT PK_Veiculo       PRIMARY KEY (Id_veiculo),
    CONSTRAINT UQ_Vaga          UNIQUE (Id_vaga),
    CONSTRAINT FK_Vei_Empresa   FOREIGN KEY (Id_empresa)   REFERENCES Empresa(Id_empresa),
    CONSTRAINT FK_Vei_Categoria FOREIGN KEY (Id_categoria) REFERENCES Categoria(Id_categoria),
    CONSTRAINT FK_Vei_Vaga      FOREIGN KEY (Id_vaga)      REFERENCES Vaga(Id_vaga)
);

CREATE TABLE Acessorio (
    Id_acessorio   INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Nome_acessorio VARCHAR(50),
    Tipo_acessorio VARCHAR(50),
    CONSTRAINT PK_Acessorio PRIMARY KEY (Id_acessorio)
);

CREATE TABLE Veiculo_acessorio (
    Id_veiculo   INTEGER NOT NULL,
    Id_acessorio INTEGER NOT NULL,
    CONSTRAINT PK_Veiculo_acessorio PRIMARY KEY (Id_veiculo, Id_acessorio),
    CONSTRAINT FK_VA_Veiculo   FOREIGN KEY (Id_veiculo)   REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_VA_Acessorio FOREIGN KEY (Id_acessorio) REFERENCES Acessorio(Id_acessorio)
);

CREATE TABLE Manutencao (
    Id_manutencao      INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_veiculo         INTEGER NOT NULL,
    Data_revisao       DATE,
    Estado_conservacao TEXT,
    Pressao_pneus      VARCHAR(20),
    Nivel_oleo         VARCHAR(20),
    Km_revisao         INTEGER,
    CONSTRAINT PK_Manutencao  PRIMARY KEY (Id_manutencao),
    CONSTRAINT FK_Man_Veiculo FOREIGN KEY (Id_veiculo) REFERENCES Veiculo(Id_veiculo)
);

CREATE TABLE Cliente (
    Id_cliente       INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_endereco      INTEGER NOT NULL,
    Tipo_cliente     CHAR(2),
    Email_cliente    VARCHAR(100),
    Telefone_cliente VARCHAR(20),
    CONSTRAINT PK_Cliente      PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_Cli_Endereco FOREIGN KEY (Id_endereco) REFERENCES Endereco(Id_endereco)
);

CREATE TABLE Cliente_pf (
    Id_cliente              INTEGER NOT NULL,
    Nome_cliente            VARCHAR(100),
    Cpf_cliente             VARCHAR(11),
    Data_nascimento_cliente DATE,
    Genero_cliente          CHAR(1),
    CONSTRAINT PK_Cliente_pf PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_PF_Cliente FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Cliente_pj (
    Id_cliente    INTEGER NOT NULL,
    Razao_social  VARCHAR(100),
    Nome_fantasia VARCHAR(100),
    Cnpj_cliente  VARCHAR(14),
    CONSTRAINT PK_Cliente_pj PRIMARY KEY (Id_cliente),
    CONSTRAINT FK_PJ_Cliente FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Motorista (
    Id_motorista              INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_cliente                INTEGER NOT NULL,
    Nome_motorista            VARCHAR(100),
    Numero_cnh                VARCHAR(20),
    Categoria_cnh             VARCHAR(3),
    Validade_cnh              DATE,
    Data_nascimento_motorista DATE,
    Email_motorista           VARCHAR(100),
    Telefone_motorista        VARCHAR(20),
    Genero_motorista          CHAR(1),
    Relacao_motorista_cliente VARCHAR(50),
    CONSTRAINT PK_Motorista   PRIMARY KEY (Id_motorista),
    CONSTRAINT FK_Mot_Cliente FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Dados_cobranca (
    Id_dados_cobranca   INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_cliente          INTEGER NOT NULL,
    Numero_cartao       VARCHAR(20),
    Nome_titular_cartao VARCHAR(100),
    Validade_cartao     VARCHAR(5),
    Cpf_titular_cartao  VARCHAR(11),
    CONSTRAINT PK_Dados_cobranca PRIMARY KEY (Id_dados_cobranca),
    CONSTRAINT FK_Dados_Cliente  FOREIGN KEY (Id_cliente) REFERENCES Cliente(Id_cliente)
);

CREATE TABLE Protecao_seguro (
    Id_protecao         INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Nome_protecao       VARCHAR(100),
    Descricao_cobertura TEXT,
    Valor_adicional     DECIMAL(10,2),
    CONSTRAINT PK_Protecao_seguro PRIMARY KEY (Id_protecao)
);

CREATE TABLE Reserva (
    Id_reserva                  INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_cliente                  INTEGER NOT NULL,
    Id_categoria                INTEGER NOT NULL,
    Id_patio_previsto_retirada  INTEGER NOT NULL,
    Id_patio_previsto_devolucao INTEGER NOT NULL,
    -- Original MySQL: DATETIME -> Postgres: TIMESTAMP
    Data_hora_reserva           TIMESTAMP,
    Data_previsao_retirada      TIMESTAMP,
    Data_previsao_devolucao     TIMESTAMP,
    Valor_previsto              DECIMAL(10,2),
    Status_reserva              VARCHAR(30),
    CONSTRAINT PK_Reserva             PRIMARY KEY (Id_reserva),
    CONSTRAINT FK_Res_Cliente         FOREIGN KEY (Id_cliente)                  REFERENCES Cliente(Id_cliente),
    CONSTRAINT FK_Res_Categoria       FOREIGN KEY (Id_categoria)                REFERENCES Categoria(Id_categoria),
    CONSTRAINT FK_Res_Patio_Retirada  FOREIGN KEY (Id_patio_previsto_retirada)  REFERENCES Patio(Id_patio),
    CONSTRAINT FK_Res_Patio_Devolucao FOREIGN KEY (Id_patio_previsto_devolucao) REFERENCES Patio(Id_patio)
);

CREATE TABLE Reserva_acessorio (
    Id_reserva   INTEGER NOT NULL,
    Id_acessorio INTEGER NOT NULL,
    CONSTRAINT PK_Reserva_acessorio PRIMARY KEY (Id_reserva, Id_acessorio),
    CONSTRAINT FK_RA_Reserva   FOREIGN KEY (Id_reserva)   REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_RA_Acessorio FOREIGN KEY (Id_acessorio) REFERENCES Acessorio(Id_acessorio)
);

CREATE TABLE Reserva_protecao (
    Id_reserva  INTEGER NOT NULL,
    Id_protecao INTEGER NOT NULL,
    CONSTRAINT PK_Reserva_protecao PRIMARY KEY (Id_reserva, Id_protecao),
    CONSTRAINT FK_RP_Reserva  FOREIGN KEY (Id_reserva)  REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_RP_Protecao FOREIGN KEY (Id_protecao) REFERENCES Protecao_seguro(Id_protecao)
);

CREATE TABLE Locacao (
    Id_locacao               INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_reserva               INTEGER NOT NULL,
    Id_veiculo               INTEGER NOT NULL,
    Id_motorista             INTEGER NOT NULL,
    Id_patio_real_retirada   INTEGER NOT NULL,
    Id_patio_real_devolucao  INTEGER NOT NULL,
    Data_hora_retirada_real  TIMESTAMP,
    Data_hora_devolucao_real TIMESTAMP,
    Estado_veiculo_retirada  TEXT,
    Estado_veiculo_devolucao TEXT,
    Km_retirada              INTEGER,
    Km_devolucao             INTEGER,
    Valor_total_final        DECIMAL(10,2),
    Status_locacao           VARCHAR(30),
    CONSTRAINT PK_Locacao             PRIMARY KEY (Id_locacao),
    CONSTRAINT UQ_Loc_Reserva         UNIQUE (Id_reserva),
    CONSTRAINT FK_Loc_Reserva         FOREIGN KEY (Id_reserva)              REFERENCES Reserva(Id_reserva),
    CONSTRAINT FK_Loc_Veiculo         FOREIGN KEY (Id_veiculo)              REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_Loc_Motorista       FOREIGN KEY (Id_motorista)            REFERENCES Motorista(Id_motorista),
    CONSTRAINT FK_Loc_Patio_Retirada  FOREIGN KEY (Id_patio_real_retirada)  REFERENCES Patio(Id_patio),
    CONSTRAINT FK_Loc_Patio_Devolucao FOREIGN KEY (Id_patio_real_devolucao) REFERENCES Patio(Id_patio)
);

CREATE TABLE Locacao_protecao (
    Id_locacao  INTEGER NOT NULL,
    Id_protecao INTEGER NOT NULL,
    CONSTRAINT PK_Locacao_protecao PRIMARY KEY (Id_locacao, Id_protecao),
    CONSTRAINT FK_LP_Locacao  FOREIGN KEY (Id_locacao)  REFERENCES Locacao(Id_locacao),
    CONSTRAINT FK_LP_Protecao FOREIGN KEY (Id_protecao) REFERENCES Protecao_seguro(Id_protecao)
);

CREATE TABLE Cobranca (
    Id_cobranca       INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_locacao        INTEGER NOT NULL,
    Id_dados_cobranca INTEGER NOT NULL,
    Valor_cobrado     DECIMAL(10,2),
    Data_cobranca     TIMESTAMP,
    Motivo_cobranca   VARCHAR(100),
    Status_pagamento  VARCHAR(30),
    CONSTRAINT PK_Cobranca    PRIMARY KEY (Id_cobranca),
    CONSTRAINT FK_Cob_Locacao FOREIGN KEY (Id_locacao)        REFERENCES Locacao(Id_locacao),
    CONSTRAINT FK_Cob_Dados   FOREIGN KEY (Id_dados_cobranca) REFERENCES Dados_cobranca(Id_dados_cobranca)
);

CREATE TABLE Foto (
    Id_foto         INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    Id_veiculo      INTEGER NOT NULL,
    Id_locacao      INTEGER,
    Url_imagem      VARCHAR(255),
    Finalidade_foto VARCHAR(50),
    Data_registro   TIMESTAMP,
    CONSTRAINT PK_Foto         PRIMARY KEY (Id_foto),
    CONSTRAINT FK_Foto_Veiculo FOREIGN KEY (Id_veiculo) REFERENCES Veiculo(Id_veiculo),
    CONSTRAINT FK_Foto_Locacao FOREIGN KEY (Id_locacao) REFERENCES Locacao(Id_locacao)
);


-- =====================================================================
-- 5. SCHEMA src_bigdata
--    Fonte original: ANSI (bigdata). Sem AUTO_INCREMENT no DDL original
--    (IDs explicitos no seed); preservado.
-- =====================================================================

SET search_path = src_bigdata;

CREATE TABLE Endereco (
    IDEndereco INTEGER NOT NULL,
    CEP        VARCHAR(8) NOT NULL,
    UF         CHAR(2) NOT NULL,
    Cidade     VARCHAR(100) NOT NULL,
    Bairro     VARCHAR(100) NOT NULL,
    Logradouro VARCHAR(255) NOT NULL,
    Numero     VARCHAR(10) NOT NULL,
    CONSTRAINT PK_Endereco PRIMARY KEY (IDEndereco),
    CONSTRAINT CHK_CEP CHECK (LENGTH(CEP) = 8),
    CONSTRAINT CHK_UF CHECK (UF IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO',
                                    'MA','MT','MS','MG','PA','PB','PR','PE','PI',
                                    'RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
);

CREATE TABLE Parceira (
    IDParceira INTEGER NOT NULL,
    CNPJ       VARCHAR(14) NOT NULL,
    Nome       VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Parceira       PRIMARY KEY (IDParceira),
    CONSTRAINT UQ_Parceira_CNPJ  UNIQUE (CNPJ)
);

CREATE TABLE Patio (
    IDPatio           INTEGER NOT NULL,
    CDPatio           VARCHAR(50) NOT NULL,
    Lotacao           INTEGER NOT NULL,
    HorarioAbertura   TIME NOT NULL,
    HorarioFechamento TIME NOT NULL,
    IDEndereco        INTEGER NOT NULL,
    IDParceira        INTEGER NOT NULL,
    CONSTRAINT PK_Patio          PRIMARY KEY (IDPatio),
    CONSTRAINT UQ_CodigoPatio    UNIQUE (CDPatio),
    CONSTRAINT CHK_Lotacao       CHECK (Lotacao > 0),
    CONSTRAINT FK_Patio_Endereco FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco),
    CONSTRAINT FK_Patio_Parceira FOREIGN KEY (IDParceira) REFERENCES Parceira(IDParceira),
    CONSTRAINT CHK_Horario       CHECK (HorarioFechamento > HorarioAbertura)
);

CREATE TABLE Vaga (
    IDVaga   INTEGER NOT NULL,
    CodVaga  VARCHAR(50) NOT NULL,
    Coberta  BOOLEAN NOT NULL,
    Andar    INTEGER,
    IDPatio  INTEGER NOT NULL,
    CONSTRAINT PK_Vaga       PRIMARY KEY (IDVaga),
    CONSTRAINT UQ_Vaga_Cod   UNIQUE (CodVaga),
    CONSTRAINT CHK_Andar     CHECK (Andar IS NULL OR Andar >= 0),
    CONSTRAINT FK_Vaga_Patio FOREIGN KEY (IDPatio) REFERENCES Patio(IDPatio)
);

CREATE TABLE Categoria (
    IDCategoria     INTEGER NOT NULL,
    Classificacao   VARCHAR(50) NOT NULL,
    ClasseLuxo      CHAR(1) NOT NULL,
    ValorDiariaBase DECIMAL(10,2) NOT NULL,
    Tracao4x4       BOOLEAN NOT NULL,
    CONSTRAINT PK_Categoria    PRIMARY KEY (IDCategoria),
    CONSTRAINT CHK_ClasseLuxo  CHECK (ClasseLuxo IN ('A', 'B', 'C')),
    CONSTRAINT CHK_ValorDiaria CHECK (ValorDiariaBase >= 0)
);

CREATE TABLE Veiculo (
    IDVeiculo          INTEGER NOT NULL,
    Placa              VARCHAR(10) NOT NULL,
    Chassi             VARCHAR(30) NOT NULL,
    Modelo             VARCHAR(100) NOT NULL,
    Ano                INTEGER NOT NULL,
    Altura             DECIMAL(5,2) NOT NULL,
    Largura            DECIMAL(5,2) NOT NULL,
    Portas             INTEGER NOT NULL,
    UltimaKilometragem INTEGER NOT NULL,
    ArCondicionado     BOOLEAN NOT NULL,
    CadeiraInfantil    BOOLEAN NOT NULL,
    BebeConforto       BOOLEAN NOT NULL,
    ValorDiaria        DECIMAL(10,2) NOT NULL,
    IDCategoria        INTEGER NOT NULL,
    CONSTRAINT PK_Veiculo           PRIMARY KEY (IDVeiculo),
    CONSTRAINT UQ_Veiculo_Placa     UNIQUE (Placa),
    CONSTRAINT UQ_Veiculo_Chassi    UNIQUE (Chassi),
    CONSTRAINT CHK_Ano              CHECK (Ano >= 1900),
    CONSTRAINT CHK_Portas           CHECK (Portas > 0),
    CONSTRAINT CHK_KM               CHECK (UltimaKilometragem >= 0),
    CONSTRAINT CHK_VeiculoValorDiar CHECK (ValorDiaria >= 0),
    CONSTRAINT CHK_Dimensoes        CHECK (Altura > 0 AND Largura > 0),
    CONSTRAINT FK_Veiculo_Categoria FOREIGN KEY (IDCategoria) REFERENCES Categoria(IDCategoria)
);

CREATE TABLE PessoaFisica (
    IDFisica     INTEGER NOT NULL,
    CPF          VARCHAR(11) NOT NULL,
    Nome         VARCHAR(255) NOT NULL,
    DtNascimento DATE NOT NULL,
    RG           VARCHAR(20) NOT NULL,
    Telefone     VARCHAR(20) NOT NULL,
    IDEndereco   INTEGER NOT NULL,
    CONSTRAINT PK_PessoaFisica          PRIMARY KEY (IDFisica),
    CONSTRAINT UQ_PessoaFisica_CPF      UNIQUE (CPF),
    CONSTRAINT CHK_CPF_Tamanho          CHECK (LENGTH(CPF) = 11),
    CONSTRAINT CHK_DataNascimento       CHECK (DtNascimento < CURRENT_DATE),
    CONSTRAINT FK_PessoaFisica_Endereco FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco)
);

CREATE TABLE Empresa (
    IDEmpresa   INTEGER NOT NULL,
    CNPJ        VARCHAR(14) NOT NULL,
    RazaoSocial VARCHAR(255) NOT NULL,
    DtAbertura  DATE NOT NULL,
    Telefone    VARCHAR(20) NOT NULL,
    IDEndereco  INTEGER NOT NULL,
    CONSTRAINT PK_Empresa          PRIMARY KEY (IDEmpresa),
    CONSTRAINT UQ_Empresa_CNPJ     UNIQUE (CNPJ),
    CONSTRAINT CHK_CNPJ_Tamanho    CHECK (LENGTH(CNPJ) = 14),
    CONSTRAINT FK_Empresa_Endereco FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco)
);

CREATE TABLE Motorista (
    IDMotorista  INTEGER NOT NULL,
    CNH          VARCHAR(20) NOT NULL,
    CategoriaCNH VARCHAR(5) NOT NULL,
    IDFisica     INTEGER NOT NULL,
    CONSTRAINT PK_Motorista              PRIMARY KEY (IDMotorista),
    CONSTRAINT UQ_Motorista_CNH          UNIQUE (CNH),
    CONSTRAINT UQ_Motorista_Fisica       UNIQUE (IDFisica),
    CONSTRAINT CHK_CategoriaCNH          CHECK (CategoriaCNH IN ('A', 'B', 'C', 'D', 'E', 'AB', 'AC', 'AD', 'AE')),
    CONSTRAINT FK_Motorista_PessoaFisica FOREIGN KEY (IDFisica) REFERENCES PessoaFisica(IDFisica)
);

CREATE TABLE CentroCusto (
    IDCentroCusto INTEGER NOT NULL,
    IDEmpresa     INTEGER,
    IDFisica      INTEGER,
    IDResponsavel INTEGER NOT NULL,
    CONSTRAINT PK_CentroCusto      PRIMARY KEY (IDCentroCusto),
    CONSTRAINT CHK_CentroCusto_Tipo CHECK (
        (IDEmpresa IS NOT NULL AND IDFisica IS NULL) OR
        (IDEmpresa IS NULL AND IDFisica IS NOT NULL)
    ),
    CONSTRAINT FK_CC_Empresa      FOREIGN KEY (IDEmpresa)     REFERENCES Empresa(IDEmpresa),
    CONSTRAINT FK_CC_Fisica       FOREIGN KEY (IDFisica)      REFERENCES PessoaFisica(IDFisica),
    CONSTRAINT FK_CC_Responsavel  FOREIGN KEY (IDResponsavel) REFERENCES PessoaFisica(IDFisica)
);

CREATE TABLE Movimentacao (
    IDMovimentacao INTEGER NOT NULL,
    DtChegada      TIMESTAMP NOT NULL,
    DtRetirada     TIMESTAMP NOT NULL,
    IDVeiculo      INTEGER NOT NULL,
    IDVagaOrigem   INTEGER NOT NULL,
    IDVagaDestino  INTEGER,
    CONSTRAINT PK_Movimentacao        PRIMARY KEY (IDMovimentacao),
    CONSTRAINT CHK_Movimentacao_Datas CHECK (DtChegada >= DtRetirada),
    CONSTRAINT FK_Mov_Veiculo         FOREIGN KEY (IDVeiculo)     REFERENCES Veiculo(IDVeiculo),
    CONSTRAINT FK_Mov_VagaOrigem      FOREIGN KEY (IDVagaOrigem)  REFERENCES Vaga(IDVaga),
    CONSTRAINT FK_Mov_VagaDestino     FOREIGN KEY (IDVagaDestino) REFERENCES Vaga(IDVaga)
);

CREATE TABLE Reserva (
    IDReserva             INTEGER NOT NULL,
    QtVeiculosSolicitados INTEGER NOT NULL,
    DtReserva             TIMESTAMP NOT NULL,
    DtRetiradaPrevista    TIMESTAMP NOT NULL,
    DtLimiteRetirada      TIMESTAMP NOT NULL,
    Status                VARCHAR(20) NOT NULL,
    IDCentroCusto         INTEGER NOT NULL,
    CONSTRAINT PK_Reserva             PRIMARY KEY (IDReserva),
    CONSTRAINT CHK_QtdVeiculos        CHECK (QtVeiculosSolicitados >= 1),
    CONSTRAINT CHK_DatasReserva       CHECK (DtLimiteRetirada > DtRetiradaPrevista),
    CONSTRAINT CHK_Status             CHECK (Status IN ('Confirmada', 'Cancelada', 'Atendida')),
    CONSTRAINT FK_Reserva_CentroCusto FOREIGN KEY (IDCentroCusto) REFERENCES CentroCusto(IDCentroCusto)
);

CREATE TABLE Locacao (
    IDLocacao       INTEGER NOT NULL,
    ValorDiaria     DECIMAL(10,2) NOT NULL,
    DtRetirada      TIMESTAMP NOT NULL,
    DtChegada       TIMESTAMP,
    IDVagaRetirada  INTEGER NOT NULL,
    IDVagaDevolvida INTEGER,
    IDVeiculo       INTEGER NOT NULL,
    IDReserva       INTEGER NOT NULL,
    IDMotorista     INTEGER NOT NULL,
    CONSTRAINT PK_Locacao              PRIMARY KEY (IDLocacao),
    CONSTRAINT CHK_LocValorDiaria      CHECK (ValorDiaria > 0),
    CONSTRAINT CHK_Datas               CHECK (DtChegada IS NULL OR DtChegada >= DtRetirada),
    CONSTRAINT FK_Locacao_VagaRetirada FOREIGN KEY (IDVagaRetirada)  REFERENCES Vaga(IDVaga),
    CONSTRAINT FK_Locacao_VagaDevolv   FOREIGN KEY (IDVagaDevolvida) REFERENCES Vaga(IDVaga),
    CONSTRAINT FK_Locacao_Veiculo      FOREIGN KEY (IDVeiculo)       REFERENCES Veiculo(IDVeiculo),
    CONSTRAINT FK_Locacao_Reserva      FOREIGN KEY (IDReserva)       REFERENCES Reserva(IDReserva),
    CONSTRAINT FK_Locacao_Motorista    FOREIGN KEY (IDMotorista)     REFERENCES Motorista(IDMotorista)
);

CREATE TABLE Prontuario (
    IDProntuario INTEGER NOT NULL,
    Operacao     VARCHAR(255) NOT NULL,
    Custo        DECIMAL(10,2) NOT NULL,
    IDEndereco   INTEGER NOT NULL,
    IDVeiculo    INTEGER NOT NULL,
    CONSTRAINT PK_Prontuario       PRIMARY KEY (IDProntuario),
    CONSTRAINT CHK_Custo           CHECK (Custo >= 0),
    CONSTRAINT FK_Prontuario_Ender FOREIGN KEY (IDEndereco) REFERENCES Endereco(IDEndereco),
    CONSTRAINT FK_Prontuario_Veic  FOREIGN KEY (IDVeiculo)  REFERENCES Veiculo(IDVeiculo)
);

CREATE TABLE Avaria (
    IDAvaria                INTEGER NOT NULL,
    DtRegistro              TIMESTAMP NOT NULL,
    Descricao               VARCHAR(500) NOT NULL,
    IDLocacao               INTEGER NOT NULL,
    IDVeiculo               INTEGER NOT NULL,
    IDProntuarioRelacionado INTEGER,
    CONSTRAINT PK_Avaria         PRIMARY KEY (IDAvaria),
    CONSTRAINT CHK_Avaria_Data   CHECK (DtRegistro <= CURRENT_TIMESTAMP),
    CONSTRAINT FK_Avaria_Locacao FOREIGN KEY (IDLocacao)               REFERENCES Locacao(IDLocacao),
    CONSTRAINT FK_Avaria_Veiculo FOREIGN KEY (IDVeiculo)               REFERENCES Veiculo(IDVeiculo),
    CONSTRAINT FK_Avaria_Pront   FOREIGN KEY (IDProntuarioRelacionado) REFERENCES Prontuario(IDProntuario)
);

-- Restaurar search_path padrao
RESET search_path;

-- =====================================================================
-- Fim do arquivo: staging/01_schema_fontes.sql
-- =====================================================================
