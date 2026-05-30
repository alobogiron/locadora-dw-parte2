-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/08_load_fatos.sql
--  Objetivo: Load — popula os 3 fatos do DW.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Ordem: fato_locacao -> fato_reserva -> fato_patio_diario.
--  Idempotente: TRUNCATE antes de inserir.
--
--  Particularidades:
--   - Locacao EM_ANDAMENTO ou sem data_devolucao_real
--       -> sk_tempo_devolucao_real = NULL e sk_patio_devolucao = NULL
--       (MOD-01: criterio direto via data_devolucao_real IS NULL).
--   - Locacao CANCELADA sem data_retirada_real (cancelada antes de
--       ocorrer): sk_tempo_retirada_real = 19000101 (sentinela
--       DATA_DESCONHECIDA). CRITICO-01 da revisao.
--   - valor_total_estimado = valor_diaria * (devolucao_prevista - retirada_real)
--       quando as 3 informacoes estao disponiveis (MOD-04 da revisao).
--   - Reserva da fonte bigdata (sk_fonte=5) sem grupo -> sk_grupo = 0.
--   - fato_patio_diario: snapshot dos ULTIMOS 30 DIAS (escala razoavel).
--     - Veiculo BAIXADO no DW eh filtrado (nao aparece no snapshot).
--     - Veiculo ALUGADO se locacao cobre o dia (LATERAL com ORDER BY
--       deterministico — CRITICO-02 da revisao).
--     - Caso contrario, situacao_atual=MANUTENCAO/RESERVADO no DW
--       propaga para o snapshot (MOD-03); restante -> DISPONIVEL no
--       patio de origem do veiculo.
-- =====================================================================

SET search_path = dw, staging, public;


-- =====================================================================
-- 0. Pre-condicao: staging populada (MOD-06 da revisao)
--    O snapshot fato_patio_diario depende de staging.stg_veiculo
--    (nome_canonico_patio). Se algum operador tentar rodar 08 sozinho
--    apos um TRUNCATE em staging, falhamos rapido com mensagem clara.
-- =====================================================================
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM staging.stg_veiculo) = 0 THEN
        RAISE EXCEPTION '08_load_fatos requer 01-05 + 06 executados na mesma sessao (staging.stg_veiculo esta vazia).';
    END IF;
END $$;


-- =====================================================================
-- 1. fato_locacao
-- =====================================================================
TRUNCATE TABLE dw.fato_locacao RESTART IDENTITY;

INSERT INTO dw.fato_locacao (
    sk_tempo_retirada_real, sk_tempo_devolucao_real, sk_tempo_devolucao_prevista,
    sk_patio_retirada, sk_patio_devolucao,
    sk_veiculo, sk_grupo, sk_cliente, sk_fonte,
    id_locacao_origem, numero_contrato_fonte, status_locacao,
    qtd_locacoes, duracao_prevista_dias, duracao_real_dias, km_rodados,
    valor_diaria_aplicada, valor_total_estimado, valor_total_final,
    sk_fonte_id_natural
)
SELECT
    -- sk_tempo_retirada_real: smart-key YYYYMMDD; CANCELADA sem retirada
    -- usa sentinela 19000101 (CRITICO-01: "evento previsto mas cancelado
    -- antes de ocorrer"). Demais locacoes precisam de data_retirada_real.
    COALESCE(
        (EXTRACT(YEAR FROM sl.data_retirada_real) * 10000
         + EXTRACT(MONTH FROM sl.data_retirada_real) * 100
         + EXTRACT(DAY FROM sl.data_retirada_real))::INTEGER,
        19000101
    ),
    -- sk_tempo_devolucao_real: NULL se EM_ANDAMENTO ou data nula
    CASE
        WHEN sl.status_normalizado = 'EM_ANDAMENTO' OR sl.data_devolucao_real IS NULL
        THEN NULL
        ELSE (EXTRACT(YEAR FROM sl.data_devolucao_real) * 10000
              + EXTRACT(MONTH FROM sl.data_devolucao_real) * 100
              + EXTRACT(DAY FROM sl.data_devolucao_real))::INTEGER
    END,
    -- sk_tempo_devolucao_prevista: cair em sentinela 19000101 quando
    -- nem previsao nem retirada existirem (CANCELADA sem nenhuma data).
    COALESCE(
        (EXTRACT(YEAR FROM sl.data_devolucao_prevista) * 10000
         + EXTRACT(MONTH FROM sl.data_devolucao_prevista) * 100
         + EXTRACT(DAY FROM sl.data_devolucao_prevista))::INTEGER,
        (EXTRACT(YEAR FROM sl.data_retirada_real) * 10000
         + EXTRACT(MONTH FROM sl.data_retirada_real) * 100
         + EXTRACT(DAY FROM sl.data_retirada_real))::INTEGER,
        19000101
    ),
    -- sk_patio_retirada
    dp_ret.sk_patio,
    -- sk_patio_devolucao: NULL quando nao houve devolucao real (semantica
    -- direta via data_devolucao_real IS NULL — MOD-01 da revisao).
    -- Cobre EM_ANDAMENTO e CANCELADA sem devolucao em todas as fontes.
    CASE
        WHEN sl.data_devolucao_real IS NULL THEN NULL
        ELSE dp_dev.sk_patio
    END,
    dv.sk_veiculo,
    COALESCE(dg.sk_grupo, 0),
    -- sk_cliente: pode ser NULL na locacao de fontes que nao tem amarra direta
    -- (fonte 3); descartar essas no WHERE.
    dc.sk_cliente,
    sl.sk_fonte,
    sl.id_natural::BIGINT,
    sl.numero_contrato,
    sl.status_normalizado,
    1,
    -- duracao_prevista_dias
    CASE
        WHEN sl.data_devolucao_prevista IS NOT NULL AND sl.data_retirada_real IS NOT NULL
        THEN EXTRACT(EPOCH FROM (sl.data_devolucao_prevista - sl.data_retirada_real))::INTEGER / 86400
        ELSE NULL
    END,
    sl.duracao_real_dias,
    sl.km_rodados,
    sl.valor_diaria_aplicada,
    -- valor_total_estimado: valor_diaria_aplicada * duracao_prevista_dias
    -- (MOD-04 da revisao). Preserva NULL quando faltar diaria ou previsao.
    CASE
        WHEN sl.valor_diaria_aplicada    IS NOT NULL
         AND sl.data_devolucao_prevista  IS NOT NULL
         AND sl.data_retirada_real       IS NOT NULL
         AND (sl.data_devolucao_prevista::DATE - sl.data_retirada_real::DATE) > 0
        THEN sl.valor_diaria_aplicada
             * (sl.data_devolucao_prevista::DATE - sl.data_retirada_real::DATE)
        ELSE NULL
    END,
    sl.valor_total_final,
    sl.id_natural
FROM      staging.stg_locacao sl
LEFT JOIN dw.dim_patio   dp_ret ON dp_ret.nome_canonico = sl.nome_canonico_patio_retirada
LEFT JOIN dw.dim_patio   dp_dev ON dp_dev.nome_canonico = sl.nome_canonico_patio_devolucao
LEFT JOIN dw.dim_veiculo dv     ON dv.sk_fonte_origem   = sl.sk_fonte AND dv.id_natural_origem = sl.veiculo_id_natural
LEFT JOIN dw.dim_grupo   dg     ON dg.nome_grupo_normalizado = sl.nome_canonico_grupo
LEFT JOIN dw.dim_cliente dc     ON dc.sk_fonte_origem = sl.sk_fonte AND dc.id_natural_origem = sl.cliente_id_natural
-- CRITICO-01: nao filtrar mais por data_retirada_real IS NOT NULL — isso
-- descartava CANCELADAs da fonte 3 (12 linhas perdidas). Agora aceitamos
-- toda locacao com status conhecido; canceladas sem retirada vao para
-- sk_tempo_retirada_real = 19000101 (sentinela).
WHERE sl.status_normalizado     <> 'DESCONHECIDO'
  AND dp_ret.sk_patio            IS NOT NULL
  AND dv.sk_veiculo              IS NOT NULL
  AND dc.sk_cliente              IS NOT NULL
ON CONFLICT (sk_fonte, sk_fonte_id_natural) DO NOTHING;


-- =====================================================================
-- 2. fato_reserva
-- =====================================================================
TRUNCATE TABLE dw.fato_reserva RESTART IDENTITY;

INSERT INTO dw.fato_reserva (
    sk_tempo_reserva, sk_tempo_retirada_prevista, sk_tempo_devolucao_prevista,
    sk_patio_retirada, sk_patio_devolucao,
    sk_grupo, sk_cliente, sk_fonte,
    id_reserva_origem, status_reserva,
    qtd_reservas, qtd_veiculos_solicitados,
    duracao_prevista_dias, dias_antecedencia, valor_previsto,
    sk_fonte_id_natural
)
SELECT
    (EXTRACT(YEAR FROM sr.data_reserva) * 10000
     + EXTRACT(MONTH FROM sr.data_reserva) * 100
     + EXTRACT(DAY FROM sr.data_reserva))::INTEGER,
    (EXTRACT(YEAR FROM sr.data_retirada_prevista) * 10000
     + EXTRACT(MONTH FROM sr.data_retirada_prevista) * 100
     + EXTRACT(DAY FROM sr.data_retirada_prevista))::INTEGER,
    (EXTRACT(YEAR FROM sr.data_devolucao_prevista) * 10000
     + EXTRACT(MONTH FROM sr.data_devolucao_prevista) * 100
     + EXTRACT(DAY FROM sr.data_devolucao_prevista))::INTEGER,
    dp_ret.sk_patio,
    -- patio_devolucao em reserva: se NULL na fonte, replicar do retirada
    COALESCE(dp_dev.sk_patio, dp_ret.sk_patio),
    -- sk_grupo: bigdata sem grupo -> sentinela 0
    COALESCE(dg.sk_grupo, 0),
    dc.sk_cliente,
    sr.sk_fonte,
    sr.id_natural::BIGINT,
    sr.status_normalizado,
    1,
    COALESCE(sr.qtd_veiculos_solicitados, 1),
    CASE
        WHEN sr.data_devolucao_prevista IS NOT NULL AND sr.data_retirada_prevista IS NOT NULL
        THEN EXTRACT(EPOCH FROM (sr.data_devolucao_prevista - sr.data_retirada_prevista))::INTEGER / 86400
        ELSE NULL
    END,
    CASE
        WHEN sr.data_retirada_prevista IS NOT NULL AND sr.data_reserva IS NOT NULL
        THEN EXTRACT(EPOCH FROM (sr.data_retirada_prevista - sr.data_reserva))::INTEGER / 86400
        ELSE NULL
    END,
    sr.valor_previsto,
    sr.id_natural
FROM      staging.stg_reserva sr
LEFT JOIN dw.dim_patio   dp_ret ON dp_ret.nome_canonico = sr.nome_canonico_patio_retirada
LEFT JOIN dw.dim_patio   dp_dev ON dp_dev.nome_canonico = sr.nome_canonico_patio_devolucao
LEFT JOIN dw.dim_grupo   dg     ON dg.nome_grupo_normalizado = sr.nome_canonico_grupo
LEFT JOIN dw.dim_cliente dc     ON dc.sk_fonte_origem = sr.sk_fonte AND dc.id_natural_origem = sr.cliente_id_natural
WHERE sr.data_reserva           IS NOT NULL
  AND sr.data_retirada_prevista IS NOT NULL
  AND sr.data_devolucao_prevista IS NOT NULL
  AND dp_ret.sk_patio           IS NOT NULL
  AND dc.sk_cliente             IS NOT NULL
ON CONFLICT (sk_fonte, sk_fonte_id_natural) DO NOTHING;


-- =====================================================================
-- 3. fato_patio_diario
-- Grao: 1 veiculo x 1 dia.
-- Estrategia: snapshot dos ultimos 30 dias antes de CURRENT_DATE.
-- Regra:
--  - se existe locacao do veiculo cobrindo o dia (retirada<=dia<devolucao_real
--    ou retirada<=dia AND status='EM_ANDAMENTO') -> situacao='ALUGADO',
--    sk_patio = patio de retirada da locacao;
--  - caso contrario -> situacao='DISPONIVEL', sk_patio = ultimo patio_devolucao
--    de locacao concluida antes do dia, ou (se nao houver) patio de origem
--    do veiculo (extracted em staging.stg_veiculo.nome_canonico_patio).
-- =====================================================================
TRUNCATE TABLE dw.fato_patio_diario RESTART IDENTITY;

-- CRITICO-02 da revisao: contagem de sobreposicoes (veiculo x dia com 2+
-- locacoes cobrindo). Logamos a quantidade antes do load para o operador
-- saber que o desempate deterministico foi acionado (ORDER BY no LATERAL).
DO $$
DECLARE
    v_overlaps INTEGER;
BEGIN
    WITH dias AS (
        SELECT generate_series(
                  (CURRENT_DATE - INTERVAL '29 days')::DATE,
                  CURRENT_DATE,
                  INTERVAL '1 day'
               )::DATE AS dia
    ),
    loc_intervalos AS (
        SELECT
            fl.sk_veiculo,
            dt_ret.data_completa  AS dia_retirada,
            COALESCE(dt_dev.data_completa, CURRENT_DATE) AS dia_devolucao
          FROM      dw.fato_locacao fl
          JOIN      dw.dim_tempo dt_ret ON dt_ret.sk_tempo = fl.sk_tempo_retirada_real
          LEFT JOIN dw.dim_tempo dt_dev ON dt_dev.sk_tempo = fl.sk_tempo_devolucao_real
         WHERE fl.status_locacao IN ('EM_ANDAMENTO','CONCLUIDA')
    ),
    sobreposicoes AS (
        SELECT li.sk_veiculo, d.dia
          FROM loc_intervalos li
          JOIN dias d ON d.dia >= li.dia_retirada AND d.dia < li.dia_devolucao
         GROUP BY li.sk_veiculo, d.dia
        HAVING COUNT(*) > 1
    )
    SELECT COUNT(*) INTO v_overlaps FROM sobreposicoes;
    RAISE NOTICE 'INFO fato_patio_diario: % combinacoes veiculo x dia com sobreposicao de locacoes (desempate determinista pelo LATERAL com ORDER BY).', v_overlaps;
END $$;

-- Tabela auxiliar in-memory: para cada (veiculo, dia), determinar
-- (situacao, sk_patio).
WITH dias AS (
    SELECT generate_series(
              (CURRENT_DATE - INTERVAL '29 days')::DATE,
              CURRENT_DATE,
              INTERVAL '1 day'
           )::DATE AS dia
),
veic_patio AS (
    -- Para cada veiculo, recupera sk_veiculo, sk_grupo, sk_fonte e sk_patio_origem.
    -- MOD-03 da revisao: veiculos BAIXADO sao filtrados aqui — nao aparecem
    -- no snapshot diario. Veiculos MANUTENCAO seguem para o snapshot e
    -- recebem situacao='MANUTENCAO' quando nao houver locacao cobrindo o dia.
    SELECT
        dv.sk_veiculo,
        dv.sk_fonte_origem        AS sk_fonte,
        dv.situacao_atual         AS situacao_atual,
        COALESCE(dg.sk_grupo, 0)  AS sk_grupo,
        dp_origem.sk_patio        AS sk_patio_origem
    FROM      dw.dim_veiculo    dv
    LEFT JOIN staging.stg_veiculo sv ON sv.sk_fonte = dv.sk_fonte_origem AND sv.id_natural = dv.id_natural_origem
    LEFT JOIN staging.depara_grupo dg2 ON dg2.sk_fonte = sv.sk_fonte AND dg2.codigo_origem = sv.grupo_id_natural
    LEFT JOIN dw.dim_grupo      dg ON dg.nome_grupo_normalizado = dg2.nome_canonico
    LEFT JOIN dw.dim_patio      dp_origem ON dp_origem.nome_canonico = sv.nome_canonico_patio
    WHERE dv.situacao_atual <> 'BAIXADO'
),
loc_intervalos AS (
    -- Locacoes que tem retirada (independente de status). Para EM_ANDAMENTO,
    -- usar CURRENT_DATE como fim aberto. sk_locacao usado para desempate
    -- determinista no LATERAL JOIN (CRITICO-02 da revisao).
    SELECT
        fl.sk_locacao,
        fl.sk_veiculo,
        fl.sk_patio_retirada,
        dt_ret.data_completa  AS dia_retirada,
        COALESCE(dt_dev.data_completa, CURRENT_DATE) AS dia_devolucao,
        fl.status_locacao
    FROM      dw.fato_locacao fl
    JOIN      dw.dim_tempo dt_ret ON dt_ret.sk_tempo = fl.sk_tempo_retirada_real
    LEFT JOIN dw.dim_tempo dt_dev ON dt_dev.sk_tempo = fl.sk_tempo_devolucao_real
    WHERE fl.status_locacao IN ('EM_ANDAMENTO','CONCLUIDA')
),
veic_x_dia AS (
    SELECT vp.sk_veiculo, d.dia
    FROM veic_patio vp
    CROSS JOIN dias d
),
veic_dia_alugado AS (
    -- Verifica se ha locacao cobrindo o dia. CRITICO-02: ORDER BY
    -- determinista (retirada mais antiga primeiro; desempate por sk_locacao)
    -- garante que re-execucoes do ETL produzam o mesmo snapshot mesmo
    -- com sobreposicoes (cenario de dado-fonte com bug de cadastro).
    SELECT
        vxd.sk_veiculo, vxd.dia,
        li.sk_patio_retirada AS sk_patio_loc,
        li.status_locacao
    FROM      veic_x_dia vxd
    LEFT JOIN LATERAL (
        SELECT li2.sk_patio_retirada, li2.status_locacao
          FROM loc_intervalos li2
         WHERE li2.sk_veiculo = vxd.sk_veiculo
           AND vxd.dia >= li2.dia_retirada
           AND vxd.dia <  li2.dia_devolucao
         ORDER BY li2.dia_retirada ASC, li2.sk_locacao ASC
         LIMIT 1
    ) li ON TRUE
)
INSERT INTO dw.fato_patio_diario (
    sk_tempo, sk_patio, sk_veiculo, sk_grupo, sk_fonte,
    situacao, flag_frota_propria_no_patio, qtd_veiculos, capacidade_vagas_patio
)
SELECT
    -- sk_tempo
    (EXTRACT(YEAR FROM vda.dia) * 10000
     + EXTRACT(MONTH FROM vda.dia) * 100
     + EXTRACT(DAY FROM vda.dia))::INTEGER,
    -- sk_patio: ALUGADO -> patio_loc; senao -> patio_origem
    COALESCE(vda.sk_patio_loc, vp.sk_patio_origem)                AS sk_patio,
    vda.sk_veiculo,
    vp.sk_grupo,
    vp.sk_fonte,
    -- MOD-03 da revisao: quando nao ha locacao cobrindo o dia e o veiculo
    -- esta em MANUTENCAO no DW, emitir situacao='MANUTENCAO' (em vez de
    -- DISPONIVEL falsamente). BAIXADO foi filtrado antes (nao chega aqui).
    CASE
        WHEN vda.sk_patio_loc IS NOT NULL                   THEN 'ALUGADO'
        WHEN vp.situacao_atual = 'MANUTENCAO'               THEN 'MANUTENCAO'
        WHEN vp.situacao_atual = 'RESERVADO'                THEN 'RESERVADO'
        ELSE 'DISPONIVEL'
    END,
    -- flag_frota_propria_no_patio: comparar codigo_fonte do veiculo com codigo_fonte_dona do patio.
    -- COALESCE garante FALSE quando o patio nao tem dona (Barra Shopping, P-07) ou fonte unknown.
    COALESCE(df.codigo_fonte = dp.codigo_fonte_dona, FALSE),
    1,
    dp.capacidade_vagas_referencia
FROM      veic_dia_alugado vda
JOIN      veic_patio       vp ON vp.sk_veiculo = vda.sk_veiculo
LEFT JOIN dw.dim_patio     dp ON dp.sk_patio = COALESCE(vda.sk_patio_loc, vp.sk_patio_origem)
LEFT JOIN dw.dim_fonte     df ON df.sk_fonte = vp.sk_fonte
WHERE COALESCE(vda.sk_patio_loc, vp.sk_patio_origem) IS NOT NULL;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/08_load_fatos.sql
-- =====================================================================
