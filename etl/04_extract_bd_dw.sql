-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/04_extract_bd_dw.sql
--  Objetivo: Extract — fonte 4 (src_bd_dw_26_1) -> staging.stg_*
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  sk_fonte = 4 (constante).
--  Cliente: JOIN com Endereco (via Id_endereco) para extrair cidade.
--  Cliente: tipo_pessoa vem do discriminador Cliente.Tipo_cliente.
--  Veiculo: nao tem patio direto -> infere pela empresa proprietaria
--  (todos os 20 veiculos sao da empresa propria id=1 -> patio Shopping Rio Sul id=1).
-- =====================================================================

SET search_path = staging, public;

DELETE FROM staging.stg_movimentacao_patio WHERE sk_fonte = 4;
DELETE FROM staging.stg_locacao            WHERE sk_fonte = 4;
DELETE FROM staging.stg_reserva            WHERE sk_fonte = 4;
DELETE FROM staging.stg_cliente            WHERE sk_fonte = 4;
DELETE FROM staging.stg_veiculo            WHERE sk_fonte = 4;
DELETE FROM staging.stg_grupo              WHERE sk_fonte = 4;
DELETE FROM staging.stg_patio              WHERE sk_fonte = 4;


-- ---------------------------------------------------------------------
-- stg_patio (join com Endereco para cidade/endereco)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_patio (
    sk_fonte, id_natural, nome_original, endereco, cidade, tipo_local,
    capacidade_vagas, funciona_24h
)
SELECT
    4,
    p.Id_patio::TEXT,
    p.Nome_patio,
    e.Logradouro || ', ' || e.Numero || COALESCE(' - ' || e.Bairro, ''),
    e.Cidade,
    CASE
        WHEN p.Nome_patio ILIKE '%Aeroporto%'  THEN 'AEROPORTO'
        WHEN p.Nome_patio ILIKE '%Rodoviaria%' THEN 'RODOVIARIA'
        WHEN p.Nome_patio ILIKE '%Shopping%'   THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    p.Capacidade,
    p.Funciona_24h
FROM      src_bd_dw_26_1.Patio p
LEFT JOIN src_bd_dw_26_1.Endereco e ON e.Id_endereco = p.Id_endereco;


-- ---------------------------------------------------------------------
-- stg_grupo (Categoria)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_grupo (
    sk_fonte, id_natural, codigo_origem, nome_origem, classe_luxo,
    valor_diaria, franquia_km_diaria, descricao
)
SELECT
    4,
    c.Id_categoria::TEXT,
    NULL,
    c.Nome_categoria,
    NULL,
    c.Valor_diaria_base,
    NULL,
    c.Descricao_categoria
FROM src_bd_dw_26_1.Categoria c;


-- ---------------------------------------------------------------------
-- stg_veiculo
-- patio_id_natural: a fonte 4 nao amarra veiculo->patio; todos sao
-- da empresa propria (Id_empresa=1 -> Shopping Rio Sul, Patio id=1).
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_veiculo (
    sk_fonte, id_natural, placa, chassi, renavam, marca, modelo, cor,
    ano_fabricacao, mecanizacao, tem_ar_condicionado,
    capacidade_pessoas, capacidade_porta_malas, categoria_dimensoes,
    km_atual, situacao, grupo_id_natural, patio_id_natural
)
SELECT
    4,
    v.Id_veiculo::TEXT,
    v.Placa,
    v.Chassi,
    NULL,
    v.Marca,
    v.Modelo,
    v.Cor,
    v.Ano,
    CASE WHEN v.Tipo_cambio ILIKE '%automatic%' THEN 'AUTOMATICA'
         WHEN v.Tipo_cambio ILIKE '%manual%'    THEN 'MANUAL'
         ELSE 'DESCONHECIDA' END,
    v.Possui_ar_condicionado,
    v.Capacidade_pessoas,
    v.Capacidade_porta_malas,
    v.Dimensoes,
    v.Km_atual,
    v.Status_veiculo,
    v.Id_categoria::TEXT,
    -- todos os veiculos da fonte 4 sao da empresa 1 (BD-DW) -> patio 1 (Rio Sul)
    CASE WHEN v.Id_empresa = 1 THEN '1' ELSE v.Id_empresa::TEXT END
FROM src_bd_dw_26_1.Veiculo v;


-- ---------------------------------------------------------------------
-- stg_cliente (LEFT JOIN com Cliente_pf, Cliente_pj e Endereco)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_cliente (
    sk_fonte, id_natural, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf, cnpj,
    data_nascimento, flag_tem_condutor_associado
)
SELECT
    4,
    c.Id_cliente::TEXT,
    c.Tipo_cliente,
    COALESCE(pf.Nome_cliente, pj.Razao_social),
    pj.Nome_fantasia,
    e.Cidade,
    e.Uf,
    c.Email_cliente,
    c.Telefone_cliente,
    pf.Cpf_cliente,
    pj.Cnpj_cliente,
    pf.Data_nascimento_cliente,
    EXISTS (SELECT 1 FROM src_bd_dw_26_1.Motorista m WHERE m.Id_cliente = c.Id_cliente)
FROM      src_bd_dw_26_1.Cliente c
LEFT JOIN src_bd_dw_26_1.Cliente_pf pf ON pf.Id_cliente = c.Id_cliente
LEFT JOIN src_bd_dw_26_1.Cliente_pj pj ON pj.Id_cliente = c.Id_cliente
LEFT JOIN src_bd_dw_26_1.Endereco   e  ON e.Id_endereco = c.Id_endereco;


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
    4,
    r.Id_reserva::TEXT,
    r.Id_cliente::TEXT,
    r.Id_categoria::TEXT,
    r.Id_patio_previsto_retirada::TEXT,
    r.Id_patio_previsto_devolucao::TEXT,
    r.Data_hora_reserva,
    r.Data_previsao_retirada,
    r.Data_previsao_devolucao,
    1,
    r.Valor_previsto,
    r.Status_reserva
FROM src_bd_dw_26_1.Reserva r
-- nao puxar reservas-stub (Id_reserva > 100): elas existem so para satisfazer FK 1:1 de Locacao
WHERE r.Id_reserva <= 100;


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
    4,
    l.Id_locacao::TEXT,
    NULL,
    l.Id_reserva::TEXT,
    m.Id_cliente::TEXT,                            -- via motorista
    l.Id_veiculo::TEXT,
    v.Id_categoria::TEXT,
    l.Id_patio_real_retirada::TEXT,
    CASE WHEN l.Data_hora_devolucao_real IS NOT NULL THEN l.Id_patio_real_devolucao::TEXT END,
    l.Data_hora_retirada_real,
    l.Data_hora_devolucao_real,
    -- usar previsao da reserva-stub correspondente (Id_reserva 101..160)
    r_stub.Data_previsao_devolucao,
    l.Km_retirada,
    l.Km_devolucao,
    NULL,                                          -- valor_diaria_aplicada nao explicito; pode derivar de Valor_total_final/duracao
    l.Valor_total_final,
    l.Status_locacao
FROM      src_bd_dw_26_1.Locacao    l
LEFT JOIN src_bd_dw_26_1.Veiculo    v       ON v.Id_veiculo = l.Id_veiculo
LEFT JOIN src_bd_dw_26_1.Motorista  m       ON m.Id_motorista = l.Id_motorista
LEFT JOIN src_bd_dw_26_1.Reserva    r_stub  ON r_stub.Id_reserva = l.Id_reserva;


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio  (fonte 4 nao tem essa tabela)
-- ---------------------------------------------------------------------


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/04_extract_bd_dw.sql
-- =====================================================================
