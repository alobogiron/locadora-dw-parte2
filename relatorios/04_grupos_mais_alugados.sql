-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: relatorios/04_grupos_mais_alugados.sql
--  Objetivo: Relatorio gerencial (d) do enunciado — Grupos mais alugados,
--            cruzando com a origem dos clientes.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Enunciado (relatorio d):
--    "Grupos de veiculos mais alugados — cruzando, eventualmente, com a
--    origem dos clientes."
--
--  Fonte: dw.fato_locacao + dw.dim_grupo + dw.dim_cliente.
--  Filtro: sem filtro de status — o "alugado" do enunciado refere-se a
--    "ja firmou contrato de locacao" (qualquer status). Para a leitura
--    de mercado mais conservadora, a Visao 3 segrega por status.
-- =====================================================================

\pset border 2
\pset null '(null)'
\set ON_ERROR_STOP on

\echo
\echo '========================================================================'
\echo 'Relatorio (d) — GRUPOS DE VEICULOS MAIS ALUGADOS'
\echo '========================================================================'
\echo

-- ---------------------------------------------------------------------
-- Visao 1: ranking por grupo (todas as locacoes)
-- ---------------------------------------------------------------------
\echo '--- Visao 1: ranking de grupos por quantidade de locacoes ---'

SELECT
    gr.nome_grupo_normalizado                         AS grupo,
    COUNT(*)                                          AS qtd_locacoes,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC)        AS posicao
FROM dw.fato_locacao floc
JOIN dw.dim_grupo gr ON gr.sk_grupo = floc.sk_grupo
GROUP BY gr.nome_grupo_normalizado
ORDER BY qtd_locacoes DESC, grupo;

\echo
\echo '--- Visao 2: grupo x cidade de origem do cliente ---'

SELECT
    gr.nome_grupo_normalizado                         AS grupo,
    cl.cidade_origem                                  AS cidade_origem,
    COUNT(*)                                          AS qtd_locacoes
FROM dw.fato_locacao floc
JOIN dw.dim_grupo   gr ON gr.sk_grupo   = floc.sk_grupo
JOIN dw.dim_cliente cl ON cl.sk_cliente = floc.sk_cliente
GROUP BY gr.nome_grupo_normalizado, cl.cidade_origem
ORDER BY qtd_locacoes DESC, grupo, cidade_origem;

\echo
\echo '--- Visao 3: ranking grupo x cidade — top por cidade ---'
-- Para cada cidade, identifica o grupo mais procurado.
WITH base AS (
    SELECT
        cl.cidade_origem                              AS cidade_origem,
        gr.nome_grupo_normalizado                     AS grupo,
        COUNT(*)                                      AS qtd_locacoes,
        ROW_NUMBER() OVER (PARTITION BY cl.cidade_origem
                           ORDER BY COUNT(*) DESC,
                                    gr.nome_grupo_normalizado) AS rn
    FROM dw.fato_locacao floc
    JOIN dw.dim_grupo   gr ON gr.sk_grupo   = floc.sk_grupo
    JOIN dw.dim_cliente cl ON cl.sk_cliente = floc.sk_cliente
    GROUP BY cl.cidade_origem, gr.nome_grupo_normalizado
)
SELECT cidade_origem, grupo, qtd_locacoes
FROM base
WHERE rn = 1
ORDER BY qtd_locacoes DESC, cidade_origem;

\echo
\echo '========================================================================'
\echo 'Fim do relatorio (d)'
\echo '========================================================================'

-- =====================================================================
-- Fim do arquivo: relatorios/04_grupos_mais_alugados.sql
-- =====================================================================
