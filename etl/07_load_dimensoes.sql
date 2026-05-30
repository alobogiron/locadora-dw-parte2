-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: etl/07_load_dimensoes.sql
--  Objetivo: Load — popula as dimensoes do DW a partir das stg_*.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Ordem: dim_fonte -> dim_patio -> dim_grupo -> dim_veiculo -> dim_cliente.
--  Idempotente: DELETE seletivo (preservando sentinelas sk_*=0).
-- =====================================================================

SET search_path = dw, staging, public;


-- =====================================================================
-- 1. dim_fonte (5 linhas reais + sentinela ja existe sk_fonte=0)
-- Idempotencia: UPSERT (ON CONFLICT) preserva sk_fonte estavel.
-- =====================================================================
INSERT INTO dw.dim_fonte (sk_fonte, codigo_fonte, nome_empresa_associada, sgbd_original, descricao) VALUES
  (1, 'andre_gustavo', 'Grupo Gustavo + Andre',                  'POSTGRES', 'Fonte Parte I do proprio grupo; Postgres nativo.'),
  (2, 'mae016',         'Grupo MAE016 (Breno, Hygor, Joao)',     'MYSQL',    'Sistema MAE016 traduzido de MySQL para Postgres.'),
  (3, 'locadora_db',    'Grupo Locadora-DB (Tadeu, Vicente)',    'POSTGRES', 'Sistema Locadora-DB; veiculo->patio extensao P-09.'),
  (4, 'bd_dw_26_1',     'Grupo BD-DW-26.1 (Ana, Mariana, +)',    'MYSQL',    'Sistema BD-DW traduzido de MySQL para Postgres.'),
  (5, 'bigdata',        'Grupo BigData',                          'ANSI',     'Sistema BigData ANSI. Reserva sem categoria (P-10).')
ON CONFLICT (sk_fonte) DO UPDATE SET
  codigo_fonte           = EXCLUDED.codigo_fonte,
  nome_empresa_associada = EXCLUDED.nome_empresa_associada,
  sgbd_original          = EXCLUDED.sgbd_original,
  descricao              = EXCLUDED.descricao;


-- =====================================================================
-- 2. dim_patio
-- Idempotencia: ON CONFLICT (nome_canonico) DO UPDATE.
-- =====================================================================
INSERT INTO dw.dim_patio (
    nome_canonico, apelido, tipo_local, cidade, endereco_descritivo,
    capacidade_vagas_referencia, flag_funciona_24h, codigo_fonte_dona
)
SELECT
    p.nome_canonico,
    CASE p.nome_canonico
        WHEN 'Aeroporto do Galeao'     THEN 'Galeao'
        WHEN 'Aeroporto Santos Dumont' THEN 'Santos Dumont'
        WHEN 'Rodoviaria do Rio'       THEN 'Rodoviaria'
        WHEN 'Shopping Rio Sul'        THEN 'Rio Sul'
        WHEN 'Shopping Nova America'   THEN 'Nova America'
        WHEN 'Barra Shopping'          THEN 'Barra'
        ELSE p.nome_canonico
    END,
    CASE
        WHEN p.nome_canonico ILIKE '%Aeroporto%'  THEN 'AEROPORTO'
        WHEN p.nome_canonico ILIKE '%Rodoviaria%' THEN 'RODOVIARIA'
        WHEN p.nome_canonico ILIKE '%Shopping%'   THEN 'SHOPPING'
        WHEN p.nome_canonico ILIKE '%Barra%'      THEN 'SHOPPING'
        ELSE 'DESCONHECIDO'
    END,
    'Rio de Janeiro',
    -- Endereco de referencia (primeiro encontrado dentre as fontes).
    (SELECT MAX(sp.endereco)
       FROM staging.stg_patio sp
      WHERE sp.nome_canonico = p.nome_canonico),
    -- Capacidade de referencia (maxima entre as fontes).
    (SELECT MAX(sp.capacidade_vagas)
       FROM staging.stg_patio sp
      WHERE sp.nome_canonico = p.nome_canonico),
    -- 24h: TRUE se pelo menos uma fonte marcou TRUE.
    COALESCE((SELECT BOOL_OR(sp.funciona_24h)
                FROM staging.stg_patio sp
               WHERE sp.nome_canonico = p.nome_canonico), FALSE),
    CASE p.nome_canonico
        WHEN 'Aeroporto do Galeao'     THEN 'andre_gustavo'
        WHEN 'Aeroporto Santos Dumont' THEN 'mae016'
        WHEN 'Rodoviaria do Rio'       THEN 'locadora_db'
        WHEN 'Shopping Rio Sul'        THEN 'bd_dw_26_1'
        WHEN 'Shopping Nova America'   THEN 'bigdata'
        WHEN 'Barra Shopping'          THEN NULL  -- sexta empresa sem sistema (P-07)
    END
FROM (
    SELECT DISTINCT nome_canonico
      FROM staging.depara_patio
) p
ORDER BY p.nome_canonico
ON CONFLICT (nome_canonico) DO UPDATE SET
  apelido                     = EXCLUDED.apelido,
  tipo_local                  = EXCLUDED.tipo_local,
  cidade                      = EXCLUDED.cidade,
  endereco_descritivo         = EXCLUDED.endereco_descritivo,
  capacidade_vagas_referencia = EXCLUDED.capacidade_vagas_referencia,
  flag_funciona_24h           = EXCLUDED.flag_funciona_24h,
  codigo_fonte_dona           = EXCLUDED.codigo_fonte_dona;


-- =====================================================================
-- 3. dim_grupo (sentinela sk_grupo=0 ja existe)
-- Idempotencia: ON CONFLICT (nome_grupo_normalizado) DO UPDATE.
-- =====================================================================
INSERT INTO dw.dim_grupo (
    nome_grupo_normalizado, codigo_curto, classe_luxo,
    valor_diaria_referencia, franquia_km_diaria_referencia, descricao
)
SELECT
    g.nome_canonico,
    NULL,
    -- classe_luxo: agregada por moda (mais comum) entre as fontes que expoem.
    COALESCE(
      (SELECT CASE UPPER(TRIM(sg2.classe_luxo))
                WHEN 'LUXO'          THEN 'LUXO'
                WHEN 'INTERMEDIARIO' THEN 'INTERMEDIARIO'
                WHEN 'ECONOMICO'     THEN 'ECONOMICO'
                ELSE 'DESCONHECIDA' END
         FROM staging.stg_grupo sg2
         JOIN staging.depara_grupo dg2
              ON dg2.sk_fonte = sg2.sk_fonte AND dg2.codigo_origem = sg2.id_natural
        WHERE dg2.nome_canonico = g.nome_canonico
          AND sg2.classe_luxo IS NOT NULL
          AND TRIM(sg2.classe_luxo) <> ''                                    -- filtra fontes que nao expuseram
        GROUP BY UPPER(TRIM(sg2.classe_luxo))
        ORDER BY COUNT(*) DESC
        LIMIT 1),
      'DESCONHECIDA'
    ),
    -- valor_diaria_referencia: media simples das fontes que expoem (LEVE-05).
    (SELECT AVG(sg2.valor_diaria)
       FROM staging.stg_grupo sg2
       JOIN staging.depara_grupo dg2
            ON dg2.sk_fonte = sg2.sk_fonte AND dg2.codigo_origem = sg2.id_natural
      WHERE dg2.nome_canonico = g.nome_canonico AND sg2.valor_diaria IS NOT NULL),
    NULL,
    g.nome_canonico
FROM (
    SELECT DISTINCT nome_canonico
      FROM staging.depara_grupo
) g
ORDER BY g.nome_canonico
ON CONFLICT (nome_grupo_normalizado) DO UPDATE SET
  classe_luxo             = EXCLUDED.classe_luxo,
  valor_diaria_referencia = EXCLUDED.valor_diaria_referencia,
  descricao               = EXCLUDED.descricao;


-- =====================================================================
-- 4. dim_veiculo
-- Idempotencia: ON CONFLICT (sk_fonte_origem, id_natural_origem) DO UPDATE.
-- =====================================================================
INSERT INTO dw.dim_veiculo (
    sk_fonte_origem, id_natural_origem, placa, chassi, renavam,
    marca, modelo, cor, ano_fabricacao, mecanizacao,
    tem_ar_condicionado, tem_adaptacao_cadeirante,
    capacidade_pessoas, capacidade_porta_malas, categoria_dimensoes,
    situacao_atual
)
SELECT
    sv.sk_fonte,
    sv.id_natural,
    sv.placa,
    sv.chassi,
    sv.renavam,
    COALESCE(NULLIF(sv.marca, ''), 'DESCONHECIDA'),
    COALESCE(NULLIF(sv.modelo, ''), 'DESCONHECIDO'),
    sv.cor,
    sv.ano_fabricacao,
    CASE sv.mecanizacao
        WHEN 'MANUAL'       THEN 'MANUAL'
        WHEN 'AUTOMATICA'   THEN 'AUTOMATICA'
        ELSE 'DESCONHECIDA'
    END,
    sv.tem_ar_condicionado,
    sv.tem_cadeira_infantil,
    sv.capacidade_pessoas,
    sv.capacidade_porta_malas,
    sv.categoria_dimensoes,
    CASE
        WHEN sv.situacao IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO','RESERVADO') THEN sv.situacao
        ELSE 'DESCONHECIDA'
    END
FROM staging.stg_veiculo sv
ON CONFLICT (sk_fonte_origem, id_natural_origem) DO UPDATE SET
  placa                    = EXCLUDED.placa,
  chassi                   = EXCLUDED.chassi,
  renavam                  = EXCLUDED.renavam,
  marca                    = EXCLUDED.marca,
  modelo                   = EXCLUDED.modelo,
  cor                      = EXCLUDED.cor,
  ano_fabricacao           = EXCLUDED.ano_fabricacao,
  mecanizacao              = EXCLUDED.mecanizacao,
  tem_ar_condicionado      = EXCLUDED.tem_ar_condicionado,
  tem_adaptacao_cadeirante = EXCLUDED.tem_adaptacao_cadeirante,
  capacidade_pessoas       = EXCLUDED.capacidade_pessoas,
  capacidade_porta_malas   = EXCLUDED.capacidade_porta_malas,
  categoria_dimensoes      = EXCLUDED.categoria_dimensoes,
  situacao_atual           = EXCLUDED.situacao_atual;


-- =====================================================================
-- 5. dim_cliente
-- Idempotencia: ON CONFLICT (sk_fonte_origem, id_natural_origem) DO UPDATE.
-- =====================================================================
INSERT INTO dw.dim_cliente (
    sk_fonte_origem, id_natural_origem, tipo_pessoa, nome, nome_fantasia,
    cidade_origem, uf_origem, email, telefone, cpf_normalizado,
    cnpj_normalizado, flag_eh_pessoa_juridica
)
SELECT
    sc.sk_fonte,
    sc.id_natural,
    CASE
        WHEN sc.tipo_pessoa IN ('PF','PJ') THEN sc.tipo_pessoa
        ELSE 'PF'
    END,
    COALESCE(NULLIF(sc.nome, ''), 'CLIENTE DESCONHECIDO'),
    sc.nome_fantasia,
    COALESCE(NULLIF(sc.cidade_origem, ''), 'DESCONHECIDA'),
    sc.uf_origem,
    sc.email,
    sc.telefone,
    sc.cpf,
    sc.cnpj,
    (sc.tipo_pessoa = 'PJ')
FROM staging.stg_cliente sc
ON CONFLICT (sk_fonte_origem, id_natural_origem) DO UPDATE SET
  tipo_pessoa             = EXCLUDED.tipo_pessoa,
  nome                    = EXCLUDED.nome,
  nome_fantasia           = EXCLUDED.nome_fantasia,
  cidade_origem           = EXCLUDED.cidade_origem,
  uf_origem               = EXCLUDED.uf_origem,
  email                   = EXCLUDED.email,
  telefone                = EXCLUDED.telefone,
  cpf_normalizado         = EXCLUDED.cpf_normalizado,
  cnpj_normalizado        = EXCLUDED.cnpj_normalizado,
  flag_eh_pessoa_juridica = EXCLUDED.flag_eh_pessoa_juridica;


RESET search_path;

-- =====================================================================
-- Fim do arquivo: etl/07_load_dimensoes.sql
-- =====================================================================
