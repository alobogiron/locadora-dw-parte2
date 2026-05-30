-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/02_extract_mae016.sql
--  Objetivo: Extract — fonte 2 (src_mae016) -> staging.stg_*
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  sk_fonte = 2 (constante).
--  Locacao: 3 caminhos de patio. Usamos SEMPRE id_patio_devolucao_real
--  para stg_locacao.patio_devolucao_id_natural (MOD-05). NULL se ainda
--  nao devolvido.
-- =====================================================================

SET search_path = staging, public;

DELETE FROM staging.stg_movimentacao_patio WHERE sk_fonte = 2;
DELETE FROM staging.stg_locacao            WHERE sk_fonte = 2;
DELETE FROM staging.stg_reserva            WHERE sk_fonte = 2;
DELETE FROM staging.stg_cliente            WHERE sk_fonte = 2;
DELETE FROM staging.stg_veiculo            WHERE sk_fonte = 2;
DELETE FROM staging.stg_grupo              WHERE sk_fonte = 2;
DELETE FROM staging.stg_patio              WHERE sk_fonte = 2;


-- ---------------------------------------------------------------------
-- stg_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_patio (
    sk_fonte, id_natural, nome_original, endereco, cidade, tipo_local,
    capacidade_vagas, funciona_24h
)
SELECT
    2,
    p.id_patio::TEXT,
    p.nome_patio,
    p.localizacao,
    'Rio de Janeiro',
    CASE
        WHEN p.nome_patio ILIKE '%Aeroporto%'  THEN 'AEROPORTO'
        WHEN p.nome_patio ILIKE '%Rodoviaria%' THEN 'RODOVIARIA'
        WHEN p.nome_patio ILIKE '%Shopping%'   THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    NULL,
    p.nome_patio ILIKE '%Aeroporto%'
FROM src_mae016.PATIO p;


-- ---------------------------------------------------------------------
-- stg_grupo
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_grupo (
    sk_fonte, id_natural, codigo_origem, nome_origem, classe_luxo,
    valor_diaria, franquia_km_diaria, descricao
)
SELECT
    2,
    g.id_grupo::TEXT,
    NULL,
    g.nome_grupo,
    NULL,
    g.faixa_valor_diaria,
    NULL,
    g.descricao
FROM src_mae016.GRUPO_VEICULO g;


-- ---------------------------------------------------------------------
-- stg_veiculo
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_veiculo (
    sk_fonte, id_natural, placa, chassi, renavam, marca, modelo, cor,
    ano_fabricacao, mecanizacao, tem_ar_condicionado, km_atual, situacao,
    grupo_id_natural, patio_id_natural
)
SELECT
    2,
    v.id_veiculo::TEXT,
    v.placa,
    v.chassi,
    NULL,                                       -- mae016 nao expoe renavam
    v.marca,
    v.modelo,
    v.cor,
    NULL,                                       -- nao expoe ano
    CASE WHEN v.mecanizacao = 'AUTOMATICO' THEN 'AUTOMATICA' ELSE v.mecanizacao END,
    v.ar_condicionado,
    NULL,                                       -- mae016 nao expoe km_atual
    v.status,
    v.id_grupo::TEXT,
    v.id_patio_atual::TEXT
FROM src_mae016.VEICULO v;


-- ---------------------------------------------------------------------
-- stg_cliente
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_cliente (
    sk_fonte, id_natural, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf, cnpj,
    data_nascimento, flag_tem_condutor_associado
)
SELECT
    2,
    c.id_cliente::TEXT,
    c.tipo_cliente,
    c.nome_razao_social,
    NULL,
    c.cidade,
    c.estado,
    c.email,
    c.telefone,
    CASE WHEN c.tipo_cliente = 'PF' THEN c.cpf_cnpj END,
    CASE WHEN c.tipo_cliente = 'PJ' THEN c.cpf_cnpj END,
    NULL,
    EXISTS (SELECT 1 FROM src_mae016.CONDUTOR co WHERE co.id_cliente = c.id_cliente)
FROM src_mae016.CLIENTE c;


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
    2,
    r.id_reserva::TEXT,
    r.id_cliente::TEXT,
    r.id_grupo::TEXT,
    r.id_patio_retirada::TEXT,
    r.id_patio_devolucao_previsto::TEXT,
    r.data_reserva::TIMESTAMP,
    r.data_prev_retirada::TIMESTAMP,
    r.data_prev_devolucao::TIMESTAMP,
    1,
    NULL,
    r.status_reserva
FROM src_mae016.RESERVA r;


-- ---------------------------------------------------------------------
-- stg_locacao
-- patio_devolucao = id_patio_devolucao_real (MOD-05); NULL se NULL na fonte.
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
    2,
    l.id_locacao::TEXT,
    NULL,
    l.id_reserva::TEXT,
    l.id_cliente::TEXT,
    l.id_veiculo::TEXT,
    v.id_grupo::TEXT,
    l.id_patio_retirada::TEXT,
    l.id_patio_devolucao_real::TEXT,
    l.data_hora_retirada,
    l.data_hora_real_devolucao,
    l.data_hora_prev_devolucao,
    NULL,
    NULL,
    NULL,                                       -- mae016 nao expoe valor_diaria
    l.valor_final,
    l.status_locacao
FROM      src_mae016.LOCACAO l
LEFT JOIN src_mae016.VEICULO v ON v.id_veiculo = l.id_veiculo;


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_movimentacao_patio (
    sk_fonte, id_natural, veiculo_id_natural,
    patio_origem_id_natural, patio_destino_id_natural,
    data_movimentacao, motivo
)
SELECT
    2,
    m.id_movimentacao::TEXT,
    m.id_veiculo::TEXT,
    m.id_patio_origem::TEXT,
    m.id_patio_destino::TEXT,
    m.data_hora_movimentacao,
    m.motivo_movimentacao
FROM src_mae016.MOVIMENTACAO_PATIO m;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/02_extract_mae016.sql
-- =====================================================================
