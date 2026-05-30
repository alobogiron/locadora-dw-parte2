-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/06_transform.sql
--  Objetivo: Transform — normalizacoes e derivacoes nas tabelas staging.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Operacoes (todas idempotentes):
--    1. UPPER(TRIM(...)) em nomes textuais.
--    2. Aplicar staging.depara_patio -> stg_*.nome_canonico_*
--    3. Aplicar staging.depara_grupo -> stg_*.nome_canonico_grupo
--    4. Normalizar status (origem -> dominio do DW).
--    5. Derivar duracao_real_dias, km_rodados.
--    6. Tratar NULL: cidade NULL -> 'CIDADE_DESCONHECIDA' em stg_cliente.
--    7. RAISE NOTICE para descartes.
-- =====================================================================

SET search_path = staging, public;

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '==== Transform START ====';

    -- =====================================================================
    -- 1. NORMALIZACAO DE TEXTO (UPPER + TRIM em nomes nao-PK)
    -- =====================================================================
    -- Patio: nome_original e cidade
    UPDATE staging.stg_patio
       SET nome_original = TRIM(nome_original),
           cidade        = UPPER(TRIM(COALESCE(cidade, '')));

    UPDATE staging.stg_grupo
       SET nome_origem = UPPER(TRIM(COALESCE(nome_origem, ''))),
           classe_luxo = UPPER(TRIM(COALESCE(classe_luxo, '')));

    UPDATE staging.stg_cliente
       SET nome   = TRIM(COALESCE(nome,   '')),
           cidade_origem = UPPER(TRIM(COALESCE(cidade_origem, '')));

    UPDATE staging.stg_veiculo
       SET marca       = UPPER(TRIM(COALESCE(marca,       ''))),
           modelo      = UPPER(TRIM(COALESCE(modelo,      ''))),
           cor         = UPPER(TRIM(COALESCE(cor,         ''))),
           mecanizacao = UPPER(TRIM(COALESCE(mecanizacao, ''))),
           situacao    = UPPER(TRIM(COALESCE(situacao,    '')));


    -- =====================================================================
    -- 2. APLICAR depara_patio
    -- Atualiza stg_patio.nome_canonico e stg_*.nome_canonico_patio_* em
    -- todas as tabelas que referenciam patios.
    -- =====================================================================
    UPDATE staging.stg_patio sp
       SET nome_canonico = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sp.sk_fonte
       AND dp.id_natural_origem = sp.id_natural;

    -- stg_veiculo
    UPDATE staging.stg_veiculo sv
       SET nome_canonico_patio = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sv.sk_fonte
       AND dp.id_natural_origem = sv.patio_id_natural;

    -- stg_reserva — retirada
    UPDATE staging.stg_reserva sr
       SET nome_canonico_patio_retirada = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sr.sk_fonte
       AND dp.id_natural_origem = sr.patio_retirada_id_natural;

    -- stg_reserva — devolucao
    UPDATE staging.stg_reserva sr
       SET nome_canonico_patio_devolucao = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sr.sk_fonte
       AND dp.id_natural_origem = sr.patio_devolucao_id_natural;

    -- stg_locacao — retirada
    UPDATE staging.stg_locacao sl
       SET nome_canonico_patio_retirada = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sl.sk_fonte
       AND dp.id_natural_origem = sl.patio_retirada_id_natural;

    -- stg_locacao — devolucao
    UPDATE staging.stg_locacao sl
       SET nome_canonico_patio_devolucao = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sl.sk_fonte
       AND dp.id_natural_origem = sl.patio_devolucao_id_natural;

    -- stg_movimentacao
    UPDATE staging.stg_movimentacao_patio sm
       SET nome_canonico_origem = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sm.sk_fonte
       AND dp.id_natural_origem = sm.patio_origem_id_natural;

    UPDATE staging.stg_movimentacao_patio sm
       SET nome_canonico_destino = dp.nome_canonico
      FROM staging.depara_patio dp
     WHERE dp.sk_fonte          = sm.sk_fonte
       AND dp.id_natural_origem = sm.patio_destino_id_natural;


    -- =====================================================================
    -- 3. APLICAR depara_grupo
    -- =====================================================================
    UPDATE staging.stg_grupo sg
       SET nome_canonico = dg.nome_canonico
      FROM staging.depara_grupo dg
     WHERE dg.sk_fonte      = sg.sk_fonte
       AND dg.codigo_origem = sg.id_natural;

    UPDATE staging.stg_veiculo sv
       SET nome_canonico_grupo = dg.nome_canonico
      FROM staging.depara_grupo dg
     WHERE dg.sk_fonte      = sv.sk_fonte
       AND dg.codigo_origem = sv.grupo_id_natural;

    UPDATE staging.stg_reserva sr
       SET nome_canonico_grupo = dg.nome_canonico
      FROM staging.depara_grupo dg
     WHERE dg.sk_fonte      = sr.sk_fonte
       AND dg.codigo_origem = sr.grupo_id_natural;

    UPDATE staging.stg_locacao sl
       SET nome_canonico_grupo = dg.nome_canonico
      FROM staging.depara_grupo dg
     WHERE dg.sk_fonte      = sl.sk_fonte
       AND dg.codigo_origem = sl.grupo_id_natural;


    -- =====================================================================
    -- 4. NORMALIZAR STATUS
    -- =====================================================================
    -- stg_locacao.status_normalizado: EM_ANDAMENTO / CONCLUIDA / CANCELADA / DESCONHECIDO
    UPDATE staging.stg_locacao
       SET status_normalizado = CASE
            WHEN UPPER(TRIM(status_origem)) IN ('EM_ANDAMENTO','ATIVA')                                 THEN 'EM_ANDAMENTO'
            WHEN UPPER(TRIM(status_origem)) IN ('CONCLUIDA','FINALIZADA','CONCLUÍDA')                   THEN 'CONCLUIDA'
            WHEN UPPER(TRIM(status_origem)) IN ('CANCELADA','CANCELED','CANCELADO')                     THEN 'CANCELADA'
            ELSE 'DESCONHECIDO'
       END;

    -- stg_reserva.status_normalizado:
    -- CONFIRMADA / EM_FILA_ESPERA / CANCELADA / CONCRETIZADA / DESCONHECIDO
    UPDATE staging.stg_reserva
       SET status_normalizado = CASE
            WHEN UPPER(TRIM(status_origem)) IN ('CONFIRMADA','ATIVA','CONFIRMED')             THEN 'CONFIRMADA'
            WHEN UPPER(TRIM(status_origem)) IN ('EM_FILA_ESPERA','ESPERA','WAITING')          THEN 'EM_FILA_ESPERA'
            WHEN UPPER(TRIM(status_origem)) IN ('CANCELADA','CANCELED','CANCELADO')           THEN 'CANCELADA'
            WHEN UPPER(TRIM(status_origem)) IN ('CONCRETIZADA','ATENDIDA','CONVERTIDA')       THEN 'CONCRETIZADA'
            ELSE 'DESCONHECIDO'
       END;


    -- =====================================================================
    -- 5. DERIVAR duracao_real_dias / km_rodados em stg_locacao
    -- =====================================================================
    UPDATE staging.stg_locacao
       SET duracao_real_dias = CASE
              WHEN data_devolucao_real IS NOT NULL AND data_retirada_real IS NOT NULL
              THEN EXTRACT(EPOCH FROM (data_devolucao_real - data_retirada_real))::INTEGER / 86400
              ELSE NULL
           END,
           km_rodados = CASE
              WHEN km_chegada IS NOT NULL AND km_saida IS NOT NULL AND km_chegada >= km_saida
              THEN km_chegada - km_saida
              ELSE NULL
           END;


    -- =====================================================================
    -- 6. TRATAR NULL em cidade_origem do cliente
    -- =====================================================================
    UPDATE staging.stg_cliente
       SET cidade_origem = 'CIDADE_DESCONHECIDA'
     WHERE cidade_origem IS NULL OR cidade_origem = '';


    -- =====================================================================
    -- 7. LOGS DE QUALIDADE (linhas suspeitas)
    -- =====================================================================
    SELECT COUNT(*) INTO v_count
      FROM staging.stg_locacao
     WHERE nome_canonico_patio_retirada IS NULL;
    IF v_count > 0 THEN
      RAISE NOTICE 'AVISO: % linhas em stg_locacao SEM nome_canonico_patio_retirada (serao descartadas no load).', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM staging.stg_reserva
     WHERE nome_canonico_patio_retirada IS NULL;
    IF v_count > 0 THEN
      RAISE NOTICE 'AVISO: % linhas em stg_reserva SEM nome_canonico_patio_retirada (serao descartadas no load).', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM staging.stg_veiculo
     WHERE nome_canonico_patio IS NULL;
    IF v_count > 0 THEN
      RAISE NOTICE 'AVISO: % linhas em stg_veiculo SEM nome_canonico_patio (sem patio mapeado).', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM staging.stg_reserva
     WHERE sk_fonte = 5 AND nome_canonico_grupo IS NULL;
    RAISE NOTICE 'INFO: % reservas da fonte bigdata sem grupo (esperado por P-10 — irao para sk_grupo=0).', v_count;

    RAISE NOTICE '==== Transform DONE ====';
END $$;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/06_transform.sql
-- =====================================================================
