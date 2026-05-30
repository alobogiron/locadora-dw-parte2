-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: relatorios/02_controle_locacoes.sql
--  Objetivo: Relatorio gerencial (b) do enunciado — Controle das locacoes.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Enunciado (relatorio b):
--    "Quantitativo de veiculos alugados por grupo, e dimensao de tempo
--    de locacao e tempo restante para devolucao (quando ficarao
--    disponiveis para nova locacao)."
--
--  Fonte: dw.fato_locacao + dw.dim_grupo + dw.dim_tempo (role-playing).
--  Notas:
--    - Faixa de duracao: aplicada a TODAS as locacoes (qualquer status)
--      sobre duracao_prevista_dias.
--    - Tempo restante: somente locacoes EM_ANDAMENTO
--      (sk_tempo_devolucao_real IS NULL filtra evento ainda nao ocorrido,
--      conforme D-10/MOD-02 do modelo); calculo: sk_tempo_devolucao_prevista
--      em data, menos CURRENT_DATE.
-- =====================================================================

\pset border 2
\pset null '(null)'
\set ON_ERROR_STOP on

\echo
\echo '========================================================================'
\echo 'Relatorio (b) — CONTROLE DAS LOCACOES'
\echo '========================================================================'
\echo

-- ---------------------------------------------------------------------
-- Visao 1: locacoes por grupo x faixa de duracao prevista
-- ---------------------------------------------------------------------
\echo '--- Visao 1: locacoes por grupo x faixa de duracao prevista ---'

WITH base AS (
    SELECT
        gr.nome_grupo_normalizado                            AS grupo,
        CASE
            WHEN floc.duracao_prevista_dias BETWEEN  1 AND  3 THEN '1-3 dias'
            WHEN floc.duracao_prevista_dias BETWEEN  4 AND  7 THEN '4-7 dias'
            WHEN floc.duracao_prevista_dias BETWEEN  8 AND 15 THEN '8-15 dias'
            WHEN floc.duracao_prevista_dias >= 16             THEN '16+ dias'
            ELSE 'INDEFINIDA'
        END                                                  AS faixa_duracao,
        -- chave numerica auxiliar para ordenacao consistente
        CASE
            WHEN floc.duracao_prevista_dias BETWEEN  1 AND  3 THEN 1
            WHEN floc.duracao_prevista_dias BETWEEN  4 AND  7 THEN 2
            WHEN floc.duracao_prevista_dias BETWEEN  8 AND 15 THEN 3
            WHEN floc.duracao_prevista_dias >= 16             THEN 4
            ELSE 9
        END                                                  AS ord_faixa
    FROM dw.fato_locacao floc
    JOIN dw.dim_grupo gr ON gr.sk_grupo = floc.sk_grupo
)
SELECT
    grupo,
    faixa_duracao,
    COUNT(*) AS qtd_locacoes
FROM base
GROUP BY grupo, faixa_duracao, ord_faixa
ORDER BY grupo, ord_faixa;

\echo
\echo '--- Visao 2: tempo restante para devolucao (somente EM_ANDAMENTO) ---'

-- Calculo: dias = sk_tempo_devolucao_prevista (smart-key YYYYMMDD)
-- convertido para DATE, menos CURRENT_DATE. Sem hardcode de data.
WITH em_andamento AS (
    SELECT
        gr.nome_grupo_normalizado                            AS grupo,
        td.data_completa                                     AS data_devolucao_prev,
        (td.data_completa - CURRENT_DATE)                    AS dias_restantes
    FROM dw.fato_locacao floc
    JOIN dw.dim_grupo gr ON gr.sk_grupo = floc.sk_grupo
    JOIN dw.dim_tempo td ON td.sk_tempo = floc.sk_tempo_devolucao_prevista
    WHERE floc.status_locacao = 'EM_ANDAMENTO'
),
categorizado AS (
    SELECT
        grupo,
        dias_restantes,
        CASE
            WHEN dias_restantes <  0                 THEN 'Atrasada'
            WHEN dias_restantes =  0                 THEN 'Hoje'
            WHEN dias_restantes BETWEEN 1 AND 3      THEN '1-3 dias'
            WHEN dias_restantes BETWEEN 4 AND 7      THEN '4-7 dias'
            WHEN dias_restantes >= 8                 THEN '8+ dias'
        END                                                  AS dias_restantes_categoria,
        CASE
            WHEN dias_restantes <  0                 THEN 0
            WHEN dias_restantes =  0                 THEN 1
            WHEN dias_restantes BETWEEN 1 AND 3      THEN 2
            WHEN dias_restantes BETWEEN 4 AND 7      THEN 3
            ELSE                                          4
        END                                                  AS ord_categoria
    FROM em_andamento
)
SELECT
    grupo,
    dias_restantes_categoria,
    COUNT(*) AS qtd_em_andamento
FROM categorizado
GROUP BY grupo, dias_restantes_categoria, ord_categoria
ORDER BY grupo, ord_categoria;

\echo
\echo '--- Visao 3 (consolidada): grupo x faixa duracao x status_locacao ---'

WITH base AS (
    SELECT
        gr.nome_grupo_normalizado                            AS grupo,
        floc.status_locacao,
        CASE
            WHEN floc.duracao_prevista_dias BETWEEN  1 AND  3 THEN '1-3 dias'
            WHEN floc.duracao_prevista_dias BETWEEN  4 AND  7 THEN '4-7 dias'
            WHEN floc.duracao_prevista_dias BETWEEN  8 AND 15 THEN '8-15 dias'
            WHEN floc.duracao_prevista_dias >= 16             THEN '16+ dias'
            ELSE 'INDEFINIDA'
        END                                                  AS faixa_duracao,
        CASE
            WHEN floc.duracao_prevista_dias BETWEEN  1 AND  3 THEN 1
            WHEN floc.duracao_prevista_dias BETWEEN  4 AND  7 THEN 2
            WHEN floc.duracao_prevista_dias BETWEEN  8 AND 15 THEN 3
            WHEN floc.duracao_prevista_dias >= 16             THEN 4
            ELSE 9
        END                                                  AS ord_faixa
    FROM dw.fato_locacao floc
    JOIN dw.dim_grupo gr ON gr.sk_grupo = floc.sk_grupo
)
SELECT
    grupo,
    status_locacao,
    faixa_duracao,
    COUNT(*) AS qtd_locacoes
FROM base
GROUP BY grupo, status_locacao, faixa_duracao, ord_faixa
ORDER BY grupo, status_locacao, ord_faixa;

\echo
\echo '========================================================================'
\echo 'Fim do relatorio (b)'
\echo '========================================================================'

-- =====================================================================
-- Fim do arquivo: relatorios/02_controle_locacoes.sql
-- =====================================================================
