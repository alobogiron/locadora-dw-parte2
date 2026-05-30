-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/01_extract_andre_gustavo.sql
--  Objetivo: Extract — fonte 1 (src_andre_gustavo) -> staging.stg_*
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  sk_fonte = 1 (constante).
--  Idempotente: DELETE WHERE sk_fonte = 1 antes de inserir.
--  Status normalizados sao preenchidos no Transform (06_transform.sql).
-- =====================================================================

SET search_path = staging, public;

-- ---------------------------------------------------------------------
-- Limpeza idempotente (so a fatia desta fonte).
-- ---------------------------------------------------------------------
DELETE FROM staging.stg_movimentacao_patio WHERE sk_fonte = 1;
DELETE FROM staging.stg_locacao            WHERE sk_fonte = 1;
DELETE FROM staging.stg_reserva            WHERE sk_fonte = 1;
DELETE FROM staging.stg_cliente            WHERE sk_fonte = 1;
DELETE FROM staging.stg_veiculo            WHERE sk_fonte = 1;
DELETE FROM staging.stg_grupo              WHERE sk_fonte = 1;
DELETE FROM staging.stg_patio              WHERE sk_fonte = 1;


-- ---------------------------------------------------------------------
-- stg_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_patio (
    sk_fonte, id_natural, nome_original, endereco, cidade, tipo_local,
    capacidade_vagas, funciona_24h
)
SELECT
    1,
    p.id_patio::TEXT,
    p.nome,
    p.endereco,
    'Rio de Janeiro',          -- todas as fontes 1 sao no Rio (seed)
    CASE
        WHEN p.nome ILIKE '%Aeroporto%'  THEN 'AEROPORTO'
        WHEN p.nome ILIKE '%Rodoviaria%' THEN 'RODOVIARIA'
        WHEN p.nome ILIKE '%Shopping%'   THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    p.capacidade_vagas,
    p.nome ILIKE '%Aeroporto%'  -- aproximacao: aeroportos 24h
FROM src_andre_gustavo.patio p;


-- ---------------------------------------------------------------------
-- stg_grupo
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_grupo (
    sk_fonte, id_natural, codigo_origem, nome_origem, classe_luxo,
    valor_diaria, franquia_km_diaria, descricao
)
SELECT
    1,
    g.id_grupo::TEXT,
    g.codigo,
    g.nome,
    g.classe_luxo,
    g.valor_diaria,
    g.franquia_km_diaria,
    g.nome
FROM src_andre_gustavo.grupo g;


-- ---------------------------------------------------------------------
-- stg_veiculo
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_veiculo (
    sk_fonte, id_natural, placa, chassi, renavam, marca, modelo, cor,
    ano_fabricacao, mecanizacao, tem_ar_condicionado, km_atual, situacao,
    grupo_id_natural, patio_id_natural
)
SELECT
    1,
    v.id_veiculo::TEXT,
    v.placa,
    v.chassi,
    v.renavam,
    v.marca,
    v.modelo,
    v.cor,
    v.ano_fabricacao,
    v.mecanizacao,            -- ja vem MANUAL/AUTOMATICA
    v.tem_ar_condicionado,
    v.km_atual,
    v.situacao,
    v.grupo_id::TEXT,
    v.patio_origem_id::TEXT
FROM src_andre_gustavo.veiculo v;


-- ---------------------------------------------------------------------
-- stg_cliente (PF + PJ unificados via cliente; LEFT JOIN nos detalhes)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_cliente (
    sk_fonte, id_natural, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf, cnpj,
    data_nascimento, flag_tem_condutor_associado
)
SELECT
    1,
    c.id_cliente::TEXT,
    c.tipo_pessoa,
    c.nome,
    cpj.nome_fantasia,
    c.cidade_origem,
    NULL,                                  -- fonte 1 nao expoe UF
    c.email,
    c.telefone,
    cpf.cpf,
    cpj.cnpj,
    cpf.data_nascimento,
    EXISTS (SELECT 1 FROM src_andre_gustavo.condutor co WHERE co.cliente_pj_id = c.id_cliente)
FROM      src_andre_gustavo.cliente c
LEFT JOIN src_andre_gustavo.cliente_pf cpf ON cpf.cliente_id = c.id_cliente
LEFT JOIN src_andre_gustavo.cliente_pj cpj ON cpj.cliente_id = c.id_cliente;


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
    1,
    r.id_reserva::TEXT,
    r.cliente_id::TEXT,
    r.grupo_id::TEXT,
    r.patio_retirada_id::TEXT,
    r.patio_devolucao_id::TEXT,
    r.data_reserva,
    r.data_retirada_prevista,
    r.data_devolucao_prevista,
    1,
    NULL,
    r.estado
FROM src_andre_gustavo.reserva r;


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
    1,
    l.id_locacao::TEXT,
    l.numero_contrato,
    l.reserva_id::TEXT,
    l.cliente_id::TEXT,
    l.veiculo_id::TEXT,
    v.grupo_id::TEXT,
    l.patio_retirada_id::TEXT,
    -- Sempre o REAL quando ocorrido. NULL se EM_ANDAMENTO/CANCELADA sem devolucao.
    CASE WHEN l.data_devolucao_real IS NOT NULL THEN l.patio_devolucao_id::TEXT END,
    l.data_retirada_real,
    l.data_devolucao_real,
    -- fonte 1 nao tem data_devolucao_prevista explicita; estima como
    -- data_retirada + duracao tipica (5 dias) para o atributo previsto.
    l.data_retirada_real + INTERVAL '5 days',
    l.km_saida,
    l.km_chegada,
    l.valor_diaria_aplicada,
    NULL,
    l.status
FROM      src_andre_gustavo.locacao l
LEFT JOIN src_andre_gustavo.veiculo v ON v.id_veiculo = l.veiculo_id;


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio  (fonte 1 nao tem essa tabela — pulo)
-- ---------------------------------------------------------------------


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/01_extract_andre_gustavo.sql
-- =====================================================================
