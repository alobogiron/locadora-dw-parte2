-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: relatorios/05_matriz_markov.sql
--  Objetivo: Matriz estocastica 6x6 de movimentacao da frota entre
--            patios — analise de previsao de ocupacao por cadeia de
--            Markov.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Enunciado:
--    "Para cada patio, levantar o percentual de veiculo que retorna ao
--    mesmo patio de onde foi retirado e o percentual que e entregue em
--    cada um dos outros patios."
--
--  Fonte (decisao D-09 do modelo): agregacao de dw.fato_locacao por
--    (sk_patio_retirada, sk_patio_devolucao) somente para locacoes
--    CONCLUIDA (devolucao registrada, sem viesar com EM_ANDAMENTO/
--    CANCELADA). NAO usamos a tabela fonte de movimentacao operacional,
--    que mistura reposicionamento interno e nao existe em todas as 5
--    fontes.
--
--  Saidas:
--    (i)   Matriz LONG (uma linha por par retirada-devolucao com
--          contagem e probabilidade).
--    (ii)  Matriz WIDE 6x6 — usa CASE WHEN agregado (nao depende da
--          extensao tablefunc; comentario abaixo cita a alternativa).
--    (iii) Validacao: soma das probabilidades por patio_retirada = 1.0
--          (tolerancia 1e-6).
--
--  Alternativa para a versao wide: extensao tablefunc.crosstab(...)
--  oferece pivot generico, mas requer CREATE EXTENSION tablefunc; aqui
--  usamos CASE WHEN para manter o script standalone e portavel.
-- =====================================================================

\pset border 2
\pset null '(null)'
\pset numericlocale off
\set ON_ERROR_STOP on

\echo
\echo '========================================================================'
\echo 'Matriz de Markov — Movimentacao da frota entre patios'
\echo '========================================================================'
\echo

-- ---------------------------------------------------------------------
-- Forma LONG: 36 linhas (6 retiradas x 6 devolucoes) — pode ter menos
-- se algum par nao tiver ocorrencia no seed. probabilidade normaliza
-- por linha de retirada (soma = 1.0 por patio de retirada).
-- ---------------------------------------------------------------------
\echo '--- Forma LONG: par (retirada, devolucao) -> qtd e probabilidade ---'

WITH locacoes_concluidas AS (
    SELECT
        pr.apelido AS patio_retirada,
        pd.apelido AS patio_devolucao
    FROM dw.fato_locacao floc
    JOIN dw.dim_patio pr ON pr.sk_patio = floc.sk_patio_retirada
    JOIN dw.dim_patio pd ON pd.sk_patio = floc.sk_patio_devolucao
    WHERE floc.status_locacao = 'CONCLUIDA'
      AND floc.sk_patio_devolucao IS NOT NULL
),
agregado AS (
    SELECT
        patio_retirada,
        patio_devolucao,
        COUNT(*) AS qtd_locacoes
    FROM locacoes_concluidas
    GROUP BY patio_retirada, patio_devolucao
)
SELECT
    patio_retirada,
    patio_devolucao,
    qtd_locacoes,
    ROUND(
        qtd_locacoes::NUMERIC
        / SUM(qtd_locacoes) OVER (PARTITION BY patio_retirada),
        4
    )::NUMERIC(7,4) AS probabilidade
FROM agregado
ORDER BY patio_retirada, patio_devolucao;

\echo
\echo '--- Forma WIDE: matriz 6x6 (probabilidades) ---'
-- Alternativa via crosstab (extensao tablefunc): exigiria
--   CREATE EXTENSION IF NOT EXISTS tablefunc;
--   SELECT * FROM crosstab($$ ... $$, $$VALUES ('Barra'),...$$) AS m(...);
-- Optamos por CASE WHEN para portabilidade e leitura direta.

WITH locacoes_concluidas AS (
    SELECT
        pr.apelido AS patio_retirada,
        pd.apelido AS patio_devolucao
    FROM dw.fato_locacao floc
    JOIN dw.dim_patio pr ON pr.sk_patio = floc.sk_patio_retirada
    JOIN dw.dim_patio pd ON pd.sk_patio = floc.sk_patio_devolucao
    WHERE floc.status_locacao = 'CONCLUIDA'
      AND floc.sk_patio_devolucao IS NOT NULL
),
totais_por_retirada AS (
    SELECT patio_retirada, COUNT(*)::NUMERIC AS total
    FROM locacoes_concluidas
    GROUP BY patio_retirada
)
SELECT
    lc.patio_retirada,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Galeao')        / t.total, 4)::NUMERIC(7,4) AS galeao,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Santos Dumont') / t.total, 4)::NUMERIC(7,4) AS santos_dumont,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Rodoviaria')    / t.total, 4)::NUMERIC(7,4) AS rodoviaria,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Rio Sul')       / t.total, 4)::NUMERIC(7,4) AS rio_sul,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Nova America')  / t.total, 4)::NUMERIC(7,4) AS nova_america,
    ROUND(COUNT(*) FILTER (WHERE lc.patio_devolucao = 'Barra')         / t.total, 4)::NUMERIC(7,4) AS barra
FROM locacoes_concluidas lc
JOIN totais_por_retirada t ON t.patio_retirada = lc.patio_retirada
GROUP BY lc.patio_retirada, t.total
ORDER BY lc.patio_retirada;

\echo
\echo '--- Forma WIDE: matriz 6x6 (contagens absolutas, controle) ---'

WITH locacoes_concluidas AS (
    SELECT
        pr.apelido AS patio_retirada,
        pd.apelido AS patio_devolucao
    FROM dw.fato_locacao floc
    JOIN dw.dim_patio pr ON pr.sk_patio = floc.sk_patio_retirada
    JOIN dw.dim_patio pd ON pd.sk_patio = floc.sk_patio_devolucao
    WHERE floc.status_locacao = 'CONCLUIDA'
      AND floc.sk_patio_devolucao IS NOT NULL
)
SELECT
    patio_retirada,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Galeao')        AS galeao,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Santos Dumont') AS santos_dumont,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Rodoviaria')    AS rodoviaria,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Rio Sul')       AS rio_sul,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Nova America')  AS nova_america,
    COUNT(*) FILTER (WHERE patio_devolucao = 'Barra')         AS barra,
    COUNT(*)                                                  AS total_retiradas
FROM locacoes_concluidas
GROUP BY patio_retirada
ORDER BY patio_retirada;

\echo
\echo '--- Validacao: soma das probabilidades por patio_retirada deve ser 1.0 ---'
-- Deve retornar zero linhas se a matriz estocastica esta correta.

WITH locacoes_concluidas AS (
    SELECT
        pr.apelido AS patio_retirada,
        pd.apelido AS patio_devolucao
    FROM dw.fato_locacao floc
    JOIN dw.dim_patio pr ON pr.sk_patio = floc.sk_patio_retirada
    JOIN dw.dim_patio pd ON pd.sk_patio = floc.sk_patio_devolucao
    WHERE floc.status_locacao = 'CONCLUIDA'
      AND floc.sk_patio_devolucao IS NOT NULL
),
agregado AS (
    SELECT
        patio_retirada,
        patio_devolucao,
        COUNT(*) AS qtd_locacoes
    FROM locacoes_concluidas
    GROUP BY patio_retirada, patio_devolucao
),
probabilidades AS (
    SELECT
        patio_retirada,
        qtd_locacoes::NUMERIC
            / SUM(qtd_locacoes) OVER (PARTITION BY patio_retirada) AS p
    FROM agregado
)
SELECT
    patio_retirada,
    SUM(p)            AS soma_prob,
    ABS(SUM(p) - 1.0) AS delta_abs
FROM probabilidades
GROUP BY patio_retirada
HAVING ABS(SUM(p) - 1.0) > 0.000001
ORDER BY patio_retirada;

\echo
\echo '(Se a tabela acima esta vazia, todas as linhas da matriz somam 1.0 com'
\echo ' tolerancia de 1e-6 — matriz estocastica valida.)'
\echo
\echo '========================================================================'
\echo 'Fim da matriz de Markov'
\echo '========================================================================'

-- =====================================================================
-- Fim do arquivo: relatorios/05_matriz_markov.sql
-- =====================================================================
