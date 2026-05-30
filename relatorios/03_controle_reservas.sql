-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: relatorios/03_controle_reservas.sql
--  Objetivo: Relatorio gerencial (c) do enunciado — Controle de reservas.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Enunciado (relatorio c):
--    "Quantas reservas por grupo de veiculo e patio (onde os clientes
--    desejam retirar os veiculos), por tempo de retirada futura
--    (reservas para a semana que vem, para o mes que vem etc.), e/ou
--    tempo de duracao das locacoes, e pelas cidades de origem dos
--    clientes."
--
--  Fonte: dw.fato_reserva + dw.dim_grupo + dw.dim_patio (retirada)
--    + dw.dim_cliente + dw.dim_tempo (reserva e retirada prevista).
--  Filtro padrao (MOD-06 do modelo):
--    status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA');
--    CANCELADA excluida — relatorio mede demanda viva, nao taxa de
--    cancelamento.
--  Horizonte temporal: classificacao usa (data_retirada_prevista -
--    data_reserva), ou seja, "antecedencia do cliente" — robusta ao
--    fato de o seed sinteticamente conter reservas com datas que ja
--    passaram em relacao a CURRENT_DATE; alinha-se a metrica
--    dias_antecedencia do fato (MOD-01).
-- =====================================================================

\pset border 2
\pset null '(null)'
\set ON_ERROR_STOP on

\echo
\echo '========================================================================'
\echo 'Relatorio (c) — CONTROLE DE RESERVAS (status ativo)'
\echo '========================================================================'
\echo

-- ---------------------------------------------------------------------
-- Visao 1: reservas por grupo x patio retirada x cidade origem cliente
-- ---------------------------------------------------------------------
\echo '--- Visao 1: grupo x patio retirada x cidade origem do cliente ---'

SELECT
    gr.nome_grupo_normalizado     AS grupo,
    pa.apelido                    AS patio_retirada,
    cl.cidade_origem              AS cidade_origem_cliente,
    COUNT(*)                      AS qtd_reservas
FROM dw.fato_reserva   fres
JOIN dw.dim_grupo      gr ON gr.sk_grupo   = fres.sk_grupo
JOIN dw.dim_patio      pa ON pa.sk_patio   = fres.sk_patio_retirada
JOIN dw.dim_cliente    cl ON cl.sk_cliente = fres.sk_cliente
WHERE fres.status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA')
GROUP BY gr.nome_grupo_normalizado, pa.apelido, cl.cidade_origem
ORDER BY gr.nome_grupo_normalizado, pa.apelido, cl.cidade_origem;

\echo
\echo '--- Visao 2: grupo x horizonte temporal (antecedencia) ---'
-- horizonte = retirada_prevista - data_reserva (dias)
-- semana_proxima: <= 7
-- mes_proximo:   8 .. 30
-- posterior:     > 30

WITH base AS (
    SELECT
        gr.nome_grupo_normalizado                             AS grupo,
        (tr.data_completa - td.data_completa)                 AS dias_antecedencia
    FROM dw.fato_reserva fres
    JOIN dw.dim_grupo    gr ON gr.sk_grupo   = fres.sk_grupo
    JOIN dw.dim_tempo    td ON td.sk_tempo   = fres.sk_tempo_reserva
    JOIN dw.dim_tempo    tr ON tr.sk_tempo   = fres.sk_tempo_retirada_prevista
    WHERE fres.status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA')
),
categorizado AS (
    SELECT
        grupo,
        CASE
            WHEN dias_antecedencia <= 7              THEN 'semana_proxima'
            WHEN dias_antecedencia BETWEEN 8 AND 30  THEN 'mes_proximo'
            WHEN dias_antecedencia > 30              THEN 'posterior'
            ELSE 'indefinido'
        END                                                   AS horizonte,
        CASE
            WHEN dias_antecedencia <= 7              THEN 1
            WHEN dias_antecedencia BETWEEN 8 AND 30  THEN 2
            WHEN dias_antecedencia > 30              THEN 3
            ELSE 9
        END                                                   AS ord_h
    FROM base
)
SELECT
    grupo,
    horizonte,
    COUNT(*) AS qtd
FROM categorizado
GROUP BY grupo, horizonte, ord_h
ORDER BY grupo, ord_h;

\echo
\echo '--- Visao 3: grupo x patio retirada x horizonte (consolidada) ---'

WITH base AS (
    SELECT
        gr.nome_grupo_normalizado                             AS grupo,
        pa.apelido                                            AS patio_retirada,
        (tr.data_completa - td.data_completa)                 AS dias_antecedencia
    FROM dw.fato_reserva fres
    JOIN dw.dim_grupo    gr ON gr.sk_grupo = fres.sk_grupo
    JOIN dw.dim_patio    pa ON pa.sk_patio = fres.sk_patio_retirada
    JOIN dw.dim_tempo    td ON td.sk_tempo = fres.sk_tempo_reserva
    JOIN dw.dim_tempo    tr ON tr.sk_tempo = fres.sk_tempo_retirada_prevista
    WHERE fres.status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA')
)
SELECT
    grupo,
    patio_retirada,
    CASE
        WHEN dias_antecedencia <= 7              THEN 'semana_proxima'
        WHEN dias_antecedencia BETWEEN 8 AND 30  THEN 'mes_proximo'
        WHEN dias_antecedencia > 30              THEN 'posterior'
        ELSE 'indefinido'
    END                                                       AS horizonte,
    COUNT(*) AS qtd
FROM base
GROUP BY grupo, patio_retirada,
         CASE
            WHEN dias_antecedencia <= 7              THEN 'semana_proxima'
            WHEN dias_antecedencia BETWEEN 8 AND 30  THEN 'mes_proximo'
            WHEN dias_antecedencia > 30              THEN 'posterior'
            ELSE 'indefinido'
         END
ORDER BY grupo, patio_retirada, horizonte;

\echo
\echo '========================================================================'
\echo 'Fim do relatorio (c)'
\echo '========================================================================'

-- =====================================================================
-- Fim do arquivo: relatorios/03_controle_reservas.sql
-- =====================================================================
