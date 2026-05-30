-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/05_extract_bigdata.sql
--  Objetivo: Extract — fonte 5 (src_bigdata) -> staging.stg_*
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  sk_fonte = 5 (constante).
--  Particularidades:
--   - Cliente: UNION ALL (PessoaFisica + Empresa). id_natural = 'PF_'||IDFisica
--     ou 'PJ_'||IDEmpresa; tipo_pessoa derivado.
--   - Cidade via JOIN com Endereco.
--   - Reserva: cidade do cliente via CentroCusto -> PessoaFisica|Empresa -> Endereco
--   - Reserva: SEM grupo (IDCategoria nao existe) -> grupo_id_natural NULL
--     (transform/load coloca em sk_grupo = 0).
--   - Locacao: derivar patio_retirada via Vaga (IDVagaRetirada -> Vaga.IDPatio).
--   - Locacao: patio_devolucao via IDVagaDevolvida (NULL se ainda nao devolvido).
--   - Cliente da locacao via Motorista.IDFisica -> 'PF_'||IDFisica
-- =====================================================================

SET search_path = staging, public;

DELETE FROM staging.stg_movimentacao_patio WHERE sk_fonte = 5;
DELETE FROM staging.stg_locacao            WHERE sk_fonte = 5;
DELETE FROM staging.stg_reserva            WHERE sk_fonte = 5;
DELETE FROM staging.stg_cliente            WHERE sk_fonte = 5;
DELETE FROM staging.stg_veiculo            WHERE sk_fonte = 5;
DELETE FROM staging.stg_grupo              WHERE sk_fonte = 5;
DELETE FROM staging.stg_patio              WHERE sk_fonte = 5;


-- ---------------------------------------------------------------------
-- stg_patio
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_patio (
    sk_fonte, id_natural, nome_original, endereco, cidade, tipo_local,
    capacidade_vagas, funciona_24h
)
SELECT
    5,
    p.IDPatio::TEXT,
    -- bigdata so tem CDPatio (codigo); reusa para nome_original; o de-para
    -- usa o IDPatio para reconciliar com os nomes canonicos.
    p.CDPatio,
    e.Logradouro || ', ' || e.Numero || COALESCE(' - ' || e.Bairro, ''),
    e.Cidade,
    CASE
        WHEN p.CDPatio ILIKE '%GIG%' OR p.CDPatio ILIKE '%SDU%' THEN 'AEROPORTO'
        WHEN p.CDPatio ILIKE '%ROD%'                            THEN 'RODOVIARIA'
        WHEN p.CDPatio ILIKE '%NAM%' OR p.CDPatio ILIKE '%RSL%' OR p.CDPatio ILIKE '%BRR%' THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    p.Lotacao,
    (p.HorarioAbertura = TIME '00:00' AND p.HorarioFechamento >= TIME '23:59')
FROM      src_bigdata.Patio p
LEFT JOIN src_bigdata.Endereco e ON e.IDEndereco = p.IDEndereco;


-- ---------------------------------------------------------------------
-- stg_grupo (Categoria)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_grupo (
    sk_fonte, id_natural, codigo_origem, nome_origem, classe_luxo,
    valor_diaria, franquia_km_diaria, descricao
)
SELECT
    5,
    c.IDCategoria::TEXT,
    NULL,
    c.Classificacao,
    -- ClasseLuxo em bigdata eh CHAR(1): A/B/C -> LUXO/INTERMEDIARIO/ECONOMICO
    CASE c.ClasseLuxo
        WHEN 'A' THEN 'LUXO'
        WHEN 'B' THEN 'INTERMEDIARIO'
        WHEN 'C' THEN 'ECONOMICO'
        ELSE 'DESCONHECIDA' END,
    c.ValorDiariaBase,
    NULL,
    c.Classificacao
FROM src_bigdata.Categoria c;


-- ---------------------------------------------------------------------
-- stg_veiculo
-- patio_id_natural: bigdata nao tem amarracao direta veiculo->patio.
-- Atribuir todos ao patio dono (IDPatio=1 = Shopping Nova America).
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_veiculo (
    sk_fonte, id_natural, placa, chassi, renavam, marca, modelo, cor,
    ano_fabricacao, mecanizacao, tem_ar_condicionado, tem_cadeira_infantil,
    km_atual, situacao, grupo_id_natural, patio_id_natural
)
SELECT
    5,
    v.IDVeiculo::TEXT,
    v.Placa,
    v.Chassi,
    NULL,
    NULL,                                     -- bigdata nao expoe marca
    v.Modelo,
    NULL,                                     -- nem cor
    v.Ano,
    'DESCONHECIDA',                           -- bigdata nao expoe mecanizacao
    v.ArCondicionado,
    v.CadeiraInfantil,
    v.UltimaKilometragem,
    'DISPONIVEL',                             -- bigdata nao expoe status
    v.IDCategoria::TEXT,
    '1'                                       -- todos no patio dono (Nova America)
FROM src_bigdata.Veiculo v;


-- ---------------------------------------------------------------------
-- stg_cliente (UNION ALL PF + PJ)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_cliente (
    sk_fonte, id_natural, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf, cnpj,
    data_nascimento, flag_tem_condutor_associado
)
SELECT
    5,
    'PF_' || pf.IDFisica,
    'PF',
    pf.Nome,
    NULL,
    e.Cidade,
    e.UF,
    NULL,
    pf.Telefone,
    pf.CPF,
    NULL,
    pf.DtNascimento,
    TRUE                                       -- toda PF eh motorista nesta fonte
FROM      src_bigdata.PessoaFisica pf
LEFT JOIN src_bigdata.Endereco e ON e.IDEndereco = pf.IDEndereco

UNION ALL

SELECT
    5,
    'PJ_' || emp.IDEmpresa,
    'PJ',
    emp.RazaoSocial,
    NULL,
    e.Cidade,
    e.UF,
    NULL,
    emp.Telefone,
    NULL,
    emp.CNPJ,
    NULL,
    FALSE
FROM      src_bigdata.Empresa emp
LEFT JOIN src_bigdata.Endereco e ON e.IDEndereco = emp.IDEndereco;


-- ---------------------------------------------------------------------
-- stg_reserva
-- cliente_id_natural via CentroCusto: PF_||IDFisica OU PJ_||IDEmpresa (XOR).
-- grupo_id_natural: NULL (bigdata nao expoe IDCategoria em Reserva — P-10).
-- patio_retirada/devolucao: bigdata nao tem em Reserva. Sentinela patio_id=1.
-- (uma extensao similar a P-09 seria possivel, mas para reserva o impacto
--  no relatorio (c) eh menor: usamos o patio dono — Nova America id=1.)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_reserva (
    sk_fonte, id_natural, cliente_id_natural, grupo_id_natural,
    patio_retirada_id_natural, patio_devolucao_id_natural,
    data_reserva, data_retirada_prevista, data_devolucao_prevista,
    qtd_veiculos_solicitados, valor_previsto, status_origem
)
SELECT
    5,
    r.IDReserva::TEXT,
    CASE
        WHEN cc.IDFisica  IS NOT NULL THEN 'PF_' || cc.IDFisica
        WHEN cc.IDEmpresa IS NOT NULL THEN 'PJ_' || cc.IDEmpresa
    END,
    NULL,                                          -- bigdata nao expoe grupo na reserva (P-10)
    '1',                                           -- patio retirada: patio dono
    '1',                                           -- patio devolucao: patio dono
    r.DtReserva,
    r.DtRetiradaPrevista,
    r.DtLimiteRetirada,
    r.QtVeiculosSolicitados,
    NULL,
    r.Status
FROM      src_bigdata.Reserva     r
LEFT JOIN src_bigdata.CentroCusto cc ON cc.IDCentroCusto = r.IDCentroCusto
-- nao puxar reservas-stub (101..160): existem so para satisfazer FK de Locacao
WHERE r.IDReserva <= 100;


-- ---------------------------------------------------------------------
-- stg_locacao
-- cliente via Motorista -> PessoaFisica (id_natural 'PF_'||IDFisica)
-- patio_retirada via Vaga.IDPatio
-- patio_devolucao via IDVagaDevolvida (se nao NULL)
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
    5,
    l.IDLocacao::TEXT,
    NULL,
    l.IDReserva::TEXT,
    'PF_' || mot.IDFisica,
    l.IDVeiculo::TEXT,
    v.IDCategoria::TEXT,
    vag_ret.IDPatio::TEXT,
    CASE WHEN l.DtChegada IS NOT NULL THEN vag_dev.IDPatio::TEXT END,
    l.DtRetirada,
    l.DtChegada,
    l.DtRetirada + INTERVAL '5 days',          -- bigdata nao tem prevista; estima
    NULL,
    NULL,
    l.ValorDiaria,
    NULL,
    CASE WHEN l.DtChegada IS NOT NULL THEN 'CONCLUIDA' ELSE 'EM_ANDAMENTO' END
FROM      src_bigdata.Locacao   l
LEFT JOIN src_bigdata.Veiculo   v       ON v.IDVeiculo = l.IDVeiculo
LEFT JOIN src_bigdata.Motorista mot     ON mot.IDMotorista = l.IDMotorista
LEFT JOIN src_bigdata.Vaga      vag_ret ON vag_ret.IDVaga  = l.IDVagaRetirada
LEFT JOIN src_bigdata.Vaga      vag_dev ON vag_dev.IDVaga  = l.IDVagaDevolvida;


-- ---------------------------------------------------------------------
-- stg_movimentacao_patio (via Vagas)
-- ---------------------------------------------------------------------
INSERT INTO staging.stg_movimentacao_patio (
    sk_fonte, id_natural, veiculo_id_natural,
    patio_origem_id_natural, patio_destino_id_natural,
    data_movimentacao, motivo
)
SELECT
    5,
    m.IDMovimentacao::TEXT,
    m.IDVeiculo::TEXT,
    vag_o.IDPatio::TEXT,
    vag_d.IDPatio::TEXT,
    m.DtRetirada,
    'Movimentacao via vaga'
FROM      src_bigdata.Movimentacao m
LEFT JOIN src_bigdata.Vaga vag_o ON vag_o.IDVaga = m.IDVagaOrigem
LEFT JOIN src_bigdata.Vaga vag_d ON vag_d.IDVaga = m.IDVagaDestino;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/05_extract_bigdata.sql
-- =====================================================================
