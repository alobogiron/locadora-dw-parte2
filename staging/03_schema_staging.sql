-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: staging/03_schema_staging.sql
--  Objetivo: DDL da area staging (tabelas intermediarias para ETL).
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Conteudo:
--    - Schema staging
--    - 7 tabelas stg_*: patio, grupo, veiculo, cliente, reserva, locacao,
--      movimentacao_patio
--    - Cada linha carrega sk_fonte (origem) + id_natural (chave na origem)
--      + colunas semanticas (tipos liberais TEXT/VARCHAR) + nome_canonico
--      (preenchido na fase Transform) + data_carga (auditoria).
-- =====================================================================

DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;

SET search_path = staging;


-- ---------------------------------------------------------------------
-- stg_patio
-- ---------------------------------------------------------------------
CREATE TABLE stg_patio (
    sk_fonte         INTEGER      NOT NULL,
    id_natural       TEXT         NOT NULL,
    nome_original    VARCHAR(200),
    endereco         VARCHAR(300),
    cidade           VARCHAR(100),
    tipo_local       VARCHAR(50),
    capacidade_vagas INTEGER,
    funciona_24h     BOOLEAN,
    -- Preenchido na fase Transform via depara_patio.
    nome_canonico    TEXT,
    data_carga       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_patio IS 'Patios extraidos das 5 fontes. nome_canonico vazio ate fase Transform.';


-- ---------------------------------------------------------------------
-- stg_grupo
-- ---------------------------------------------------------------------
CREATE TABLE stg_grupo (
    sk_fonte           INTEGER      NOT NULL,
    id_natural         TEXT         NOT NULL,
    codigo_origem      VARCHAR(50),
    nome_origem        VARCHAR(200),
    classe_luxo        VARCHAR(50),
    valor_diaria       NUMERIC(12,2),
    franquia_km_diaria INTEGER,
    descricao          VARCHAR(500),
    nome_canonico      TEXT,
    data_carga         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_grupo IS 'Grupos/categorias de veiculo extraidos das 5 fontes.';


-- ---------------------------------------------------------------------
-- stg_veiculo
-- ---------------------------------------------------------------------
CREATE TABLE stg_veiculo (
    sk_fonte           INTEGER      NOT NULL,
    id_natural         TEXT         NOT NULL,
    placa              VARCHAR(20),
    chassi             VARCHAR(50),
    renavam            VARCHAR(20),
    marca              VARCHAR(100),
    modelo             VARCHAR(100),
    cor                VARCHAR(50),
    ano_fabricacao     INTEGER,
    mecanizacao        VARCHAR(50),
    tem_ar_condicionado BOOLEAN,
    tem_cadeira_infantil BOOLEAN,
    capacidade_pessoas INTEGER,
    capacidade_porta_malas INTEGER,
    categoria_dimensoes VARCHAR(50),
    km_atual           INTEGER,
    situacao           VARCHAR(50),
    -- Chaves para resolucao de grupo/patio no Transform.
    grupo_id_natural   TEXT,
    patio_id_natural   TEXT,
    nome_canonico_grupo TEXT,
    nome_canonico_patio TEXT,
    data_carga         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_veiculo IS 'Frota das 5 fontes; FK para grupo/patio via id_natural para casamento no Transform.';


-- ---------------------------------------------------------------------
-- stg_cliente
-- ---------------------------------------------------------------------
CREATE TABLE stg_cliente (
    sk_fonte           INTEGER      NOT NULL,
    id_natural         TEXT         NOT NULL,
    tipo_pessoa        VARCHAR(10),
    nome               VARCHAR(200),
    nome_fantasia      VARCHAR(200),
    cidade_origem      VARCHAR(100),
    uf_origem          VARCHAR(2),
    email              VARCHAR(200),
    telefone           VARCHAR(40),
    cpf                VARCHAR(20),
    cnpj               VARCHAR(20),
    data_nascimento    DATE,
    flag_tem_condutor_associado BOOLEAN,
    data_carga         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_cliente IS 'Clientes (PF+PJ unificados) das 5 fontes. Sem dedup cross-fonte.';


-- ---------------------------------------------------------------------
-- stg_reserva
-- ---------------------------------------------------------------------
CREATE TABLE stg_reserva (
    sk_fonte                  INTEGER      NOT NULL,
    id_natural                TEXT         NOT NULL,
    cliente_id_natural        TEXT,
    grupo_id_natural          TEXT,
    patio_retirada_id_natural TEXT,
    patio_devolucao_id_natural TEXT,
    data_reserva              TIMESTAMP,
    data_retirada_prevista    TIMESTAMP,
    data_devolucao_prevista   TIMESTAMP,
    qtd_veiculos_solicitados  INTEGER,
    valor_previsto            NUMERIC(12,2),
    status_origem             VARCHAR(50),
    -- Preenchidos no Transform.
    status_normalizado        VARCHAR(30),
    nome_canonico_patio_retirada TEXT,
    nome_canonico_patio_devolucao TEXT,
    nome_canonico_grupo       TEXT,
    data_carga                TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_reserva IS 'Reservas das 5 fontes. Status normalizado para CONFIRMADA/EM_FILA_ESPERA/CANCELADA/CONCRETIZADA no Transform.';


-- ---------------------------------------------------------------------
-- stg_locacao
-- ---------------------------------------------------------------------
CREATE TABLE stg_locacao (
    sk_fonte                  INTEGER      NOT NULL,
    id_natural                TEXT         NOT NULL,
    numero_contrato           VARCHAR(50),
    reserva_id_natural        TEXT,
    cliente_id_natural        TEXT,
    veiculo_id_natural        TEXT,
    grupo_id_natural          TEXT,
    patio_retirada_id_natural TEXT,
    patio_devolucao_id_natural TEXT,
    data_retirada_real        TIMESTAMP,
    data_devolucao_real       TIMESTAMP,
    data_devolucao_prevista   TIMESTAMP,
    km_saida                  INTEGER,
    km_chegada                INTEGER,
    valor_diaria_aplicada     NUMERIC(12,2),
    valor_total_final         NUMERIC(12,2),
    status_origem             VARCHAR(50),
    -- Preenchidos no Transform.
    status_normalizado        VARCHAR(30),
    duracao_real_dias         INTEGER,
    km_rodados                INTEGER,
    nome_canonico_patio_retirada TEXT,
    nome_canonico_patio_devolucao TEXT,
    nome_canonico_grupo       TEXT,
    data_carga                TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_locacao IS 'Locacoes das 5 fontes. Status normalizado para EM_ANDAMENTO/CONCLUIDA/CANCELADA no Transform.';


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio
-- ---------------------------------------------------------------------
-- Apenas auxilia inspecao; o fato_patio_diario eh derivado das locacoes
-- (decisao D-09 do modelo dimensional). Mantida para auditoria/contexto.
CREATE TABLE stg_movimentacao_patio (
    sk_fonte                INTEGER      NOT NULL,
    id_natural              TEXT         NOT NULL,
    veiculo_id_natural      TEXT,
    patio_origem_id_natural TEXT,
    patio_destino_id_natural TEXT,
    data_movimentacao       TIMESTAMP,
    motivo                  VARCHAR(200),
    nome_canonico_origem    TEXT,
    nome_canonico_destino   TEXT,
    data_carga              TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (sk_fonte, id_natural)
);

COMMENT ON TABLE stg_movimentacao_patio IS 'Movimentacoes operacionais entre patios; auxiliar — fato_patio_diario eh derivado de fato_locacao (D-09).';


-- ---------------------------------------------------------------------
-- Indices na staging
-- ---------------------------------------------------------------------
CREATE INDEX ix_stg_patio_canonico    ON stg_patio(nome_canonico);
CREATE INDEX ix_stg_grupo_canonico    ON stg_grupo(nome_canonico);
CREATE INDEX ix_stg_veiculo_canonico  ON stg_veiculo(nome_canonico_grupo);
CREATE INDEX ix_stg_locacao_status    ON stg_locacao(status_normalizado);
CREATE INDEX ix_stg_reserva_status    ON stg_reserva(status_normalizado);
CREATE INDEX ix_stg_locacao_datas     ON stg_locacao(data_retirada_real, data_devolucao_real);

RESET search_path;

-- =====================================================================
-- Fim do arquivo: staging/03_schema_staging.sql
-- =====================================================================
