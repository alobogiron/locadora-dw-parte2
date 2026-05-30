-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/03_extract_locadora_db.sql
--  Objetivo: Extract — fonte 3 (src_locadora_db) -> staging.stg_*
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  sk_fonte = 3 (constante).
--  Veiculo: usa coluna id_patio_origem (extensao P-09 da DDL).
-- =====================================================================

SET search_path = staging, public;

DELETE FROM staging.stg_movimentacao_patio WHERE sk_fonte = 3;
DELETE FROM staging.stg_locacao            WHERE sk_fonte = 3;
DELETE FROM staging.stg_reserva            WHERE sk_fonte = 3;
DELETE FROM staging.stg_cliente            WHERE sk_fonte = 3;
DELETE FROM staging.stg_veiculo            WHERE sk_fonte = 3;
DELETE FROM staging.stg_grupo              WHERE sk_fonte = 3;
DELETE FROM staging.stg_patio              WHERE sk_fonte = 3;


-- ---------------------------------------------------------------------
-- stg_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_patio (
    sk_fonte, id_natural, nome_original, endereco, cidade, tipo_local,
    capacidade_vagas, funciona_24h
)
SELECT
    3,
    p.id::TEXT,
    p.nome,
    NULL,
    p.cidade,
    CASE
        WHEN p.nome ILIKE '%Aeroporto%'  THEN 'AEROPORTO'
        WHEN p.nome ILIKE '%Rodoviaria%' THEN 'RODOVIARIA'
        WHEN p.nome ILIKE '%Shopping%'   THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    NULL,
    p.nome ILIKE '%Aeroporto%'
FROM src_locadora_db.patio p;


-- ---------------------------------------------------------------------
-- stg_grupo
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_grupo (
    sk_fonte, id_natural, codigo_origem, nome_origem, classe_luxo,
    valor_diaria, franquia_km_diaria, descricao
)
SELECT
    3,
    g.id::TEXT,
    NULL,
    g.nome,
    NULL,
    NULL,                       -- fonte 3 nao expoe preco
    NULL,
    g.categoria
FROM src_locadora_db.grupo_veiculo g;


-- ---------------------------------------------------------------------
-- stg_veiculo (usa id_patio_origem - extensao P-09)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_veiculo (
    sk_fonte, id_natural, placa, chassi, renavam, marca, modelo, cor,
    ano_fabricacao, mecanizacao, tem_ar_condicionado, km_atual, situacao,
    grupo_id_natural, patio_id_natural
)
SELECT
    3,
    v.id::TEXT,
    v.placa,
    v.chassi,
    NULL,
    v.marca,
    v.modelo,
    v.cor,
    NULL,
    CASE WHEN v.tipo_mecanizacao = 'manual'      THEN 'MANUAL'
         WHEN v.tipo_mecanizacao = 'automatico'  THEN 'AUTOMATICA'
         ELSE 'DESCONHECIDA' END,
    v.ar_condicionado,
    NULL,
    UPPER(v.status),
    v.grupo_id::TEXT,
    v.id_patio_origem::TEXT
FROM src_locadora_db.veiculo v;


-- ---------------------------------------------------------------------
-- stg_cliente
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_cliente (
    sk_fonte, id_natural, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf, cnpj,
    data_nascimento, flag_tem_condutor_associado
)
SELECT
    3,
    c.id::TEXT,
    c.tipo,
    c.nome,
    NULL,
    c.cidade,
    NULL,                                  -- fonte 3 nao expoe UF
    NULL,
    NULL,
    NULL,                                  -- fonte 3 nao expoe cpf/cnpj
    NULL,
    NULL,
    EXISTS (SELECT 1 FROM src_locadora_db.condutor co WHERE co.cliente_id = c.id)
FROM src_locadora_db.cliente c;


-- ---------------------------------------------------------------------
-- stg_reserva
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_reserva (
    sk_fonte, id_natural, cliente_id_natural, grupo_id_natural,
    patio_retirada_id_natural, patio_devolucao_id_natural,
    data_reserva, data_retirada_prevista, data_devolucao_prevista,
    qtd_veiculos_solicitados, valor_previsto, status_origem
)
SELECT
    3,
    r.id::TEXT,
    r.cliente_id::TEXT,
    r.grupo_id::TEXT,
    r.patio_retirada_id::TEXT,
    r.patio_devolucao_id::TEXT,
    r.data_inicio::TIMESTAMP,             -- fonte 3 usa data_inicio como data_reserva
    r.data_inicio::TIMESTAMP,             -- e tambem como data_retirada_prevista
    r.data_fim::TIMESTAMP,
    1,
    NULL,
    r.status
FROM src_locadora_db.reserva r;


-- ---------------------------------------------------------------------
-- stg_locacao
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_locacao (
    sk_fonte, id_natural, numero_contrato, reserva_id_natural,
    cliente_id_natural, veiculo_id_natural, grupo_id_natural,
    patio_retirada_id_natural, patio_devolucao_id_natural,
    data_retirada_real, data_devolucao_real, data_devolucao_prevista,
    km_saida, km_chegada, valor_diaria_aplicada, valor_total_final,
    status_origem
)
SELECT
    3,
    l.id::TEXT,
    NULL,
    l.reserva_id::TEXT,
    co.cliente_id::TEXT,                           -- fonte 3 amarra cliente via condutor
    l.veiculo_id::TEXT,
    v.grupo_id::TEXT,
    l.patio_retirada_id::TEXT,
    -- Real quando ocorrido. NULL se ainda nao devolvido.
    CASE WHEN l.data_devolucao_realizada IS NOT NULL THEN l.patio_devolucao_id::TEXT END,
    l.data_retirada_realizada,
    l.data_devolucao_realizada,
    l.data_devolucao_prevista,
    l.km_entrega,
    l.km_devolucao,
    NULL,                                          -- fonte 3 nao expoe valor_diaria
    NULL,                                          -- nem valor_total_final
    CASE
        WHEN l.data_devolucao_realizada IS NOT NULL THEN 'CONCLUIDA'
        WHEN l.data_retirada_realizada  IS NOT NULL THEN 'EM_ANDAMENTO'
        ELSE 'CANCELADA'
    END
FROM      src_locadora_db.locacao l
LEFT JOIN src_locadora_db.veiculo  v  ON v.id  = l.veiculo_id
LEFT JOIN src_locadora_db.condutor co ON co.id = l.condutor_id;


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_movimentacao_patio (
    sk_fonte, id_natural, veiculo_id_natural,
    patio_origem_id_natural, patio_destino_id_natural,
    data_movimentacao, motivo
)
SELECT
    3,
    m.id::TEXT,
    m.veiculo_id::TEXT,
    m.origem_patio_id::TEXT,
    m.destino_patio_id::TEXT,
    m.data_movimentacao,
    m.motivo
FROM src_locadora_db.movimentacao_patio m;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/03_extract_locadora_db.sql
-- =====================================================================
