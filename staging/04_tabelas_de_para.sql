-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: staging/04_tabelas_de_para.sql
--  Objetivo: Tabelas de mapeamento (de-para) que reconciliam vocabularios
--            das 5 fontes para os nomes canonicos do DW.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Conteudo:
--    1. depara_patio  — mapeia (sk_fonte, id_natural_origem) -> nome_canonico
--    2. depara_grupo  — mapeia (sk_fonte, codigo_origem)     -> nome_canonico
--
--  Nomes canonicos:
--    Patios (6, conforme enunciado):
--      'Aeroporto do Galeao', 'Aeroporto Santos Dumont', 'Rodoviaria do Rio',
--      'Shopping Rio Sul',    'Shopping Nova America',   'Barra Shopping'.
--    Grupos:
--      'Economico', 'Intermediario', 'Executivo', 'SUV', 'Luxo'.
--
--  Idempotente: DROP TABLE IF EXISTS antes do CREATE; populacao via INSERT
--  (a tabela e zerada no DROP).
-- =====================================================================

DROP TABLE IF EXISTS staging.depara_patio;
DROP TABLE IF EXISTS staging.depara_grupo;

-- ---------------------------------------------------------------------
-- depara_patio
-- ---------------------------------------------------------------------
CREATE TABLE staging.depara_patio (
    sk_fonte          INTEGER     NOT NULL,
    id_natural_origem TEXT        NOT NULL,
    nome_original     TEXT        NOT NULL,
    nome_canonico     TEXT        NOT NULL,
    PRIMARY KEY (sk_fonte, id_natural_origem)
);

COMMENT ON TABLE staging.depara_patio IS
  'De-para de patios das 5 fontes para os 6 patios canonicos do enunciado.';


-- ---------------------------------------------------------------------
-- depara_grupo
-- ---------------------------------------------------------------------
CREATE TABLE staging.depara_grupo (
    sk_fonte      INTEGER     NOT NULL,
    codigo_origem TEXT        NOT NULL,
    nome_origem   TEXT,
    nome_canonico TEXT        NOT NULL,
    PRIMARY KEY (sk_fonte, codigo_origem)
);

COMMENT ON TABLE staging.depara_grupo IS
  'De-para de grupos/categorias das 5 fontes para nomes canonicos.';


-- =====================================================================
-- POPULACAO depara_patio
-- =====================================================================
--
-- Convencao de sk_fonte:
--   1 = src_andre_gustavo  (dona do Aeroporto do Galeao)
--   2 = src_mae016         (dona do Aeroporto Santos Dumont)
--   3 = src_locadora_db    (dona da Rodoviaria do Rio)
--   4 = src_bd_dw_26_1     (dona do Shopping Rio Sul)
--   5 = src_bigdata        (dona do Shopping Nova America)
-- ---------------------------------------------------------------------

INSERT INTO staging.depara_patio (sk_fonte, id_natural_origem, nome_original, nome_canonico) VALUES
  -- fonte 1 — src_andre_gustavo (patio.id_patio 1..6, na ordem que o seed inseriu)
  (1, '1', 'Aeroporto do Galeao',     'Aeroporto do Galeao'),
  (1, '2', 'Aeroporto Santos Dumont', 'Aeroporto Santos Dumont'),
  (1, '3', 'Rodoviaria do Rio',       'Rodoviaria do Rio'),
  (1, '4', 'Shopping Rio Sul',        'Shopping Rio Sul'),
  (1, '5', 'Shopping Nova America',   'Shopping Nova America'),
  (1, '6', 'Barra Shopping',          'Barra Shopping'),

  -- fonte 2 — src_mae016 (PATIO.id_patio 1..6)
  (2, '1', 'Aeroporto Santos Dumont', 'Aeroporto Santos Dumont'),
  (2, '2', 'Aeroporto do Galeao',     'Aeroporto do Galeao'),
  (2, '3', 'Rodoviaria do Rio',       'Rodoviaria do Rio'),
  (2, '4', 'Shopping Rio Sul',        'Shopping Rio Sul'),
  (2, '5', 'Shopping Nova America',   'Shopping Nova America'),
  (2, '6', 'Barra Shopping',          'Barra Shopping'),

  -- fonte 3 — src_locadora_db (patio.id 1..6, SERIAL na ordem de insert)
  (3, '1', 'Rodoviaria do Rio',       'Rodoviaria do Rio'),
  (3, '2', 'Aeroporto do Galeao',     'Aeroporto do Galeao'),
  (3, '3', 'Aeroporto Santos Dumont', 'Aeroporto Santos Dumont'),
  (3, '4', 'Shopping Rio Sul',        'Shopping Rio Sul'),
  (3, '5', 'Shopping Nova America',   'Shopping Nova America'),
  (3, '6', 'Barra Shopping',          'Barra Shopping'),

  -- fonte 4 — src_bd_dw_26_1 (Patio.Id_patio 1..6)
  (4, '1', 'Shopping Rio Sul',        'Shopping Rio Sul'),
  (4, '2', 'Aeroporto do Galeao',     'Aeroporto do Galeao'),
  (4, '3', 'Aeroporto Santos Dumont', 'Aeroporto Santos Dumont'),
  (4, '4', 'Rodoviaria do Rio',       'Rodoviaria do Rio'),
  (4, '5', 'Shopping Nova America',   'Shopping Nova America'),
  (4, '6', 'Barra Shopping',          'Barra Shopping'),

  -- fonte 5 — src_bigdata (Patio.IDPatio 1..6)
  (5, '1', 'Shopping Nova America',   'Shopping Nova America'),
  (5, '2', 'Aeroporto do Galeao',     'Aeroporto do Galeao'),
  (5, '3', 'Aeroporto Santos Dumont', 'Aeroporto Santos Dumont'),
  (5, '4', 'Rodoviaria do Rio',       'Rodoviaria do Rio'),
  (5, '5', 'Shopping Rio Sul',        'Shopping Rio Sul'),
  (5, '6', 'Barra Shopping',          'Barra Shopping');


-- =====================================================================
-- POPULACAO depara_grupo
-- =====================================================================
INSERT INTO staging.depara_grupo (sk_fonte, codigo_origem, nome_origem, nome_canonico) VALUES
  -- fonte 1 — src_andre_gustavo.grupo.id_grupo 1..5 (codigos ECO, INT, EXE, SUV, LUX)
  (1, '1', 'Economico',     'Economico'),
  (1, '2', 'Intermediario', 'Intermediario'),
  (1, '3', 'Executivo',     'Executivo'),
  (1, '4', 'SUV',           'SUV'),
  (1, '5', 'Luxo',          'Luxo'),

  -- fonte 2 — src_mae016.GRUPO_VEICULO.id_grupo 1..5
  (2, '1', 'Economico',     'Economico'),
  (2, '2', 'Intermediario', 'Intermediario'),
  (2, '3', 'Executivo',     'Executivo'),
  (2, '4', 'SUV',           'SUV'),
  (2, '5', 'Luxo',          'Luxo'),

  -- fonte 3 — src_locadora_db.grupo_veiculo.id 1..5
  (3, '1', 'Economico',     'Economico'),
  (3, '2', 'Intermediario', 'Intermediario'),
  (3, '3', 'Executivo',     'Executivo'),
  (3, '4', 'SUV',           'SUV'),
  (3, '5', 'Luxo',          'Luxo'),

  -- fonte 4 — src_bd_dw_26_1.Categoria.Id_categoria 1..5
  (4, '1', 'Economico',     'Economico'),
  (4, '2', 'Intermediario', 'Intermediario'),
  (4, '3', 'Executivo',     'Executivo'),
  (4, '4', 'SUV',           'SUV'),
  (4, '5', 'Luxo',          'Luxo'),

  -- fonte 5 — src_bigdata.Categoria.IDCategoria 1..5
  (5, '1', 'Economico',     'Economico'),
  (5, '2', 'Intermediario', 'Intermediario'),
  (5, '3', 'Executivo',     'Executivo'),
  (5, '4', 'SUV',           'SUV'),
  (5, '5', 'Luxo',          'Luxo');


CREATE INDEX ix_depara_patio_canonico ON staging.depara_patio(nome_canonico);
CREATE INDEX ix_depara_grupo_canonico ON staging.depara_grupo(nome_canonico);

-- =====================================================================
-- Fim do arquivo: staging/04_tabelas_de_para.sql
-- =====================================================================
