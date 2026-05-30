-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: relatorios/01_controle_patio.sql
--  Objetivo: Relatorio gerencial (a) do enunciado — Controle de patio.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Enunciado (relatorio a):
--    "Quantitativo de veiculos no patio por grupo e origem. Pode haver
--    agrupamento por marca do veiculo, modelos e tipo de mecanizacao.
--    Por origem entenda-se da frota da empresa dona do patio, ou da
--    frota das outras cinco empresas associadas."
--
--  Fonte: dw.fato_patio_diario (snapshot periodico, grao 1 veiculo/dia)
--    + dw.dim_patio + dw.dim_grupo + dw.dim_veiculo + dw.dim_fonte.
--  Filtro: snapshot do dia mais recente disponivel
--          (MAX(sk_tempo) FROM dw.fato_patio_diario).
--  Origem: derivada de flag_frota_propria_no_patio (D-06, P-01 do modelo)
--          mapeada para PROPRIA / ASSOCIADA.
--
--  Execucao:
--    docker exec pgtest psql -U postgres -d locadora_dw_parte2 \
--      -v ON_ERROR_STOP=1 -f /tmp/01_controle_patio.sql
-- =====================================================================

\pset border 2
\pset null '(null)'

-- Variavel: dia do snapshot mais recente (smart-key YYYYMMDD).
-- Evita hardcode de data; usa o ultimo carregado em fato_patio_diario.
\set ON_ERROR_STOP on

\echo
\echo '========================================================================'
\echo 'Relatorio (a) — CONTROLE DE PATIO — Snapshot do dia mais recente'
\echo '========================================================================'
\echo

-- ---------------------------------------------------------------------
-- Visao 1: por patio x grupo x origem — pivot por situacao
-- ---------------------------------------------------------------------
\echo '--- Visao 1: por patio x grupo x origem (pivot por situacao) ---'

WITH ultimo_snapshot AS (
    SELECT MAX(sk_tempo) AS sk_tempo_max FROM dw.fato_patio_diario
),
base AS (
    SELECT
        pa.apelido                                                    AS patio,
        gr.nome_grupo_normalizado                                     AS grupo,
        CASE WHEN fpd.flag_frota_propria_no_patio
             THEN 'PROPRIA' ELSE 'ASSOCIADA' END                      AS origem_frota,
        fpd.situacao
    FROM dw.fato_patio_diario fpd
    JOIN ultimo_snapshot us ON us.sk_tempo_max = fpd.sk_tempo
    JOIN dw.dim_patio    pa ON pa.sk_patio     = fpd.sk_patio
    JOIN dw.dim_grupo    gr ON gr.sk_grupo     = fpd.sk_grupo
)
SELECT
    patio,
    grupo,
    origem_frota,
    COUNT(*) FILTER (WHERE situacao = 'DISPONIVEL')  AS qtd_disponiveis,
    COUNT(*) FILTER (WHERE situacao = 'ALUGADO')     AS qtd_alugados,
    COUNT(*) FILTER (WHERE situacao = 'MANUTENCAO')  AS qtd_manutencao,
    COUNT(*) FILTER (WHERE situacao = 'RESERVADO')   AS qtd_reservados,
    COUNT(*)                                         AS qtd_total
FROM base
GROUP BY patio, grupo, origem_frota
ORDER BY patio, grupo, origem_frota;

\echo
\echo '--- Visao 2: por patio x marca x origem (total) ---'

WITH ultimo_snapshot AS (
    SELECT MAX(sk_tempo) AS sk_tempo_max FROM dw.fato_patio_diario
)
SELECT
    pa.apelido                                                AS patio,
    COALESCE(ve.marca, 'DESCONHECIDA')                        AS marca,
    CASE WHEN fpd.flag_frota_propria_no_patio
         THEN 'PROPRIA' ELSE 'ASSOCIADA' END                  AS origem_frota,
    COUNT(*)                                                  AS qtd_total
FROM dw.fato_patio_diario fpd
JOIN ultimo_snapshot us ON us.sk_tempo_max = fpd.sk_tempo
JOIN dw.dim_patio    pa ON pa.sk_patio     = fpd.sk_patio
JOIN dw.dim_veiculo  ve ON ve.sk_veiculo   = fpd.sk_veiculo
GROUP BY pa.apelido, ve.marca, fpd.flag_frota_propria_no_patio
ORDER BY pa.apelido, marca, origem_frota;

\echo
\echo '--- Visao 3: por patio x modelo x origem (total) ---'

WITH ultimo_snapshot AS (
    SELECT MAX(sk_tempo) AS sk_tempo_max FROM dw.fato_patio_diario
)
SELECT
    pa.apelido                                                AS patio,
    COALESCE(ve.modelo, 'DESCONHECIDO')                       AS modelo,
    CASE WHEN fpd.flag_frota_propria_no_patio
         THEN 'PROPRIA' ELSE 'ASSOCIADA' END                  AS origem_frota,
    COUNT(*)                                                  AS qtd_total
FROM dw.fato_patio_diario fpd
JOIN ultimo_snapshot us ON us.sk_tempo_max = fpd.sk_tempo
JOIN dw.dim_patio    pa ON pa.sk_patio     = fpd.sk_patio
JOIN dw.dim_veiculo  ve ON ve.sk_veiculo   = fpd.sk_veiculo
GROUP BY pa.apelido, ve.modelo, fpd.flag_frota_propria_no_patio
ORDER BY pa.apelido, modelo, origem_frota;

\echo
\echo '--- Visao 4: por patio x mecanizacao x origem (total) ---'

WITH ultimo_snapshot AS (
    SELECT MAX(sk_tempo) AS sk_tempo_max FROM dw.fato_patio_diario
)
SELECT
    pa.apelido                                                AS patio,
    ve.mecanizacao                                            AS mecanizacao,
    CASE WHEN fpd.flag_frota_propria_no_patio
         THEN 'PROPRIA' ELSE 'ASSOCIADA' END                  AS origem_frota,
    COUNT(*)                                                  AS qtd_total
FROM dw.fato_patio_diario fpd
JOIN ultimo_snapshot us ON us.sk_tempo_max = fpd.sk_tempo
JOIN dw.dim_patio    pa ON pa.sk_patio     = fpd.sk_patio
JOIN dw.dim_veiculo  ve ON ve.sk_veiculo   = fpd.sk_veiculo
GROUP BY pa.apelido, ve.mecanizacao, fpd.flag_frota_propria_no_patio
ORDER BY pa.apelido, ve.mecanizacao, origem_frota;

\echo
\echo '========================================================================'
\echo 'Fim do relatorio (a)'
\echo '========================================================================'

-- =====================================================================
-- Fim do arquivo: relatorios/01_controle_patio.sql
-- =====================================================================
