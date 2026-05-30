-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: dw/01_schema_dw.sql
--  Objetivo: DDL do esquema estrela do DW conforme contrato em
--            dimensional/modelo-dimensional.md.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Conteudo:
--    Schema dw
--    6 dimensoes conformadas:
--      dim_tempo, dim_patio, dim_veiculo, dim_grupo, dim_cliente, dim_fonte
--    3 fatos:
--      fato_locacao (transacao), fato_reserva (transacao), fato_patio_diario (snapshot periodico)
--
--  Convencao:
--    - sk_* = surrogate key via GENERATED ALWAYS AS IDENTITY (excepcao dim_tempo
--      cuja sk_tempo eh smart-key INTEGER YYYYMMDD).
--    - dim_fonte tem sk_fonte SMALLINT estavel (1..5) — vide enunciado.
--    - Linhas sentinela inseridas para suportar FKs orfas (D-10 do modelo).
--    - SCD tipo 1 em todas as dimensoes (D-04 do modelo).
--
--  Idempotente: DROP SCHEMA IF EXISTS dw CASCADE; CREATE SCHEMA dw.
-- =====================================================================

DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

SET search_path = dw;


-- =====================================================================
-- DIMENSIONS
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_tempo
--   Smart-key inteira YYYYMMDD. Populada pela funcao popular_dim_tempo()
--   em 02_dim_tempo_carga.sql. Sentinela sk_tempo = 19000101 (DATA_DESCONHECIDA).
-- ---------------------------------------------------------------------
CREATE TABLE dim_tempo (
    sk_tempo            INTEGER     PRIMARY KEY,
    data_completa       DATE,
    ano                 INTEGER     NOT NULL,
    semestre            INTEGER     NOT NULL,
    trimestre           INTEGER     NOT NULL,
    bimestre            INTEGER     NOT NULL,
    mes_numero          INTEGER     NOT NULL,
    mes_nome            VARCHAR(20) NOT NULL,
    mes_abreviado       VARCHAR(5)  NOT NULL,
    semana_ano          INTEGER     NOT NULL,
    dia_mes             INTEGER     NOT NULL,
    dia_ano             INTEGER     NOT NULL,
    dia_semana_numero   INTEGER     NOT NULL,
    dia_semana_nome     VARCHAR(20) NOT NULL,
    eh_fim_de_semana    BOOLEAN     NOT NULL,
    eh_feriado_nacional BOOLEAN     NOT NULL DEFAULT FALSE,
    descricao_periodo   VARCHAR(40)
);

COMMENT ON TABLE  dim_tempo IS 'Dimensao tempo conformada (grao: dia). Smart-key YYYYMMDD. Sentinela sk_tempo=19000101 = DATA_DESCONHECIDA.';
COMMENT ON COLUMN dim_tempo.sk_tempo IS 'Smart-key inteira YYYYMMDD; -1 reservado para data desconhecida/nao aplicavel.';


-- ---------------------------------------------------------------------
-- dim_patio
-- ---------------------------------------------------------------------
CREATE TABLE dim_patio (
    sk_patio                     INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_canonico                VARCHAR(80) NOT NULL UNIQUE,
    apelido                      VARCHAR(40) NOT NULL,
    tipo_local                   VARCHAR(20) NOT NULL CHECK (tipo_local IN ('AEROPORTO','RODOVIARIA','SHOPPING','DESCONHECIDO')),
    cidade                       VARCHAR(80) NOT NULL,
    endereco_descritivo          VARCHAR(200),
    capacidade_vagas_referencia  INTEGER,
    flag_funciona_24h            BOOLEAN     NOT NULL DEFAULT FALSE,
    codigo_fonte_dona            VARCHAR(30)              -- codigo_fonte da empresa associada dona deste patio; NULL p/ Barra (P-07: sexta empresa sem sistema)
);

COMMENT ON TABLE  dim_patio IS 'Dimensao patio conformada. 6 patios canonicos + 1 sentinela (PATIO_DESCONHECIDO).';
COMMENT ON COLUMN dim_patio.nome_canonico IS 'Chave natural conformada (UNIQUE) — usada pelo ETL para lookup.';
COMMENT ON COLUMN dim_patio.codigo_fonte_dona IS 'Empresa associada dona deste patio (foreign key logico para dim_fonte.codigo_fonte). Habilita calculo de fato_patio_diario.flag_frota_propria_no_patio. NULL para Barra Shopping (sexta empresa sem sistema-fonte, P-07).';


-- ---------------------------------------------------------------------
-- dim_veiculo
-- ---------------------------------------------------------------------
CREATE TABLE dim_veiculo (
    sk_veiculo               INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sk_fonte_origem          SMALLINT    NOT NULL,
    id_natural_origem        TEXT        NOT NULL,
    placa                    VARCHAR(20),
    chassi                   VARCHAR(50),
    renavam                  VARCHAR(20),
    marca                    VARCHAR(60),
    modelo                   VARCHAR(60),
    cor                      VARCHAR(30),
    ano_fabricacao           INTEGER,
    mecanizacao              VARCHAR(20) NOT NULL DEFAULT 'DESCONHECIDA'
                             CHECK (mecanizacao IN ('MANUAL','AUTOMATICA','DESCONHECIDA')),
    tem_ar_condicionado      BOOLEAN,
    tem_adaptacao_cadeirante BOOLEAN,
    capacidade_pessoas       INTEGER,
    capacidade_porta_malas   INTEGER,
    categoria_dimensoes      VARCHAR(40),
    situacao_atual           VARCHAR(20) NOT NULL DEFAULT 'DESCONHECIDA'
                             CHECK (situacao_atual IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO','RESERVADO','DESCONHECIDA')),
    CONSTRAINT uq_dim_veiculo_origem UNIQUE (sk_fonte_origem, id_natural_origem)
);

COMMENT ON TABLE dim_veiculo IS 'Dimensao veiculo conformada. Chave natural composta (sk_fonte_origem, id_natural_origem) — sem dedup cross-fonte (D-03 do modelo).';


-- ---------------------------------------------------------------------
-- dim_grupo
-- ---------------------------------------------------------------------
CREATE TABLE dim_grupo (
    sk_grupo                       INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_grupo_normalizado         VARCHAR(40)   NOT NULL UNIQUE,
    codigo_curto                   VARCHAR(10),
    classe_luxo                    VARCHAR(20)   NOT NULL DEFAULT 'DESCONHECIDA'
                                   CHECK (classe_luxo IN ('LUXO','INTERMEDIARIO','ECONOMICO','DESCONHECIDA')),
    valor_diaria_referencia        NUMERIC(10,2),
    franquia_km_diaria_referencia  INTEGER,
    descricao                      VARCHAR(300)
);

COMMENT ON TABLE dim_grupo IS 'Dimensao grupo/categoria conformada. nome_grupo_normalizado eh a chave natural.';


-- ---------------------------------------------------------------------
-- dim_cliente
-- ---------------------------------------------------------------------
CREATE TABLE dim_cliente (
    sk_cliente                  INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sk_fonte_origem             SMALLINT    NOT NULL,
    id_natural_origem           TEXT        NOT NULL,
    tipo_pessoa                 VARCHAR(2)  NOT NULL DEFAULT 'PF' CHECK (tipo_pessoa IN ('PF','PJ')),
    nome                        VARCHAR(200) NOT NULL,
    nome_fantasia               VARCHAR(200),
    cidade_origem               VARCHAR(80)  NOT NULL DEFAULT 'DESCONHECIDA',
    uf_origem                   VARCHAR(2),
    email                       VARCHAR(200),
    telefone                    VARCHAR(40),
    cpf_normalizado             VARCHAR(11),
    cnpj_normalizado            VARCHAR(14),
    flag_eh_pessoa_juridica     BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_dim_cliente_origem UNIQUE (sk_fonte_origem, id_natural_origem)
);

COMMENT ON TABLE  dim_cliente IS 'Dimensao cliente conformada. Chave natural composta — sem dedup cross-fonte (D-03 do modelo).';
COMMENT ON COLUMN dim_cliente.cidade_origem IS 'Default DESCONHECIDA quando a fonte nao expoe (vide §5.3 do modelo). Sem dedup cross-fonte.';
COMMENT ON COLUMN dim_cliente.flag_eh_pessoa_juridica IS 'TRUE quando tipo_pessoa=PJ. Substitui antiga flag_tem_condutor_associado (LEVE-01 da revisao).';


-- ---------------------------------------------------------------------
-- dim_fonte
-- ---------------------------------------------------------------------
CREATE TABLE dim_fonte (
    sk_fonte                SMALLINT    PRIMARY KEY,
    codigo_fonte            VARCHAR(30) NOT NULL UNIQUE,
    nome_empresa_associada  VARCHAR(100) NOT NULL,
    sgbd_original           VARCHAR(20) NOT NULL,
    descricao               VARCHAR(300)
);

COMMENT ON TABLE dim_fonte IS 'Dimensao fonte conformada. 5 fontes + 1 sentinela (sk_fonte=0). sk_fonte explicita (nao IDENTITY) por ser estavel pela convencao do projeto.';


-- =====================================================================
-- FATOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- fato_locacao (Transaction Fact Table)
-- Grao: uma linha por locacao registrada em qualquer fonte.
-- Role-playing: dim_tempo (3 papeis), dim_patio (2 papeis).
-- ---------------------------------------------------------------------
CREATE TABLE fato_locacao (
    sk_locacao                  INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Chaves estrangeiras (dimensionais)
    sk_tempo_retirada_real      INTEGER       NOT NULL,
    sk_tempo_devolucao_real     INTEGER,        -- NULL se EM_ANDAMENTO (evento ainda nao ocorreu — MOD-02)
    sk_tempo_devolucao_prevista INTEGER       NOT NULL,
    sk_patio_retirada           INTEGER       NOT NULL,
    sk_patio_devolucao          INTEGER,        -- NULL se EM_ANDAMENTO (MOD-05 — sempre o REAL quando ocorrido)
    sk_veiculo                  INTEGER       NOT NULL,
    sk_grupo                    INTEGER       NOT NULL,
    sk_cliente                  INTEGER       NOT NULL,
    sk_fonte                    SMALLINT      NOT NULL,

    -- Degenerate dimensions
    id_locacao_origem           BIGINT        NOT NULL,        -- PK numerica na fonte; auditoria reversa (MOD-04)
    numero_contrato_fonte       VARCHAR(50),                   -- so andre_gustavo expoe; NULL em 4/5 fontes
    status_locacao              VARCHAR(20)   NOT NULL
                                CHECK (status_locacao IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA','DESCONHECIDO')),

    -- Metricas
    qtd_locacoes                INTEGER       NOT NULL DEFAULT 1 CHECK (qtd_locacoes = 1),
    duracao_prevista_dias       INTEGER,
    duracao_real_dias           INTEGER,
    km_rodados                  INTEGER,
    valor_diaria_aplicada       NUMERIC(12,2),
    valor_total_estimado        NUMERIC(12,2),
    valor_total_final           NUMERIC(12,2),

    -- Identificador de carga (auditoria)
    sk_fonte_id_natural         TEXT          NOT NULL,
    data_carga_dw               TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_floc_tempo_ret_real   FOREIGN KEY (sk_tempo_retirada_real)      REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_floc_tempo_dev_real   FOREIGN KEY (sk_tempo_devolucao_real)     REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_floc_tempo_dev_prev   FOREIGN KEY (sk_tempo_devolucao_prevista) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_floc_patio_retirada   FOREIGN KEY (sk_patio_retirada)           REFERENCES dim_patio(sk_patio),
    CONSTRAINT fk_floc_patio_devolucao  FOREIGN KEY (sk_patio_devolucao)          REFERENCES dim_patio(sk_patio),
    CONSTRAINT fk_floc_veiculo          FOREIGN KEY (sk_veiculo)                  REFERENCES dim_veiculo(sk_veiculo),
    CONSTRAINT fk_floc_grupo            FOREIGN KEY (sk_grupo)                    REFERENCES dim_grupo(sk_grupo),
    CONSTRAINT fk_floc_cliente          FOREIGN KEY (sk_cliente)                  REFERENCES dim_cliente(sk_cliente),
    CONSTRAINT fk_floc_fonte            FOREIGN KEY (sk_fonte)                    REFERENCES dim_fonte(sk_fonte),
    CONSTRAINT uq_floc_origem           UNIQUE (sk_fonte, sk_fonte_id_natural)
);

COMMENT ON TABLE  fato_locacao IS 'Fato de transacao: uma linha por contrato de locacao. Role-playing em dim_tempo (3) e dim_patio (2).';
COMMENT ON COLUMN fato_locacao.sk_tempo_devolucao_real IS 'NULL para locacoes EM_ANDAMENTO ou CANCELADA sem devolucao. MOD-02: NULL preserva "ainda nao ocorreu"; sentinela 19000101 reservada para "dado perdido".';
COMMENT ON COLUMN fato_locacao.sk_patio_devolucao IS 'Role-playing dim_patio AS dim_patio_devolucao. MOD-05: SEMPRE o REAL quando a fonte distingue previsto vs realizado. NULL se EM_ANDAMENTO. Input da matriz de Markov.';
COMMENT ON COLUMN fato_locacao.sk_patio_retirada IS 'Role-playing: dim_patio AS dim_patio_retirada.';
COMMENT ON COLUMN fato_locacao.id_locacao_origem IS 'PK numerica da locacao no sistema-fonte. Habilita auditoria reversa em 5/5 fontes (MOD-04).';


-- ---------------------------------------------------------------------
-- fato_reserva (Transaction Fact Table)
-- Grao: uma linha por reserva registrada em qualquer fonte.
-- ---------------------------------------------------------------------
CREATE TABLE fato_reserva (
    sk_reserva                  INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    sk_tempo_reserva            INTEGER       NOT NULL,
    sk_tempo_retirada_prevista  INTEGER       NOT NULL,
    sk_tempo_devolucao_prevista INTEGER       NOT NULL,
    sk_patio_retirada           INTEGER       NOT NULL,
    sk_patio_devolucao          INTEGER       NOT NULL,
    sk_grupo                    INTEGER       NOT NULL,
    sk_cliente                  INTEGER       NOT NULL,
    sk_fonte                    SMALLINT      NOT NULL,

    -- Degenerate dimensions
    id_reserva_origem           BIGINT        NOT NULL,        -- PK numerica na fonte; auditoria reversa em 5/5 fontes
    status_reserva              VARCHAR(30)   NOT NULL
                                CHECK (status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CANCELADA','CONCRETIZADA','DESCONHECIDO')),

    qtd_reservas                INTEGER       NOT NULL DEFAULT 1 CHECK (qtd_reservas = 1),
    qtd_veiculos_solicitados    INTEGER       NOT NULL DEFAULT 1 CHECK (qtd_veiculos_solicitados >= 1),
    duracao_prevista_dias       INTEGER,
    dias_antecedencia           INTEGER,
    valor_previsto              NUMERIC(12,2),

    sk_fonte_id_natural         TEXT          NOT NULL,
    data_carga_dw               TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fres_tempo_reserva    FOREIGN KEY (sk_tempo_reserva)            REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fres_tempo_ret_prev   FOREIGN KEY (sk_tempo_retirada_prevista)  REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fres_tempo_dev_prev   FOREIGN KEY (sk_tempo_devolucao_prevista) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fres_patio_retirada   FOREIGN KEY (sk_patio_retirada)           REFERENCES dim_patio(sk_patio),
    CONSTRAINT fk_fres_patio_devolucao  FOREIGN KEY (sk_patio_devolucao)          REFERENCES dim_patio(sk_patio),
    CONSTRAINT fk_fres_grupo            FOREIGN KEY (sk_grupo)                    REFERENCES dim_grupo(sk_grupo),
    CONSTRAINT fk_fres_cliente          FOREIGN KEY (sk_cliente)                  REFERENCES dim_cliente(sk_cliente),
    CONSTRAINT fk_fres_fonte            FOREIGN KEY (sk_fonte)                    REFERENCES dim_fonte(sk_fonte),
    CONSTRAINT uq_fres_origem           UNIQUE (sk_fonte, sk_fonte_id_natural)
);

COMMENT ON TABLE  fato_reserva IS 'Fato de transacao: uma linha por reserva. Sem sk_veiculo (reserva eh por grupo, nao por veiculo — P-05 do modelo).';
COMMENT ON COLUMN fato_reserva.sk_grupo IS 'Para reservas da fonte bigdata aponta para sk_grupo=0 (sentinela GRUPO_NAO_INFORMADO — vide CRITICO-04 e P-10).';
COMMENT ON COLUMN fato_reserva.id_reserva_origem IS 'PK numerica da reserva na fonte. Auditoria reversa em 5/5 fontes.';


-- ---------------------------------------------------------------------
-- fato_patio_diario (Periodic Snapshot Fact Table) — v1.1 pos-revisao
-- Grao: UMA LINHA POR VEICULO POR DIA (corrigido: CRITICO-01 e CRITICO-02
-- pediam grao inequivoco que habilitasse corte por marca/modelo/mecanizacao).
-- Inclui sk_veiculo; metrica unica qtd_veiculos=1; pivot eh feito na consulta.
-- ---------------------------------------------------------------------
CREATE TABLE fato_patio_diario (
    sk_patio_diario              INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    sk_tempo                     INTEGER     NOT NULL,
    sk_patio                     INTEGER     NOT NULL,
    sk_veiculo                   INTEGER     NOT NULL,        -- NOVO (CRITICO-01): habilita corte por marca/modelo
    sk_grupo                     INTEGER     NOT NULL,        -- desnormalizado a partir de dim_veiculo
    sk_fonte                     SMALLINT    NOT NULL,

    -- Atributos degenerados no fato
    situacao                     VARCHAR(15) NOT NULL
                                 CHECK (situacao IN ('DISPONIVEL','ALUGADO','MANUTENCAO','RESERVADO')),
    flag_frota_propria_no_patio  BOOLEAN     NOT NULL DEFAULT FALSE,

    -- Metrica unica (semi-aditiva no tempo, aditiva nas demais)
    qtd_veiculos                 INTEGER     NOT NULL DEFAULT 1 CHECK (qtd_veiculos = 1),

    -- Atributo de pátio replicado (acelera relatorio a sem JOIN extra)
    capacidade_vagas_patio       INTEGER,

    data_carga_dw                TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fpd_tempo    FOREIGN KEY (sk_tempo)   REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fpd_patio    FOREIGN KEY (sk_patio)   REFERENCES dim_patio(sk_patio),
    CONSTRAINT fk_fpd_veiculo  FOREIGN KEY (sk_veiculo) REFERENCES dim_veiculo(sk_veiculo),
    CONSTRAINT fk_fpd_grupo    FOREIGN KEY (sk_grupo)   REFERENCES dim_grupo(sk_grupo),
    CONSTRAINT fk_fpd_fonte    FOREIGN KEY (sk_fonte)   REFERENCES dim_fonte(sk_fonte),
    CONSTRAINT uq_fpd_grain    UNIQUE (sk_tempo, sk_veiculo)        -- grao = 1 veiculo x 1 dia
);

COMMENT ON TABLE  fato_patio_diario IS 'Fato de snapshot periodico. Grao: UMA LINHA POR VEICULO POR DIA (v1.1). Habilita relatorio (a) com corte por marca/modelo/mecanizacao via JOIN com dim_veiculo.';
COMMENT ON COLUMN fato_patio_diario.qtd_veiculos IS 'Metrica unica fixa=1. Semi-aditiva no tempo (somar entre dias conta o mesmo veiculo varias vezes); aditiva nas demais dimensoes (somar entre patios/grupos/veiculos eh natural).';
COMMENT ON COLUMN fato_patio_diario.situacao IS 'Atributo degenerado. Pivot em colunas via COUNT(*) FILTER (WHERE situacao=X) na consulta — mais flexivel que pre-agregar.';
COMMENT ON COLUMN fato_patio_diario.flag_frota_propria_no_patio IS 'TRUE quando sk_fonte do veiculo coincide com a fonte dona do patio. Habilita relatorio (a) "frota da empresa dona vs associadas" sem JOIN adicional.';


-- =====================================================================
-- INDICES (FKs do fato — performance de drill across)
-- =====================================================================

CREATE INDEX ix_floc_tempo_ret_real ON fato_locacao(sk_tempo_retirada_real);
CREATE INDEX ix_floc_tempo_dev_real ON fato_locacao(sk_tempo_devolucao_real);
CREATE INDEX ix_floc_patio_ret     ON fato_locacao(sk_patio_retirada);
CREATE INDEX ix_floc_patio_dev     ON fato_locacao(sk_patio_devolucao);
CREATE INDEX ix_floc_veiculo       ON fato_locacao(sk_veiculo);
CREATE INDEX ix_floc_grupo         ON fato_locacao(sk_grupo);
CREATE INDEX ix_floc_cliente       ON fato_locacao(sk_cliente);
CREATE INDEX ix_floc_fonte         ON fato_locacao(sk_fonte);
CREATE INDEX ix_floc_status        ON fato_locacao(status_locacao);

CREATE INDEX ix_fres_tempo_res     ON fato_reserva(sk_tempo_reserva);
CREATE INDEX ix_fres_tempo_ret_p   ON fato_reserva(sk_tempo_retirada_prevista);
CREATE INDEX ix_fres_patio_ret     ON fato_reserva(sk_patio_retirada);
CREATE INDEX ix_fres_grupo         ON fato_reserva(sk_grupo);
CREATE INDEX ix_fres_cliente       ON fato_reserva(sk_cliente);
CREATE INDEX ix_fres_fonte         ON fato_reserva(sk_fonte);
CREATE INDEX ix_fres_status        ON fato_reserva(status_reserva);

CREATE INDEX ix_fpd_tempo          ON fato_patio_diario(sk_tempo);
CREATE INDEX ix_fpd_patio          ON fato_patio_diario(sk_patio);
CREATE INDEX ix_fpd_veiculo        ON fato_patio_diario(sk_veiculo);
CREATE INDEX ix_fpd_grupo          ON fato_patio_diario(sk_grupo);
CREATE INDEX ix_fpd_fonte          ON fato_patio_diario(sk_fonte);
CREATE INDEX ix_fpd_situacao       ON fato_patio_diario(situacao);


-- =====================================================================
-- SENTINELAS (D-10 revisado)
-- =====================================================================
-- dim_tempo sentinela vai em 02_dim_tempo_carga.sql.

-- dim_fonte sentinela (sk_fonte = 0)
INSERT INTO dim_fonte (sk_fonte, codigo_fonte, nome_empresa_associada, sgbd_original, descricao) VALUES
  (0, 'FONTE_DESCONHECIDA', 'Fonte desconhecida (sentinela)', 'N/A', 'Linha sentinela para registros sem fonte identificada.');

-- dim_grupo sentinela (sk_grupo = 0) — CRITICO-04 / P-10
-- Destino das reservas da bigdata (que nao expoe IDCategoria) e outras
-- linhas-fonte sem grupo recuperavel.
INSERT INTO dim_grupo (sk_grupo, nome_grupo_normalizado, codigo_curto, classe_luxo, valor_diaria_referencia, franquia_km_diaria_referencia, descricao)
OVERRIDING SYSTEM VALUE
VALUES
  (0, 'GRUPO_NAO_INFORMADO', NULL, 'DESCONHECIDA', NULL, NULL, 'Sentinela: linha destino das reservas da fonte bigdata (que nao modela IDCategoria em Reserva). Vide P-10 do modelo dimensional.');

-- dim_patio sentinela (sk_patio = 0)
INSERT INTO dim_patio (sk_patio, nome_canonico, apelido, tipo_local, cidade, endereco_descritivo, capacidade_vagas_referencia, flag_funciona_24h, codigo_fonte_dona)
OVERRIDING SYSTEM VALUE
VALUES
  (0, 'PATIO_DESCONHECIDO', 'Desconhecido', 'DESCONHECIDO', 'N/A', NULL, NULL, FALSE, NULL);


RESET search_path;

-- =====================================================================
-- Fim do arquivo: dw/01_schema_dw.sql
-- =====================================================================
