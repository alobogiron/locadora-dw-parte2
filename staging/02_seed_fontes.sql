-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: staging/02_seed_fontes.sql
--  Objetivo: Popular as 5 fontes (src_*) com dados sinteticos consistentes
--            para suportar todo o pipeline ETL, os 4 relatorios e a matriz
--            de Markov.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Volume aproximado por fonte:
--    - 6 patios (1 proprio + 5 associados) — total 6 canonicos por fonte
--    - ~20 veiculos
--    - ~30 clientes (~25 PF + ~5 PJ)
--    - ~30 reservas
--    - ~60 locacoes (~40% patio_retirada != patio_devolucao para Markov)
--
--  Distribuicao de propriedade dos patios canonicos do enunciado:
--    - src_andre_gustavo  -> dono do Aeroporto do Galeao   (id local 1)
--    - src_mae016         -> dono do Aeroporto Santos Dumont
--    - src_locadora_db    -> dono da Rodoviaria do Rio
--    - src_bd_dw_26_1     -> dono do Shopping Rio Sul
--    - src_bigdata        -> dono do Shopping Nova America
--    - Barra Shopping     -> "associado" presente em todos os 5 schemas
--
--  Idempotente: TRUNCATE em cascata antes dos INSERTs (e os SERIAL/IDENTITY
--               sao reiniciados via RESTART IDENTITY).
-- =====================================================================

-- Limpeza idempotente. Ordem nao importa por causa do CASCADE.
TRUNCATE TABLE
    src_andre_gustavo.cobranca, src_andre_gustavo.locacao, src_andre_gustavo.reserva,
    src_andre_gustavo.condutor, src_andre_gustavo.cliente_pj, src_andre_gustavo.cliente_pf,
    src_andre_gustavo.cliente, src_andre_gustavo.veiculo, src_andre_gustavo.grupo,
    src_andre_gustavo.vaga, src_andre_gustavo.patio
    RESTART IDENTITY CASCADE;

TRUNCATE TABLE
    src_mae016.MOVIMENTACAO_PATIO, src_mae016.PAGAMENTO, src_mae016.LOCACAO,
    src_mae016.RESERVA, src_mae016.VEICULO, src_mae016.CONDUTOR,
    src_mae016.CLIENTE, src_mae016.GRUPO_VEICULO, src_mae016.PATIO, src_mae016.EMPRESA
    CASCADE;

TRUNCATE TABLE
    src_locadora_db.movimentacao_patio, src_locadora_db.manutencao, src_locadora_db.foto,
    src_locadora_db.locacao_seguro, src_locadora_db.seguro, src_locadora_db.cobranca,
    src_locadora_db.locacao, src_locadora_db.reserva, src_locadora_db.vaga,
    src_locadora_db.patio, src_locadora_db.veiculo_acessorio, src_locadora_db.acessorio,
    src_locadora_db.veiculo, src_locadora_db.grupo_veiculo, src_locadora_db.condutor,
    src_locadora_db.cliente, src_locadora_db.empresa_locadora
    RESTART IDENTITY CASCADE;

TRUNCATE TABLE
    src_bd_dw_26_1.Foto, src_bd_dw_26_1.Cobranca, src_bd_dw_26_1.Locacao_protecao,
    src_bd_dw_26_1.Locacao, src_bd_dw_26_1.Reserva_protecao, src_bd_dw_26_1.Reserva_acessorio,
    src_bd_dw_26_1.Reserva, src_bd_dw_26_1.Protecao_seguro, src_bd_dw_26_1.Dados_cobranca,
    src_bd_dw_26_1.Motorista, src_bd_dw_26_1.Cliente_pj, src_bd_dw_26_1.Cliente_pf,
    src_bd_dw_26_1.Cliente, src_bd_dw_26_1.Manutencao, src_bd_dw_26_1.Veiculo_acessorio,
    src_bd_dw_26_1.Acessorio, src_bd_dw_26_1.Veiculo, src_bd_dw_26_1.Categoria,
    src_bd_dw_26_1.Vaga, src_bd_dw_26_1.Patio, src_bd_dw_26_1.Empresa, src_bd_dw_26_1.Endereco
    RESTART IDENTITY CASCADE;

TRUNCATE TABLE
    src_bigdata.Avaria, src_bigdata.Prontuario, src_bigdata.Locacao, src_bigdata.Reserva,
    src_bigdata.Movimentacao, src_bigdata.CentroCusto, src_bigdata.Motorista,
    src_bigdata.Empresa, src_bigdata.PessoaFisica, src_bigdata.Veiculo, src_bigdata.Categoria,
    src_bigdata.Vaga, src_bigdata.Patio, src_bigdata.Parceira, src_bigdata.Endereco
    CASCADE;


-- =====================================================================
-- FONTE 1 — src_andre_gustavo (dona do Aeroporto do Galeao)
-- =====================================================================

SET search_path = src_andre_gustavo;

-- Patios: 6 canonicos do enunciado (id 1 = Galeao = proprio)
INSERT INTO patio (nome, endereco, capacidade_vagas) VALUES
  ('Aeroporto do Galeao',     'Av. 20 de Janeiro, s/n - Ilha do Governador, Rio de Janeiro RJ', 250),
  ('Aeroporto Santos Dumont', 'Praca Sen. Salgado Filho, s/n - Centro, Rio de Janeiro RJ',      150),
  ('Rodoviaria do Rio',       'Av. Francisco Bicalho, 1 - Santo Cristo, Rio de Janeiro RJ',     120),
  ('Shopping Rio Sul',        'Rua Lauro Muller, 116 - Botafogo, Rio de Janeiro RJ',            100),
  ('Shopping Nova America',   'Av. Pastor Martin Luther King Jr, 126 - Del Castilho, Rio RJ',   140),
  ('Barra Shopping',          'Av. das Americas, 4666 - Barra da Tijuca, Rio de Janeiro RJ',    180);

-- Vagas (algumas amostras por patio)
INSERT INTO vaga (patio_id, codigo, setor, ocupada) VALUES
  (1, 'A01', 'A', TRUE), (1, 'A02', 'A', FALSE), (1, 'B01', 'B', TRUE),
  (2, 'A01', 'A', FALSE), (2, 'B01', 'B', TRUE),
  (3, 'A01', 'A', FALSE), (4, 'A01', 'A', TRUE),
  (5, 'A01', 'A', FALSE), (6, 'A01', 'A', TRUE);

-- Grupos
INSERT INTO grupo (codigo, nome, classe_luxo, valor_diaria, franquia_km_diaria) VALUES
  ('ECO', 'Economico',     'ECONOMICO',    119.90, 200),
  ('INT', 'Intermediario', 'INTERMEDIARIO',179.90, 250),
  ('EXE', 'Executivo',     'INTERMEDIARIO',259.90, 300),
  ('SUV', 'SUV',           'INTERMEDIARIO',299.90, 300),
  ('LUX', 'Luxo',          'LUXO',         499.90, 400);

-- Veiculos (20)
INSERT INTO veiculo (grupo_id, patio_origem_id, placa, chassi, renavam, marca, modelo, cor, ano_fabricacao, mecanizacao, tem_ar_condicionado, km_atual, situacao) VALUES
  (1, 1, 'AGV0A01', '9BWZZZAG0000000A1', '10000000001', 'Chevrolet', 'Onix',     'Prata',    2022, 'MANUAL',     TRUE, 15000, 'DISPONIVEL'),
  (1, 1, 'AGV0A02', '9BWZZZAG0000000A2', '10000000002', 'Hyundai',   'HB20',     'Branco',   2023, 'AUTOMATICA', TRUE, 12000, 'DISPONIVEL'),
  (1, 1, 'AGV0A03', '9BWZZZAG0000000A3', '10000000003', 'Fiat',      'Mobi',     'Vermelho', 2021, 'MANUAL',     TRUE, 28000, 'ALUGADO'),
  (1, 6, 'AGV0A04', '9BWZZZAG0000000A4', '10000000004', 'Renault',   'Kwid',     'Laranja',  2022, 'MANUAL',     TRUE, 18000, 'DISPONIVEL'),
  (2, 1, 'AGV0B01', '9BWZZZAG0000000B1', '10000000005', 'Volkswagen','Polo',     'Cinza',    2023, 'AUTOMATICA', TRUE, 9000,  'DISPONIVEL'),
  (2, 2, 'AGV0B02', '9BWZZZAG0000000B2', '10000000006', 'Fiat',      'Argo',     'Branco',   2022, 'MANUAL',     TRUE, 22000, 'ALUGADO'),
  (2, 1, 'AGV0B03', '9BWZZZAG0000000B3', '10000000007', 'Hyundai',   'HB20S',    'Preto',    2023, 'AUTOMATICA', TRUE, 11000, 'DISPONIVEL'),
  (2, 4, 'AGV0B04', '9BWZZZAG0000000B4', '10000000008', 'Chevrolet', 'Onix Plus','Azul',     2024, 'AUTOMATICA', TRUE, 5000,  'DISPONIVEL'),
  (3, 1, 'AGV0C01', '9BWZZZAG0000000C1', '10000000009', 'Toyota',    'Corolla',  'Preto',    2023, 'AUTOMATICA', TRUE, 14000, 'DISPONIVEL'),
  (3, 3, 'AGV0C02', '9BWZZZAG0000000C2', '10000000010', 'Honda',     'Civic',    'Prata',    2022, 'AUTOMATICA', TRUE, 19000, 'ALUGADO'),
  (3, 1, 'AGV0C03', '9BWZZZAG0000000C3', '10000000011', 'Nissan',    'Sentra',   'Branco',   2023, 'AUTOMATICA', TRUE, 8000,  'DISPONIVEL'),
  (4, 1, 'AGV0D01', '9BWZZZAG0000000D1', '10000000012', 'Jeep',      'Compass',  'Cinza',    2023, 'AUTOMATICA', TRUE, 16000, 'DISPONIVEL'),
  (4, 5, 'AGV0D02', '9BWZZZAG0000000D2', '10000000013', 'Volkswagen','T-Cross',  'Vermelho', 2022, 'AUTOMATICA', TRUE, 25000, 'ALUGADO'),
  (4, 1, 'AGV0D03', '9BWZZZAG0000000D3', '10000000014', 'Hyundai',   'Creta',    'Branco',   2024, 'AUTOMATICA', TRUE, 4000,  'DISPONIVEL'),
  (4, 6, 'AGV0D04', '9BWZZZAG0000000D4', '10000000015', 'Chevrolet', 'Tracker',  'Preto',    2023, 'AUTOMATICA', TRUE, 12000, 'DISPONIVEL'),
  (5, 1, 'AGV0E01', '9BWZZZAG0000000E1', '10000000016', 'Audi',      'A4',       'Preto',    2023, 'AUTOMATICA', TRUE, 7000,  'DISPONIVEL'),
  (5, 1, 'AGV0E02', '9BWZZZAG0000000E2', '10000000017', 'BMW',       '320i',     'Branco',   2024, 'AUTOMATICA', TRUE, 3500,  'DISPONIVEL'),
  (5, 1, 'AGV0E03', '9BWZZZAG0000000E3', '10000000018', 'Mercedes',  'C200',     'Cinza',    2023, 'AUTOMATICA', TRUE, 10000, 'ALUGADO'),
  (1, 6, 'AGV0A05', '9BWZZZAG0000000A5', '10000000019', 'Volkswagen','Gol',      'Branco',   2021, 'MANUAL',     TRUE, 30000, 'MANUTENCAO'),
  (2, 1, 'AGV0B05', '9BWZZZAG0000000B5', '10000000020', 'Fiat',      'Cronos',   'Prata',    2022, 'AUTOMATICA', TRUE, 21000, 'DISPONIVEL');

-- Clientes (25 PF + 5 PJ = 30)
INSERT INTO cliente (tipo_pessoa, nome, email, telefone, cidade_origem) VALUES
  ('PF', 'Ana Beatriz Souza',      'ana.souza@email.com',      '(21) 98800-0001', 'Rio de Janeiro'),
  ('PF', 'Bruno Henrique Lima',    'bruno.lima@email.com',     '(21) 98800-0002', 'Niteroi'),
  ('PF', 'Carla Mendes Castro',    'carla.castro@email.com',   '(11) 98800-0003', 'Sao Paulo'),
  ('PF', 'Diego Martins Oliveira', 'diego.oliveira@email.com', '(31) 98800-0004', 'Belo Horizonte'),
  ('PF', 'Elaine Costa Ribeiro',   'elaine.ribeiro@email.com', '(21) 98800-0005', 'Sao Goncalo'),
  ('PF', 'Felipe Augusto Pinto',   'felipe.pinto@email.com',   '(21) 98800-0006', 'Duque de Caxias'),
  ('PF', 'Gabriela Faria Nunes',   'gabriela.nunes@email.com', '(11) 98800-0007', 'Sao Paulo'),
  ('PF', 'Henrique Silva Carvalho','henrique.silva@email.com', '(27) 98800-0008', 'Vitoria'),
  ('PF', 'Isabela Rocha Gomes',    'isabela.gomes@email.com',  '(41) 98800-0009', 'Curitiba'),
  ('PF', 'Joao Pedro Alves',       'joao.alves@email.com',     '(21) 98800-0010', 'Rio de Janeiro'),
  ('PF', 'Karina Lopes Borges',    'karina.borges@email.com',  '(21) 98800-0011', 'Niteroi'),
  ('PF', 'Lucas Fernandes Diniz',  'lucas.diniz@email.com',    '(31) 98800-0012', 'Belo Horizonte'),
  ('PF', 'Mariana Sousa Teixeira', 'mariana.teixeira@email.com','(11) 98800-0013','Sao Paulo'),
  ('PF', 'Natalia Pires Barbosa',  'natalia.barbosa@email.com','(21) 98800-0014', 'Rio de Janeiro'),
  ('PF', 'Otavio Cesar Pinto',     'otavio.pinto@email.com',   '(21) 98800-0015', 'Sao Goncalo'),
  ('PF', 'Patricia Lima Moreira',  'patricia.moreira@email.com','(21) 98800-0016','Duque de Caxias'),
  ('PF', 'Quesia Almeida Reis',    'quesia.reis@email.com',    '(27) 98800-0017', 'Vitoria'),
  ('PF', 'Rafael Carvalho Costa',  'rafael.costa@email.com',   '(41) 98800-0018', 'Curitiba'),
  ('PF', 'Sabrina Tavares Pinto',  'sabrina.pinto@email.com',  '(21) 98800-0019', 'Rio de Janeiro'),
  ('PF', 'Thiago Mendes Pereira',  'thiago.pereira@email.com', '(21) 98800-0020', 'Niteroi'),
  ('PF', 'Ursula Vieira Lopes',    'ursula.lopes@email.com',   '(11) 98800-0021', 'Sao Paulo'),
  ('PF', 'Vinicius Araujo Cunha',  'vinicius.cunha@email.com', '(31) 98800-0022', 'Belo Horizonte'),
  ('PF', 'Wagner Rocha Tavares',   'wagner.tavares@email.com', '(21) 98800-0023', 'Rio de Janeiro'),
  ('PF', 'Xenia Barbosa Cordeiro', 'xenia.cordeiro@email.com', '(21) 98800-0024', 'Sao Goncalo'),
  ('PF', 'Yago Marcelo Soares',    'yago.soares@email.com',    '(21) 98800-0025', 'Duque de Caxias'),
  ('PJ', 'Petropolis Turismo Ltda','contato@petropolis.tur',   '(24) 98800-0026', 'Rio de Janeiro'),
  ('PJ', 'BH Negocios SA',         'contato@bhnegocios.com',   '(31) 98800-0027', 'Belo Horizonte'),
  ('PJ', 'SP Eventos ME',          'contato@speventos.com',    '(11) 98800-0028', 'Sao Paulo'),
  ('PJ', 'Niteroi Comercio Ltda',  'contato@niteroicom.com',   '(21) 98800-0029', 'Niteroi'),
  ('PJ', 'Vitoria Logistica SA',   'contato@vitorialog.com',   '(27) 98800-0030', 'Vitoria');

-- cliente_pf (25 PF)
INSERT INTO cliente_pf (cliente_id, cpf, rg, data_nascimento, cnh_numero, cnh_categoria, cnh_validade)
SELECT c.id_cliente,
       LPAD(c.id_cliente::TEXT, 11, '0'),
       'RG' || LPAD(c.id_cliente::TEXT, 8, '0'),
       (DATE '1980-01-01' + (c.id_cliente * 137)),
       'CNH' || LPAD(c.id_cliente::TEXT, 9, '0'),
       'B',
       DATE '2030-12-31'
FROM cliente c WHERE c.tipo_pessoa = 'PF';

-- cliente_pj (5 PJ)
INSERT INTO cliente_pj (cliente_id, cnpj, nome_fantasia, responsavel)
SELECT c.id_cliente,
       LPAD(c.id_cliente::TEXT, 14, '0'),
       c.nome,
       'Responsavel ' || c.nome
FROM cliente c WHERE c.tipo_pessoa = 'PJ';

-- condutor (1 por PJ)
INSERT INTO condutor (cliente_pj_id, cpf, nome, cnh_numero, cnh_categoria, cnh_validade)
SELECT cpj.cliente_id,
       LPAD((cpj.cliente_id + 100)::TEXT, 11, '0'),
       'Condutor ' || c.nome,
       'CNHC' || LPAD(cpj.cliente_id::TEXT, 8, '0'),
       'B',
       DATE '2030-12-31'
FROM cliente_pj cpj JOIN cliente c ON c.id_cliente = cpj.cliente_id;

-- Reservas (30)
INSERT INTO reserva (cliente_id, grupo_id, patio_retirada_id, patio_devolucao_id, data_reserva, data_retirada_prevista, data_devolucao_prevista, estado)
SELECT
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 5) + 1,
    ((gs - 1) % 6) + 1,
    ((gs * 3 - 1) % 6) + 1,
    DATE '2024-01-15' + (gs * 13)::INTEGER,
    DATE '2024-01-25' + (gs * 13)::INTEGER + 2,
    DATE '2024-01-25' + (gs * 13)::INTEGER + (5 + (gs % 7)),
    CASE WHEN gs % 10 = 0 THEN 'CANCELADA'
         WHEN gs % 7 = 0 THEN 'EM_FILA_ESPERA'
         WHEN gs % 3 = 0 THEN 'CONCRETIZADA'
         ELSE 'CONFIRMADA' END
FROM generate_series(1, 30) gs;

-- Locacoes (60). Regra do schema andre_gustavo: indice unico parcial
-- impede 2 locacoes EM_ANDAMENTO no mesmo veiculo. Estrategia:
--   - Apenas as ultimas 5 locacoes (gs in 56..60) ficam EM_ANDAMENTO,
--     e cada uma usa um veiculo distinto que nao foi usado pelo bloco
--     EM_ANDAMENTO em outra linha. ((gs - 1) % 20) + 1 com gs=56..60 =>
--     veiculos {16,17,18,19,20} — sem colisao.
--   - CANCELADA quando gs % 5 = 4 (12 linhas espalhadas).
--   - CONCLUIDA caso contrario (~43 linhas).
INSERT INTO locacao (numero_contrato, reserva_id, cliente_id, veiculo_id, patio_retirada_id, patio_devolucao_id,
                     data_retirada_real, data_devolucao_real, km_saida, km_chegada, valor_diaria_aplicada, status)
SELECT
    'AG-' || LPAD(gs::TEXT, 6, '0'),
    NULL,  -- walk-in / sem amarrar a reserva especifica
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 20) + 1,
    ((gs - 1) % 6) + 1,
    CASE WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1 ELSE ((gs - 1) % 6) + 1 END,
    (TIMESTAMP '2024-02-01 10:00:00' + (gs * INTERVAL '5 days')),
    CASE
      WHEN gs > 55                THEN NULL  -- EM_ANDAMENTO
      WHEN gs % 5  = 4            THEN NULL  -- CANCELADA
      ELSE (TIMESTAMP '2024-02-01 10:00:00' + (gs * INTERVAL '5 days') + ((3 + gs % 5) * INTERVAL '1 day'))
    END,
    1000 + gs * 10,
    CASE
      WHEN gs > 55                THEN NULL
      WHEN gs % 5  = 4            THEN NULL
      ELSE 1000 + gs * 10 + (50 + gs % 200)
    END,
    100.00 + (gs % 5) * 50,
    CASE WHEN gs > 55     THEN 'EM_ANDAMENTO'
         WHEN gs % 5  = 4 THEN 'CANCELADA'
         ELSE 'CONCLUIDA' END
FROM generate_series(1, 60) gs;

-- Cobrancas para concluidas (~70%)
INSERT INTO cobranca (locacao_id, data_emissao, valor_total, status)
SELECT l.id_locacao,
       DATE(l.data_devolucao_real),
       l.valor_diaria_aplicada * 5,
       'PAGA'
FROM locacao l WHERE l.status = 'CONCLUIDA';


-- =====================================================================
-- FONTE 2 — src_mae016 (dona do Aeroporto Santos Dumont)
-- IDs explicitos (sem AUTO_INCREMENT na DDL original; PKs INT NOT NULL).
-- =====================================================================

SET search_path = src_mae016;

-- Empresas (uma propria + as 5 associadas - referencias)
INSERT INTO EMPRESA (id_empresa, nome_empresa) VALUES
  (1, 'MAE016 Locacoes SA'),
  (2, 'Andre Gustavo Locacoes Ltda'),
  (3, 'Locadora DB SA'),
  (4, 'BD-DW Locacoes Ltda'),
  (5, 'BigData Locacoes SA'),
  (6, 'Barra Frota Associada');

-- Patios: 6 (id 1 = Santos Dumont = proprio)
INSERT INTO PATIO (id_patio, id_empresa, nome_patio, localizacao, codigo_patio) VALUES
  (1, 1, 'Aeroporto Santos Dumont',  'Praca Sen. Salgado Filho, Centro, Rio de Janeiro RJ',          'M-SDU'),
  (2, 2, 'Aeroporto do Galeao',      'Av. 20 de Janeiro, Ilha do Governador, Rio de Janeiro RJ',     'M-GIG'),
  (3, 3, 'Rodoviaria do Rio',        'Av. Francisco Bicalho, Santo Cristo, Rio de Janeiro RJ',       'M-ROD'),
  (4, 4, 'Shopping Rio Sul',         'Rua Lauro Muller, Botafogo, Rio de Janeiro RJ',                'M-RSL'),
  (5, 5, 'Shopping Nova America',    'Av. Pastor Martin Luther King Jr, Del Castilho, Rio RJ',       'M-NAM'),
  (6, 6, 'Barra Shopping',           'Av. das Americas, 4666, Barra da Tijuca, Rio de Janeiro RJ',   'M-BRR');

-- Grupos
INSERT INTO GRUPO_VEICULO (id_grupo, nome_grupo, descricao, faixa_valor_diaria) VALUES
  (1, 'Economico',     'Hatch compacto',         109.90),
  (2, 'Intermediario', 'Sedan compacto',         169.90),
  (3, 'Executivo',     'Sedan executivo',        249.90),
  (4, 'SUV',           'Utilitario esportivo',   289.90),
  (5, 'Luxo',          'Premium',                479.90);

-- Clientes (~30)
INSERT INTO CLIENTE (id_cliente, tipo_cliente, nome_razao_social, cpf_cnpj, cidade, estado, telefone, email) VALUES
  (1,  'PF', 'Alan Pereira Lima',       '20000000001', 'Rio de Janeiro', 'RJ', '(21) 97700-0001', 'alan.lima@m016.com'),
  (2,  'PF', 'Beatriz Mendes Souza',    '20000000002', 'Niteroi',        'RJ', '(21) 97700-0002', 'beatriz.souza@m016.com'),
  (3,  'PF', 'Carlos Eduardo Faria',    '20000000003', 'Sao Paulo',      'SP', '(11) 97700-0003', 'carlos.faria@m016.com'),
  (4,  'PF', 'Daniele Castro Pinto',    '20000000004', 'Belo Horizonte', 'MG', '(31) 97700-0004', 'daniele.castro@m016.com'),
  (5,  'PF', 'Eduardo Lima Rocha',      '20000000005', 'Sao Goncalo',    'RJ', '(21) 97700-0005', 'eduardo.rocha@m016.com'),
  (6,  'PF', 'Fernanda Alves Souza',    '20000000006', 'Duque de Caxias','RJ', '(21) 97700-0006', 'fernanda.souza@m016.com'),
  (7,  'PF', 'Gustavo Silva Castro',    '20000000007', 'Vitoria',        'ES', '(27) 97700-0007', 'gustavo.castro@m016.com'),
  (8,  'PF', 'Helena Costa Pinto',      '20000000008', 'Curitiba',       'PR', '(41) 97700-0008', 'helena.pinto@m016.com'),
  (9,  'PF', 'Igor Borges Lima',        '20000000009', 'Rio de Janeiro', 'RJ', '(21) 97700-0009', 'igor.lima@m016.com'),
  (10, 'PF', 'Julia Faria Diniz',       '20000000010', 'Niteroi',        'RJ', '(21) 97700-0010', 'julia.diniz@m016.com'),
  (11, 'PF', 'Kaue Almeida Reis',       '20000000011', 'Sao Paulo',      'SP', '(11) 97700-0011', 'kaue.reis@m016.com'),
  (12, 'PF', 'Leticia Costa Alves',     '20000000012', 'Belo Horizonte', 'MG', '(31) 97700-0012', 'leticia.alves@m016.com'),
  (13, 'PF', 'Marcio Pereira Borges',   '20000000013', 'Rio de Janeiro', 'RJ', '(21) 97700-0013', 'marcio.borges@m016.com'),
  (14, 'PF', 'Nicole Tavares Pinto',    '20000000014', 'Sao Goncalo',    'RJ', '(21) 97700-0014', 'nicole.pinto@m016.com'),
  (15, 'PF', 'Otaviano Vieira Reis',    '20000000015', 'Duque de Caxias','RJ', '(21) 97700-0015', 'otaviano.reis@m016.com'),
  (16, 'PF', 'Patricia Rocha Mendes',   '20000000016', 'Vitoria',        'ES', '(27) 97700-0016', 'patricia.mendes@m016.com'),
  (17, 'PF', 'Quirino Souza Lima',      '20000000017', 'Curitiba',       'PR', '(41) 97700-0017', 'quirino.lima@m016.com'),
  (18, 'PF', 'Renata Tavares Castro',   '20000000018', 'Rio de Janeiro', 'RJ', '(21) 97700-0018', 'renata.castro@m016.com'),
  (19, 'PF', 'Samuel Lopes Pinto',      '20000000019', 'Niteroi',        'RJ', '(21) 97700-0019', 'samuel.pinto@m016.com'),
  (20, 'PF', 'Thais Cordeiro Almeida',  '20000000020', 'Sao Paulo',      'SP', '(11) 97700-0020', 'thais.almeida@m016.com'),
  (21, 'PF', 'Ulisses Borges Cunha',    '20000000021', 'Belo Horizonte', 'MG', '(31) 97700-0021', 'ulisses.cunha@m016.com'),
  (22, 'PF', 'Vania Castro Pinto',      '20000000022', 'Rio de Janeiro', 'RJ', '(21) 97700-0022', 'vania.pinto@m016.com'),
  (23, 'PF', 'Wallace Silva Reis',      '20000000023', 'Sao Goncalo',    'RJ', '(21) 97700-0023', 'wallace.reis@m016.com'),
  (24, 'PF', 'Ximena Almeida Rocha',    '20000000024', 'Duque de Caxias','RJ', '(21) 97700-0024', 'ximena.rocha@m016.com'),
  (25, 'PF', 'Yuri Mendes Tavares',     '20000000025', 'Vitoria',        'ES', '(27) 97700-0025', 'yuri.tavares@m016.com'),
  (26, 'PJ', 'Rio Tour Servicos Ltda',  '20000000000026', 'Rio de Janeiro','RJ','(21) 97700-0026', 'contato@riotour.com'),
  (27, 'PJ', 'BH Frota Empresarial SA', '20000000000027', 'Belo Horizonte','MG','(31) 97700-0027', 'contato@bhfrota.com'),
  (28, 'PJ', 'SP Move Locacoes ME',     '20000000000028', 'Sao Paulo',     'SP','(11) 97700-0028', 'contato@spmove.com'),
  (29, 'PJ', 'Niteroi Travel Ltda',     '20000000000029', 'Niteroi',       'RJ','(21) 97700-0029', 'contato@niteroitravel.com'),
  (30, 'PJ', 'ES Cargas SA',            '20000000000030', 'Vitoria',       'ES','(27) 97700-0030', 'contato@escargas.com');

-- Condutores (1 por PF + 1 por PJ = 30)
INSERT INTO CONDUTOR (id_condutor, nome_condutor, cpf, numero_cnh, categoria_cnh, validade_cnh, id_cliente)
SELECT c.id_cliente,
       'Condutor ' || c.nome_razao_social,
       'CPFC' || LPAD(c.id_cliente::TEXT, 16, '0'),
       'CNHM' || LPAD(c.id_cliente::TEXT, 16, '0'),
       'B',
       DATE '2031-12-31',
       c.id_cliente
FROM CLIENTE c;

-- Veiculos (20)
INSERT INTO VEICULO (id_veiculo, placa, chassi, marca, modelo, cor, mecanizacao, ar_condicionado, status, id_grupo, id_empresa, id_patio_atual) VALUES
  (1,  'M16A001', '9BMZZM160000000A1', 'Chevrolet','Onix',     'Branco',  'MANUAL',     TRUE, 'DISPONIVEL', 1, 1, 1),
  (2,  'M16A002', '9BMZZM160000000A2', 'Hyundai',  'HB20',     'Prata',   'AUTOMATICO', TRUE, 'DISPONIVEL', 1, 1, 1),
  (3,  'M16A003', '9BMZZM160000000A3', 'Fiat',     'Mobi',     'Vermelho','MANUAL',     TRUE, 'ALUGADO',    1, 1, 6),
  (4,  'M16A004', '9BMZZM160000000A4', 'Renault',  'Kwid',     'Cinza',   'MANUAL',     TRUE, 'DISPONIVEL', 1, 1, 2),
  (5,  'M16B001', '9BMZZM160000000B1', 'Volkswagen','Polo',    'Preto',   'AUTOMATICO', TRUE, 'DISPONIVEL', 2, 1, 1),
  (6,  'M16B002', '9BMZZM160000000B2', 'Fiat',     'Cronos',   'Branco',  'AUTOMATICO', TRUE, 'ALUGADO',    2, 1, 3),
  (7,  'M16B003', '9BMZZM160000000B3', 'Hyundai',  'HB20S',    'Prata',   'AUTOMATICO', TRUE, 'DISPONIVEL', 2, 1, 1),
  (8,  'M16B004', '9BMZZM160000000B4', 'Chevrolet','Onix Plus','Azul',    'AUTOMATICO', TRUE, 'DISPONIVEL', 2, 1, 4),
  (9,  'M16C001', '9BMZZM160000000C1', 'Toyota',   'Corolla',  'Preto',   'AUTOMATICO', TRUE, 'DISPONIVEL', 3, 1, 1),
  (10, 'M16C002', '9BMZZM160000000C2', 'Honda',    'Civic',    'Branco',  'AUTOMATICO', TRUE, 'ALUGADO',    3, 1, 5),
  (11, 'M16C003', '9BMZZM160000000C3', 'Nissan',   'Sentra',   'Prata',   'AUTOMATICO', TRUE, 'DISPONIVEL', 3, 1, 1),
  (12, 'M16D001', '9BMZZM160000000D1', 'Jeep',     'Compass',  'Cinza',   'AUTOMATICO', TRUE, 'DISPONIVEL', 4, 1, 1),
  (13, 'M16D002', '9BMZZM160000000D2', 'Volkswagen','T-Cross', 'Vermelho','AUTOMATICO', TRUE, 'ALUGADO',    4, 1, 6),
  (14, 'M16D003', '9BMZZM160000000D3', 'Hyundai',  'Creta',    'Branco',  'AUTOMATICO', TRUE, 'DISPONIVEL', 4, 1, 2),
  (15, 'M16D004', '9BMZZM160000000D4', 'Chevrolet','Tracker',  'Preto',   'AUTOMATICO', TRUE, 'DISPONIVEL', 4, 1, 1),
  (16, 'M16E001', '9BMZZM160000000E1', 'Audi',     'A4',       'Preto',   'AUTOMATICO', TRUE, 'DISPONIVEL', 5, 1, 1),
  (17, 'M16E002', '9BMZZM160000000E2', 'BMW',      '320i',     'Branco',  'AUTOMATICO', TRUE, 'DISPONIVEL', 5, 1, 1),
  (18, 'M16E003', '9BMZZM160000000E3', 'Mercedes', 'C200',     'Cinza',   'AUTOMATICO', TRUE, 'ALUGADO',    5, 1, 4),
  (19, 'M16A005', '9BMZZM160000000A5', 'Volkswagen','Gol',     'Branco',  'MANUAL',     TRUE, 'MANUTENCAO', 1, 1, 1),
  (20, 'M16B005', '9BMZZM160000000B5', 'Fiat',     'Argo',     'Azul',    'AUTOMATICO', TRUE, 'DISPONIVEL', 2, 1, 1);

-- Reservas (30)
INSERT INTO RESERVA (id_reserva, data_reserva, data_prev_retirada, data_prev_devolucao, status_reserva, id_cliente, id_grupo, id_patio_retirada, id_patio_devolucao_previsto)
SELECT
    gs,
    DATE '2024-02-01' + (gs * 11)::INTEGER,
    DATE '2024-02-01' + (gs * 11)::INTEGER + 3,
    DATE '2024-02-01' + (gs * 11)::INTEGER + 3 + (4 + gs % 6),
    CASE WHEN gs % 10 = 0 THEN 'CANCELADA'
         WHEN gs % 4 = 0 THEN 'CONVERTIDA'
         ELSE 'ATIVA' END,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 5) + 1,
    ((gs - 1) % 6) + 1,
    ((gs * 2 - 1) % 6) + 1
FROM generate_series(1, 30) gs;

-- Locacoes (60)
INSERT INTO LOCACAO (id_locacao, data_hora_retirada, data_hora_prev_devolucao, data_hora_real_devolucao,
                     valor_previsto, valor_final, status_locacao,
                     id_reserva, id_cliente, id_condutor, id_veiculo,
                     id_patio_retirada, id_patio_devolucao_previsto, id_patio_devolucao_real)
SELECT
    gs,
    TIMESTAMP '2024-03-01 09:00:00' + (gs * INTERVAL '4 days'),
    TIMESTAMP '2024-03-01 09:00:00' + (gs * INTERVAL '4 days') + ((3 + gs % 7) * INTERVAL '1 day'),
    CASE
      WHEN gs % 10 = 9 THEN NULL
      WHEN gs % 5  = 4 THEN NULL
      ELSE TIMESTAMP '2024-03-01 09:00:00' + (gs * INTERVAL '4 days') + ((3 + gs % 7) * INTERVAL '1 day')
    END,
    500.00 + (gs % 7) * 100,
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 500.00 + (gs % 7) * 100 + 50 END,
    CASE WHEN gs % 10 = 9 THEN 'ATIVA'
         WHEN gs % 5  = 4 THEN 'CANCELADA'
         ELSE 'FINALIZADA' END,
    NULL,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 20) + 1,
    ((gs - 1) % 6) + 1,
    ((gs - 1) % 6) + 1,
    CASE WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1 ELSE ((gs - 1) % 6) + 1 END
FROM generate_series(1, 60) gs;

-- Pagamentos para finalizadas
INSERT INTO PAGAMENTO (id_pagamento, data_pagamento, valor_pagamento, forma_pagamento, tipo_pagamento, id_locacao)
SELECT l.id_locacao,
       DATE(l.data_hora_real_devolucao),
       l.valor_final,
       CASE WHEN l.id_locacao % 4 = 0 THEN 'PIX'
            WHEN l.id_locacao % 3 = 0 THEN 'BOLETO'
            WHEN l.id_locacao % 2 = 0 THEN 'CARTAO'
            ELSE 'DINHEIRO' END,
       'FINAL',
       l.id_locacao
FROM LOCACAO l WHERE l.status_locacao = 'FINALIZADA';

-- Movimentacoes (poucas, apenas para auditoria)
INSERT INTO MOVIMENTACAO_PATIO (id_movimentacao, data_hora_movimentacao, motivo_movimentacao, id_veiculo, id_patio_origem, id_patio_destino) VALUES
  (1, TIMESTAMP '2024-04-10 14:00:00', 'Reposicionamento', 3, 1, 2),
  (2, TIMESTAMP '2024-04-12 09:30:00', 'Reposicionamento', 6, 3, 1),
  (3, TIMESTAMP '2024-05-01 10:00:00', 'Manutencao',       19, 6, 1);


-- =====================================================================
-- FONTE 3 — src_locadora_db (dona da Rodoviaria do Rio)
-- =====================================================================

SET search_path = src_locadora_db;

INSERT INTO empresa_locadora (nome, cnpj) VALUES
  ('Locadora DB SA',            '30.000.000/0001-30'),
  ('Andre Gustavo Frota',       '30.000.000/0001-31'),
  ('MAE016 Frota',              '30.000.000/0001-32'),
  ('BD-DW Frota',               '30.000.000/0001-33'),
  ('BigData Frota',             '30.000.000/0001-34'),
  ('Barra Frota Associada',     '30.000.000/0001-35');

INSERT INTO patio (nome, cidade) VALUES
  ('Rodoviaria do Rio',         'Rio de Janeiro'),  -- id 1 (proprio)
  ('Aeroporto do Galeao',       'Rio de Janeiro'),
  ('Aeroporto Santos Dumont',   'Rio de Janeiro'),
  ('Shopping Rio Sul',          'Rio de Janeiro'),
  ('Shopping Nova America',     'Rio de Janeiro'),
  ('Barra Shopping',            'Rio de Janeiro');

INSERT INTO grupo_veiculo (nome, categoria) VALUES
  ('Economico',     'Hatch compacto'),
  ('Intermediario', 'Sedan compacto'),
  ('Executivo',     'Sedan executivo'),
  ('SUV',           'Utilitario esportivo'),
  ('Luxo',          'Premium');

-- Clientes
INSERT INTO cliente (nome, tipo, cidade) VALUES
  ('Adriana Souza Lima',      'PF', 'Rio de Janeiro'),
  ('Beto Costa Pinto',        'PF', 'Niteroi'),
  ('Camila Ribeiro Mendes',   'PF', 'Sao Paulo'),
  ('Daniel Castro Rocha',     'PF', 'Belo Horizonte'),
  ('Erica Lima Borges',       'PF', 'Sao Goncalo'),
  ('Fabio Almeida Costa',     'PF', 'Duque de Caxias'),
  ('Glenda Faria Reis',       'PF', 'Vitoria'),
  ('Helio Tavares Pinto',     'PF', 'Curitiba'),
  ('Ines Carvalho Diniz',     'PF', 'Rio de Janeiro'),
  ('Jorge Mendes Lima',       'PF', 'Niteroi'),
  ('Katia Pinto Souza',       'PF', 'Sao Paulo'),
  ('Lucio Cordeiro Reis',     'PF', 'Belo Horizonte'),
  ('Marta Lopes Pinto',       'PF', 'Sao Goncalo'),
  ('Nilo Vieira Cunha',       'PF', 'Duque de Caxias'),
  ('Olga Faria Castro',       'PF', 'Vitoria'),
  ('Paulo Rocha Almeida',     'PF', 'Curitiba'),
  ('Queila Borges Tavares',   'PF', 'Rio de Janeiro'),
  ('Rui Lima Costa',          'PF', 'Niteroi'),
  ('Sergio Castro Mendes',    'PF', 'Sao Paulo'),
  ('Tania Almeida Pinto',     'PF', 'Belo Horizonte'),
  ('Ubaldo Tavares Souza',    'PF', 'Sao Goncalo'),
  ('Vania Cunha Faria',       'PF', 'Duque de Caxias'),
  ('Wesley Borges Pinto',     'PF', 'Vitoria'),
  ('Xisto Mendes Reis',       'PF', 'Curitiba'),
  ('Yedda Castro Lima',       'PF', 'Rio de Janeiro'),
  ('TechRio Consultoria Ltda','PJ', 'Rio de Janeiro'),
  ('Niteroi Solucoes ME',     'PJ', 'Niteroi'),
  ('SP Mobilidade Ltda',      'PJ', 'Sao Paulo'),
  ('BH Logistica SA',         'PJ', 'Belo Horizonte'),
  ('Curitiba Frotas SA',      'PJ', 'Curitiba');

-- Condutores (1 por cliente)
INSERT INTO condutor (cliente_id, nome, cnh, validade, categoria, telefone)
SELECT c.id,
       'Condutor ' || c.nome,
       'LDB' || LPAD(c.id::TEXT, 17, '0'),
       DATE '2031-12-31',
       'B',
       '(21) 96600-' || LPAD(c.id::TEXT, 4, '0')
FROM cliente c;

-- Veiculos (~20) — incluindo id_patio_origem (extensao de integracao, P-09 do modelo).
-- Atribuicao: a maioria fica no patio proprio (Rodoviaria=1); alguns sao
-- "estacionados" em patios das outras empresas associadas para gerar
-- cruzamentos no fato_patio_diario.
INSERT INTO veiculo (placa, chassi, modelo, marca, cor, tipo_mecanizacao, ar_condicionado, status, adaptado_cadeirante, grupo_id, empresa_id, id_patio_origem) VALUES
  ('LDB0A01', '9BLDBA01000000001', 'Onix',      'Chevrolet','Prata',    'manual',     TRUE, 'disponivel', FALSE, 1, 1, 1),
  ('LDB0A02', '9BLDBA02000000002', 'HB20',      'Hyundai',  'Branco',   'automatico', TRUE, 'disponivel', FALSE, 1, 1, 1),
  ('LDB0A03', '9BLDBA03000000003', 'Mobi',      'Fiat',     'Vermelho', 'manual',     TRUE, 'alugado',    TRUE,  1, 1, 2),
  ('LDB0A04', '9BLDBA04000000004', 'Kwid',      'Renault',  'Laranja',  'manual',     TRUE, 'disponivel', FALSE, 1, 1, 1),
  ('LDB0B01', '9BLDBB01000000005', 'Polo',      'Volkswagen','Cinza',   'automatico', TRUE, 'disponivel', FALSE, 2, 1, 1),
  ('LDB0B02', '9BLDBB02000000006', 'Argo',      'Fiat',     'Branco',   'manual',     TRUE, 'alugado',    FALSE, 2, 1, 3),
  ('LDB0B03', '9BLDBB03000000007', 'HB20S',     'Hyundai',  'Preto',    'automatico', TRUE, 'disponivel', FALSE, 2, 1, 1),
  ('LDB0B04', '9BLDBB04000000008', 'Onix Plus', 'Chevrolet','Azul',     'automatico', TRUE, 'disponivel', FALSE, 2, 1, 4),
  ('LDB0C01', '9BLDBC01000000009', 'Corolla',   'Toyota',   'Preto',    'automatico', TRUE, 'disponivel', FALSE, 3, 1, 1),
  ('LDB0C02', '9BLDBC02000000010', 'Civic',     'Honda',    'Prata',    'automatico', TRUE, 'alugado',    FALSE, 3, 1, 5),
  ('LDB0C03', '9BLDBC03000000011', 'Sentra',    'Nissan',   'Branco',   'automatico', TRUE, 'disponivel', FALSE, 3, 1, 1),
  ('LDB0D01', '9BLDBD01000000012', 'Compass',   'Jeep',     'Cinza',    'automatico', TRUE, 'disponivel', FALSE, 4, 1, 1),
  ('LDB0D02', '9BLDBD02000000013', 'T-Cross',   'Volkswagen','Vermelho','automatico', TRUE, 'alugado',    FALSE, 4, 1, 6),
  ('LDB0D03', '9BLDBD03000000014', 'Creta',     'Hyundai',  'Branco',   'automatico', TRUE, 'disponivel', FALSE, 4, 1, 1),
  ('LDB0D04', '9BLDBD04000000015', 'Tracker',   'Chevrolet','Preto',    'automatico', TRUE, 'disponivel', FALSE, 4, 1, 2),
  ('LDB0E01', '9BLDBE01000000016', 'A4',        'Audi',     'Preto',    'automatico', TRUE, 'disponivel', FALSE, 5, 1, 1),
  ('LDB0E02', '9BLDBE02000000017', '320i',      'BMW',      'Branco',   'automatico', TRUE, 'disponivel', FALSE, 5, 1, 1),
  ('LDB0E03', '9BLDBE03000000018', 'C200',      'Mercedes', 'Cinza',    'automatico', TRUE, 'alugado',    FALSE, 5, 1, 3),
  ('LDB0A05', '9BLDBA05000000019', 'Gol',       'Volkswagen','Branco',  'manual',     TRUE, 'manutencao', FALSE, 1, 1, 1),
  ('LDB0B05', '9BLDBB05000000020', 'Cronos',    'Fiat',     'Prata',    'automatico', TRUE, 'disponivel', FALSE, 2, 1, 4);

-- Acessorios
INSERT INTO acessorio (nome) VALUES ('GPS'), ('Bluetooth'), ('Airbag');

-- Reservas (30)
INSERT INTO reserva (cliente_id, grupo_id, patio_retirada_id, patio_devolucao_id, data_inicio, data_fim, status)
SELECT
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 5) + 1,
    ((gs - 1) % 6) + 1,
    ((gs * 3 - 1) % 6) + 1,
    DATE '2024-04-01' + (gs * 9)::INTEGER,
    DATE '2024-04-01' + (gs * 9)::INTEGER + (4 + gs % 6),
    CASE WHEN gs % 10 = 0 THEN 'cancelada'
         WHEN gs % 7  = 0 THEN 'espera'
         WHEN gs % 3  = 0 THEN 'confirmada'
         ELSE 'ativa' END
FROM generate_series(1, 30) gs;

-- Locacoes (60)
INSERT INTO locacao (reserva_id, veiculo_id, condutor_id, patio_retirada_id, patio_devolucao_id,
                     data_retirada_prevista, data_retirada_realizada,
                     data_devolucao_prevista, data_devolucao_realizada,
                     estado_entrega, estado_devolucao, km_entrega, km_devolucao)
SELECT
    NULL,
    ((gs - 1) % 20) + 1,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 6) + 1,
    CASE WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1 ELSE ((gs - 1) % 6) + 1 END,
    TIMESTAMP '2024-05-01 10:00:00' + (gs * INTERVAL '3 days'),
    CASE WHEN gs % 5 = 4 THEN NULL ELSE TIMESTAMP '2024-05-01 10:30:00' + (gs * INTERVAL '3 days') END,
    TIMESTAMP '2024-05-01 10:00:00' + (gs * INTERVAL '3 days') + ((3 + gs % 6) * INTERVAL '1 day'),
    CASE
      WHEN gs % 10 = 9 THEN NULL
      WHEN gs % 5  = 4 THEN NULL
      ELSE TIMESTAMP '2024-05-01 10:00:00' + (gs * INTERVAL '3 days') + ((3 + gs % 6) * INTERVAL '1 day')
    END,
    'Sem avarias',
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 'Sem avarias' END,
    CASE WHEN gs % 5 = 4 THEN NULL ELSE 10000 + gs * 50 END,
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 10000 + gs * 50 + 100 END
FROM generate_series(1, 60) gs;

-- Cobrancas
INSERT INTO cobranca (locacao_id, valor, status, data_pagamento)
SELECT l.id,
       300.00 + (l.id % 5) * 50,
       'pago',
       DATE(l.data_devolucao_realizada)
FROM locacao l WHERE l.data_devolucao_realizada IS NOT NULL;

-- Seguros
INSERT INTO seguro (tipo, valor) VALUES ('Basico', 29.90), ('Completo', 59.90);

INSERT INTO movimentacao_patio (veiculo_id, origem_patio_id, destino_patio_id, motivo) VALUES
  (3, 1, 6, 'Reposicionamento de frota'),
  (10, 1, 5, 'Devolucao em patio diferente');


-- =====================================================================
-- FONTE 4 — src_bd_dw_26_1 (dona do Shopping Rio Sul)
-- Identity columns: usar OVERRIDING SYSTEM VALUE p/ controlar IDs.
-- =====================================================================

SET search_path = src_bd_dw_26_1;

-- Enderecos (1 por patio + 1 por empresa + 30 clientes = 36)
INSERT INTO Endereco (Id_endereco, Uf, Cep, Cidade, Bairro, Logradouro, Numero, Complemento) OVERRIDING SYSTEM VALUE VALUES
  (1, 'RJ', '22290240', 'Rio de Janeiro', 'Botafogo',         'Rua Lauro Muller',       '116',  'Shopping'),  -- Rio Sul (proprio)
  (2, 'RJ', '21941900', 'Rio de Janeiro', 'Ilha do Governador','Av. 20 de Janeiro',     's/n',  'Aeroporto'),
  (3, 'RJ', '20021340', 'Rio de Janeiro', 'Centro',           'Praca Sen. Salgado Filho','s/n', 'Aeroporto'),
  (4, 'RJ', '20211110', 'Rio de Janeiro', 'Santo Cristo',     'Av. Francisco Bicalho',   '1',   'Rodoviaria'),
  (5, 'RJ', '20765001', 'Rio de Janeiro', 'Del Castilho',     'Av. Pastor M Luther King','126','Shopping'),
  (6, 'RJ', '22640102', 'Rio de Janeiro', 'Barra da Tijuca',  'Av. das Americas',        '4666','Shopping'),
  -- Cliente PFs
  (10, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Rua A',  '10', NULL),
  (11, 'RJ', '24020012', 'Niteroi',        'Icarai',        'Rua B',  '11', NULL),
  (12, 'SP', '01310100', 'Sao Paulo',      'Bela Vista',    'Rua C',  '12', NULL),
  (13, 'MG', '30130001', 'Belo Horizonte', 'Centro',        'Rua D',  '13', NULL),
  (14, 'RJ', '24439900', 'Sao Goncalo',    'Centro',        'Rua E',  '14', NULL),
  (15, 'RJ', '25055090', 'Duque de Caxias','Centro',        'Rua F',  '15', NULL),
  (16, 'ES', '29010301', 'Vitoria',        'Centro',        'Rua G',  '16', NULL),
  (17, 'PR', '80020100', 'Curitiba',       'Centro',        'Rua H',  '17', NULL),
  (18, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Rua I',  '18', NULL),
  (19, 'RJ', '24020012', 'Niteroi',        'Icarai',        'Rua J',  '19', NULL),
  (20, 'SP', '01310100', 'Sao Paulo',      'Bela Vista',    'Rua K',  '20', NULL),
  (21, 'MG', '30130001', 'Belo Horizonte', 'Centro',        'Rua L',  '21', NULL),
  (22, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Rua M',  '22', NULL),
  (23, 'RJ', '24439900', 'Sao Goncalo',    'Centro',        'Rua N',  '23', NULL),
  (24, 'RJ', '25055090', 'Duque de Caxias','Centro',        'Rua O',  '24', NULL),
  (25, 'ES', '29010301', 'Vitoria',        'Centro',        'Rua P',  '25', NULL),
  (26, 'PR', '80020100', 'Curitiba',       'Centro',        'Rua Q',  '26', NULL),
  (27, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Rua R',  '27', NULL),
  (28, 'RJ', '24020012', 'Niteroi',        'Icarai',        'Rua S',  '28', NULL),
  (29, 'SP', '01310100', 'Sao Paulo',      'Bela Vista',    'Rua T',  '29', NULL),
  (30, 'MG', '30130001', 'Belo Horizonte', 'Centro',        'Rua U',  '30', NULL),
  (31, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Rua V',  '31', NULL),
  (32, 'RJ', '24439900', 'Sao Goncalo',    'Centro',        'Rua W',  '32', NULL),
  (33, 'RJ', '25055090', 'Duque de Caxias','Centro',        'Rua X',  '33', NULL),
  (34, 'ES', '29010301', 'Vitoria',        'Centro',        'Rua Y',  '34', NULL),
  -- Clientes PJ
  (35, 'RJ', '20040020', 'Rio de Janeiro', 'Centro',        'Av PJ1', '100', 'Conj 101'),
  (36, 'MG', '30130001', 'Belo Horizonte', 'Centro',        'Av PJ2', '200', 'Conj 202'),
  (37, 'SP', '01310100', 'Sao Paulo',      'Bela Vista',    'Av PJ3', '300', 'Conj 303'),
  (38, 'RJ', '24020012', 'Niteroi',        'Icarai',        'Av PJ4', '400', 'Conj 404'),
  (39, 'ES', '29010301', 'Vitoria',        'Centro',        'Av PJ5', '500', 'Conj 505'),
  -- Empresa propria
  (50, 'RJ', '22290240', 'Rio de Janeiro', 'Botafogo',      'Rua Empresa', '1', NULL);

-- Avancar identity para alem do maior id manual
SELECT setval(pg_get_serial_sequence('Endereco','id_endereco'), 100, false);

-- Empresa propria (uma so; demais patios sao "associados" mas representados como mesma empresa para simplicidade)
INSERT INTO Empresa (Id_empresa, Id_endereco, Nome_empresa, Cnpj_empresa) OVERRIDING SYSTEM VALUE VALUES
  (1, 50, 'BD-DW Locacoes Ltda',     '40000000000001'),
  (2, 2,  'Andre Gustavo Locacoes',  '40000000000002'),
  (3, 3,  'MAE016 Locacoes',         '40000000000003'),
  (4, 4,  'Locadora DB SA',          '40000000000004'),
  (5, 5,  'BigData Locacoes',        '40000000000005'),
  (6, 6,  'Barra Frota Associada',   '40000000000006');

SELECT setval(pg_get_serial_sequence('Empresa','id_empresa'), 10, false);

-- Patios: 6
INSERT INTO Patio (Id_patio, Id_empresa, Id_endereco, Nome_patio, Capacidade, Hora_abertura, Hora_fechamento, Funciona_24h) OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 1, 'Shopping Rio Sul',         100, TIME '06:00', TIME '23:00', FALSE),
  (2, 2, 2, 'Aeroporto do Galeao',      250, TIME '00:00', TIME '23:59', TRUE),
  (3, 3, 3, 'Aeroporto Santos Dumont',  150, TIME '06:00', TIME '23:00', FALSE),
  (4, 4, 4, 'Rodoviaria do Rio',        120, TIME '00:00', TIME '23:59', TRUE),
  (5, 5, 5, 'Shopping Nova America',    140, TIME '08:00', TIME '22:00', FALSE),
  (6, 6, 6, 'Barra Shopping',           180, TIME '08:00', TIME '22:00', FALSE);

SELECT setval(pg_get_serial_sequence('Patio','id_patio'), 10, false);

-- Categorias
INSERT INTO Categoria (Id_categoria, Nome_categoria, Descricao_categoria, Valor_diaria_base) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Economico',     'Hatch compacto',     115.00),
  (2, 'Intermediario', 'Sedan compacto',     175.00),
  (3, 'Executivo',     'Sedan executivo',    260.00),
  (4, 'SUV',           'Utilitario',         295.00),
  (5, 'Luxo',          'Premium',            489.00);

SELECT setval(pg_get_serial_sequence('Categoria','id_categoria'), 10, false);

-- Veiculos (20)
INSERT INTO Veiculo (Id_veiculo, Id_empresa, Id_categoria, Id_vaga, Placa, Chassi, Marca, Modelo, Ano, Cor, Tipo_cambio, Possui_ar_condicionado, Capacidade_pessoas, Capacidade_porta_malas, Dimensoes, Km_atual, Status_veiculo) OVERRIDING SYSTEM VALUE VALUES
  (1,  1, 1, NULL, 'BDW0A01', '9BBDWA0100000A01', 'Chevrolet','Onix',     2022, 'Prata',   'Manual',    TRUE, 5, 280, 'Pequeno',  18000, 'DISPONIVEL'),
  (2,  1, 1, NULL, 'BDW0A02', '9BBDWA0200000A02', 'Hyundai',  'HB20',     2023, 'Branco',  'Automatico',TRUE, 5, 300, 'Pequeno',  14000, 'DISPONIVEL'),
  (3,  1, 1, NULL, 'BDW0A03', '9BBDWA0300000A03', 'Fiat',     'Mobi',     2021, 'Vermelho','Manual',    TRUE, 5, 235, 'Pequeno',  30000, 'ALUGADO'),
  (4,  1, 1, NULL, 'BDW0A04', '9BBDWA0400000A04', 'Renault',  'Kwid',     2022, 'Laranja', 'Manual',    TRUE, 5, 290, 'Pequeno',  20000, 'DISPONIVEL'),
  (5,  1, 2, NULL, 'BDW0B01', '9BBDWB0100000B01', 'Volkswagen','Polo',    2023, 'Cinza',   'Automatico',TRUE, 5, 350, 'Medio',    10000, 'DISPONIVEL'),
  (6,  1, 2, NULL, 'BDW0B02', '9BBDWB0200000B02', 'Fiat',     'Argo',     2022, 'Branco',  'Manual',    TRUE, 5, 300, 'Medio',    23000, 'ALUGADO'),
  (7,  1, 2, NULL, 'BDW0B03', '9BBDWB0300000B03', 'Hyundai',  'HB20S',    2023, 'Preto',   'Automatico',TRUE, 5, 410, 'Medio',    12000, 'DISPONIVEL'),
  (8,  1, 2, NULL, 'BDW0B04', '9BBDWB0400000B04', 'Chevrolet','Onix Plus',2024, 'Azul',    'Automatico',TRUE, 5, 400, 'Medio',    6000,  'DISPONIVEL'),
  (9,  1, 3, NULL, 'BDW0C01', '9BBDWC0100000C01', 'Toyota',   'Corolla',  2023, 'Preto',   'Automatico',TRUE, 5, 470, 'Grande',   15000, 'DISPONIVEL'),
  (10, 1, 3, NULL, 'BDW0C02', '9BBDWC0200000C02', 'Honda',    'Civic',    2022, 'Prata',   'Automatico',TRUE, 5, 460, 'Grande',   20000, 'ALUGADO'),
  (11, 1, 3, NULL, 'BDW0C03', '9BBDWC0300000C03', 'Nissan',   'Sentra',   2023, 'Branco',  'Automatico',TRUE, 5, 450, 'Grande',   9000,  'DISPONIVEL'),
  (12, 1, 4, NULL, 'BDW0D01', '9BBDWD0100000D01', 'Jeep',     'Compass',  2023, 'Cinza',   'Automatico',TRUE, 5, 410, 'SUV',      17000, 'DISPONIVEL'),
  (13, 1, 4, NULL, 'BDW0D02', '9BBDWD0200000D02', 'Volkswagen','T-Cross', 2022, 'Vermelho','Automatico',TRUE, 5, 380, 'SUV',      26000, 'ALUGADO'),
  (14, 1, 4, NULL, 'BDW0D03', '9BBDWD0300000D03', 'Hyundai',  'Creta',    2024, 'Branco',  'Automatico',TRUE, 5, 400, 'SUV',      5000,  'DISPONIVEL'),
  (15, 1, 4, NULL, 'BDW0D04', '9BBDWD0400000D04', 'Chevrolet','Tracker',  2023, 'Preto',   'Automatico',TRUE, 5, 393, 'SUV',      13000, 'DISPONIVEL'),
  (16, 1, 5, NULL, 'BDW0E01', '9BBDWE0100000E01', 'Audi',     'A4',       2023, 'Preto',   'Automatico',TRUE, 5, 480, 'Grande',   8000,  'DISPONIVEL'),
  (17, 1, 5, NULL, 'BDW0E02', '9BBDWE0200000E02', 'BMW',      '320i',     2024, 'Branco',  'Automatico',TRUE, 5, 480, 'Grande',   4500,  'DISPONIVEL'),
  (18, 1, 5, NULL, 'BDW0E03', '9BBDWE0300000E03', 'Mercedes', 'C200',     2023, 'Cinza',   'Automatico',TRUE, 5, 490, 'Grande',   11000, 'ALUGADO'),
  (19, 1, 1, NULL, 'BDW0A05', '9BBDWA0500000A05', 'Volkswagen','Gol',     2021, 'Branco',  'Manual',    TRUE, 5, 280, 'Pequeno',  31000, 'MANUTENCAO'),
  (20, 1, 2, NULL, 'BDW0B05', '9BBDWB0500000B05', 'Fiat',     'Cronos',   2022, 'Prata',   'Automatico',TRUE, 5, 390, 'Medio',    22000, 'DISPONIVEL');

SELECT setval(pg_get_serial_sequence('Veiculo','id_veiculo'), 30, false);

-- Clientes (25 PF + 5 PJ = 30)
INSERT INTO Cliente (Id_cliente, Id_endereco, Tipo_cliente, Email_cliente, Telefone_cliente) OVERRIDING SYSTEM VALUE VALUES
  (1, 10,'PF','cli1@bdw.com', '(21) 99500-0001'),  (2, 11,'PF','cli2@bdw.com', '(21) 99500-0002'),
  (3, 12,'PF','cli3@bdw.com', '(11) 99500-0003'),  (4, 13,'PF','cli4@bdw.com', '(31) 99500-0004'),
  (5, 14,'PF','cli5@bdw.com', '(21) 99500-0005'),  (6, 15,'PF','cli6@bdw.com', '(21) 99500-0006'),
  (7, 16,'PF','cli7@bdw.com', '(27) 99500-0007'),  (8, 17,'PF','cli8@bdw.com', '(41) 99500-0008'),
  (9, 18,'PF','cli9@bdw.com', '(21) 99500-0009'),  (10,19,'PF','cli10@bdw.com','(21) 99500-0010'),
  (11,20,'PF','cli11@bdw.com','(11) 99500-0011'),  (12,21,'PF','cli12@bdw.com','(31) 99500-0012'),
  (13,22,'PF','cli13@bdw.com','(21) 99500-0013'),  (14,23,'PF','cli14@bdw.com','(21) 99500-0014'),
  (15,24,'PF','cli15@bdw.com','(21) 99500-0015'),  (16,25,'PF','cli16@bdw.com','(27) 99500-0016'),
  (17,26,'PF','cli17@bdw.com','(41) 99500-0017'),  (18,27,'PF','cli18@bdw.com','(21) 99500-0018'),
  (19,28,'PF','cli19@bdw.com','(21) 99500-0019'),  (20,29,'PF','cli20@bdw.com','(11) 99500-0020'),
  (21,30,'PF','cli21@bdw.com','(31) 99500-0021'),  (22,31,'PF','cli22@bdw.com','(21) 99500-0022'),
  (23,32,'PF','cli23@bdw.com','(21) 99500-0023'),  (24,33,'PF','cli24@bdw.com','(21) 99500-0024'),
  (25,34,'PF','cli25@bdw.com','(27) 99500-0025'),
  (26,35,'PJ','pj1@bdw.com',  '(21) 99500-0026'),  (27,36,'PJ','pj2@bdw.com',  '(31) 99500-0027'),
  (28,37,'PJ','pj3@bdw.com',  '(11) 99500-0028'),  (29,38,'PJ','pj4@bdw.com',  '(21) 99500-0029'),
  (30,39,'PJ','pj5@bdw.com',  '(27) 99500-0030');

SELECT setval(pg_get_serial_sequence('Cliente','id_cliente'), 50, false);

-- Cliente_pf
INSERT INTO Cliente_pf (Id_cliente, Nome_cliente, Cpf_cliente, Data_nascimento_cliente, Genero_cliente)
SELECT c.Id_cliente,
       'Cliente PF ' || c.Id_cliente,
       LPAD(c.Id_cliente::TEXT, 11, '4'),
       (DATE '1985-01-01' + (c.Id_cliente * 97)),
       CASE WHEN c.Id_cliente % 2 = 0 THEN 'F' ELSE 'M' END
FROM Cliente c WHERE c.Tipo_cliente = 'PF';

-- Cliente_pj
INSERT INTO Cliente_pj (Id_cliente, Razao_social, Nome_fantasia, Cnpj_cliente)
SELECT c.Id_cliente,
       'Razao Social PJ ' || c.Id_cliente,
       'Fantasia ' || c.Id_cliente,
       LPAD(c.Id_cliente::TEXT, 14, '4')
FROM Cliente c WHERE c.Tipo_cliente = 'PJ';

-- Motoristas (1 por cliente)
INSERT INTO Motorista (Id_motorista, Id_cliente, Nome_motorista, Numero_cnh, Categoria_cnh, Validade_cnh, Data_nascimento_motorista, Email_motorista, Telefone_motorista, Genero_motorista, Relacao_motorista_cliente) OVERRIDING SYSTEM VALUE
SELECT c.Id_cliente, c.Id_cliente,
       'Motorista ' || c.Id_cliente,
       'CNHBDW' || LPAD(c.Id_cliente::TEXT, 14, '0'),
       'B',
       DATE '2031-12-31',
       (DATE '1985-01-01' + (c.Id_cliente * 97)),
       'motorista' || c.Id_cliente || '@bdw.com',
       '(21) 99500-' || LPAD(c.Id_cliente::TEXT, 4, '0'),
       CASE WHEN c.Id_cliente % 2 = 0 THEN 'F' ELSE 'M' END,
       'Titular'
FROM Cliente c;

SELECT setval(pg_get_serial_sequence('Motorista','id_motorista'), 50, false);

-- Reservas (30)
INSERT INTO Reserva (Id_reserva, Id_cliente, Id_categoria, Id_patio_previsto_retirada, Id_patio_previsto_devolucao,
                     Data_hora_reserva, Data_previsao_retirada, Data_previsao_devolucao, Valor_previsto, Status_reserva) OVERRIDING SYSTEM VALUE
SELECT
    gs,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 5) + 1,
    ((gs - 1) % 6) + 1,
    ((gs * 3 - 1) % 6) + 1,
    TIMESTAMP '2024-06-01 10:00:00' + (gs * INTERVAL '10 days'),
    TIMESTAMP '2024-06-01 10:00:00' + (gs * INTERVAL '10 days') + INTERVAL '2 days',
    TIMESTAMP '2024-06-01 10:00:00' + (gs * INTERVAL '10 days') + ((6 + gs % 5) * INTERVAL '1 day'),
    500.00 + (gs % 7) * 80,
    CASE WHEN gs % 10 = 0 THEN 'CANCELADA'
         WHEN gs % 5  = 0 THEN 'ATENDIDA'
         ELSE 'CONFIRMADA' END
FROM generate_series(1, 30) gs;

SELECT setval(pg_get_serial_sequence('Reserva','id_reserva'), 100, false);

-- Locacoes (60). UQ_Loc_Reserva exige Id_reserva unico por locacao,
-- entao geramos 60 reservas-stub adicionais (101..160) so para satisfazer FK.
INSERT INTO Reserva (Id_reserva, Id_cliente, Id_categoria, Id_patio_previsto_retirada, Id_patio_previsto_devolucao,
                     Data_hora_reserva, Data_previsao_retirada, Data_previsao_devolucao, Valor_previsto, Status_reserva) OVERRIDING SYSTEM VALUE
SELECT
    100 + gs,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 5) + 1,
    ((gs - 1) % 6) + 1,
    CASE WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1 ELSE ((gs - 1) % 6) + 1 END,
    TIMESTAMP '2024-07-01 09:00:00' + (gs * INTERVAL '3 days'),
    TIMESTAMP '2024-07-01 09:00:00' + (gs * INTERVAL '3 days') + INTERVAL '1 day',
    TIMESTAMP '2024-07-01 09:00:00' + (gs * INTERVAL '3 days') + ((4 + gs % 6) * INTERVAL '1 day'),
    600.00 + (gs % 5) * 90,
    'ATENDIDA'
FROM generate_series(1, 60) gs;

SELECT setval(pg_get_serial_sequence('Reserva','id_reserva'), 200, false);

INSERT INTO Locacao (Id_locacao, Id_reserva, Id_veiculo, Id_motorista, Id_patio_real_retirada, Id_patio_real_devolucao,
                     Data_hora_retirada_real, Data_hora_devolucao_real,
                     Estado_veiculo_retirada, Estado_veiculo_devolucao,
                     Km_retirada, Km_devolucao, Valor_total_final, Status_locacao) OVERRIDING SYSTEM VALUE
SELECT
    gs,
    100 + gs,
    ((gs - 1) % 20) + 1,
    ((gs - 1) % 30) + 1,
    ((gs - 1) % 6) + 1,
    CASE WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1 ELSE ((gs - 1) % 6) + 1 END,
    TIMESTAMP '2024-07-01 10:00:00' + (gs * INTERVAL '3 days'),
    CASE
      WHEN gs % 10 = 9 THEN NULL
      WHEN gs % 5  = 4 THEN NULL
      ELSE TIMESTAMP '2024-07-01 10:00:00' + (gs * INTERVAL '3 days') + ((3 + gs % 5) * INTERVAL '1 day')
    END,
    'OK',
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 'OK' END,
    20000 + gs * 30,
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 20000 + gs * 30 + 100 END,
    CASE WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL ELSE 600.00 + (gs % 5) * 90 END,
    CASE WHEN gs % 10 = 9 THEN 'EM_ANDAMENTO'
         WHEN gs % 5  = 4 THEN 'CANCELADA'
         ELSE 'CONCLUIDA' END
FROM generate_series(1, 60) gs;

SELECT setval(pg_get_serial_sequence('Locacao','id_locacao'), 100, false);


-- =====================================================================
-- FONTE 5 — src_bigdata (dona do Shopping Nova America)
-- Sem AUTO_INCREMENT no DDL original; IDs explicitos.
-- =====================================================================

SET search_path = src_bigdata;

-- Enderecos
INSERT INTO Endereco (IDEndereco, CEP, UF, Cidade, Bairro, Logradouro, Numero) VALUES
  (1, '20765001', 'RJ', 'Rio de Janeiro', 'Del Castilho',     'Av. Pastor M Luther King', '126'),
  (2, '21941900', 'RJ', 'Rio de Janeiro', 'Ilha do Governador','Av. 20 de Janeiro',       's/n'),
  (3, '20021340', 'RJ', 'Rio de Janeiro', 'Centro',           'Praca Sen. Salgado Filho','s/n'),
  (4, '20211110', 'RJ', 'Rio de Janeiro', 'Santo Cristo',     'Av. Francisco Bicalho',   '1'),
  (5, '22290240', 'RJ', 'Rio de Janeiro', 'Botafogo',         'Rua Lauro Muller',        '116'),
  (6, '22640102', 'RJ', 'Rio de Janeiro', 'Barra da Tijuca',  'Av. das Americas',        '4666'),
  -- Empresas/parceiras
  (7, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',           'Rua Empresa BD',          '99'),
  -- 30 enderecos cliente
  (10, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Rua A',                   '10'),
  (11, '24020012', 'RJ', 'Niteroi',        'Icarai',          'Rua B',                   '11'),
  (12, '01310100', 'SP', 'Sao Paulo',      'Bela Vista',      'Rua C',                   '12'),
  (13, '30130001', 'MG', 'Belo Horizonte', 'Centro',          'Rua D',                   '13'),
  (14, '24439900', 'RJ', 'Sao Goncalo',    'Centro',          'Rua E',                   '14'),
  (15, '25055090', 'RJ', 'Duque de Caxias','Centro',          'Rua F',                   '15'),
  (16, '29010301', 'ES', 'Vitoria',        'Centro',          'Rua G',                   '16'),
  (17, '80020100', 'PR', 'Curitiba',       'Centro',          'Rua H',                   '17'),
  (18, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Rua I',                   '18'),
  (19, '24020012', 'RJ', 'Niteroi',        'Icarai',          'Rua J',                   '19'),
  (20, '01310100', 'SP', 'Sao Paulo',      'Bela Vista',      'Rua K',                   '20'),
  (21, '30130001', 'MG', 'Belo Horizonte', 'Centro',          'Rua L',                   '21'),
  (22, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Rua M',                   '22'),
  (23, '24439900', 'RJ', 'Sao Goncalo',    'Centro',          'Rua N',                   '23'),
  (24, '25055090', 'RJ', 'Duque de Caxias','Centro',          'Rua O',                   '24'),
  (25, '29010301', 'ES', 'Vitoria',        'Centro',          'Rua P',                   '25'),
  (26, '80020100', 'PR', 'Curitiba',       'Centro',          'Rua Q',                   '26'),
  (27, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Rua R',                   '27'),
  (28, '24020012', 'RJ', 'Niteroi',        'Icarai',          'Rua S',                   '28'),
  (29, '01310100', 'SP', 'Sao Paulo',      'Bela Vista',      'Rua T',                   '29'),
  (30, '30130001', 'MG', 'Belo Horizonte', 'Centro',          'Rua U',                   '30'),
  (31, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Rua V',                   '31'),
  (32, '24439900', 'RJ', 'Sao Goncalo',    'Centro',          'Rua W',                   '32'),
  (33, '25055090', 'RJ', 'Duque de Caxias','Centro',          'Rua X',                   '33'),
  (34, '29010301', 'ES', 'Vitoria',        'Centro',          'Rua Y',                   '34'),
  -- 5 PJ
  (35, '20040020', 'RJ', 'Rio de Janeiro', 'Centro',          'Av PJ1',                  '100'),
  (36, '30130001', 'MG', 'Belo Horizonte', 'Centro',          'Av PJ2',                  '200'),
  (37, '01310100', 'SP', 'Sao Paulo',      'Bela Vista',      'Av PJ3',                  '300'),
  (38, '24020012', 'RJ', 'Niteroi',        'Icarai',          'Av PJ4',                  '400'),
  (39, '29010301', 'ES', 'Vitoria',        'Centro',          'Av PJ5',                  '500');

-- Parceiras (1 por patio, 6 parceiras totais para satisfazer FK do Patio)
INSERT INTO Parceira (IDParceira, CNPJ, Nome) VALUES
  (1, '50000000000001', 'BigData Locacoes SA'),
  (2, '50000000000002', 'Andre Gustavo Parceira'),
  (3, '50000000000003', 'MAE016 Parceira'),
  (4, '50000000000004', 'Locadora DB Parceira'),
  (5, '50000000000005', 'BD-DW Parceira'),
  (6, '50000000000006', 'Barra Parceira');

-- Patios (proprio + 5 associados)
INSERT INTO Patio (IDPatio, CDPatio, Lotacao, HorarioAbertura, HorarioFechamento, IDEndereco, IDParceira) VALUES
  (1, 'BD-NAM', 140, TIME '08:00', TIME '22:00', 1, 1),
  (2, 'BD-GIG', 250, TIME '00:00', TIME '23:59', 2, 2),
  (3, 'BD-SDU', 150, TIME '06:00', TIME '23:00', 3, 3),
  (4, 'BD-ROD', 120, TIME '00:00', TIME '23:59', 4, 4),
  (5, 'BD-RSL', 100, TIME '06:00', TIME '23:00', 5, 5),
  (6, 'BD-BRR', 180, TIME '08:00', TIME '22:00', 6, 6);

-- Vagas (1 por patio para suportar FKs de Movimentacao/Locacao)
INSERT INTO Vaga (IDVaga, CodVaga, Coberta, Andar, IDPatio) VALUES
  (1, 'BD-V001', TRUE, 1, 1), (2, 'BD-V002', TRUE, 1, 2), (3, 'BD-V003', TRUE, 1, 3),
  (4, 'BD-V004', TRUE, 1, 4), (5, 'BD-V005', TRUE, 1, 5), (6, 'BD-V006', TRUE, 1, 6),
  (7, 'BD-V007', TRUE, 1, 1), (8, 'BD-V008', TRUE, 1, 2), (9, 'BD-V009', TRUE, 1, 3),
  (10,'BD-V010', TRUE, 1, 4), (11,'BD-V011', TRUE, 1, 5), (12,'BD-V012', TRUE, 1, 6);

-- Categorias
INSERT INTO Categoria (IDCategoria, Classificacao, ClasseLuxo, ValorDiariaBase, Tracao4x4) VALUES
  (1, 'Economico',     'C', 119.00, FALSE),
  (2, 'Intermediario', 'B', 179.00, FALSE),
  (3, 'Executivo',     'B', 259.00, FALSE),
  (4, 'SUV',           'B', 299.00, TRUE),
  (5, 'Luxo',          'A', 499.00, FALSE);

-- Veiculos (20)
INSERT INTO Veiculo (IDVeiculo, Placa, Chassi, Modelo, Ano, Altura, Largura, Portas, UltimaKilometragem,
                     ArCondicionado, CadeiraInfantil, BebeConforto, ValorDiaria, IDCategoria) VALUES
  (1,  'BIG0A01', '9BBGA0100000000A01', 'Onix',      2022, 1.48, 1.72, 4, 17000, TRUE, FALSE, FALSE, 119.00, 1),
  (2,  'BIG0A02', '9BBGA0200000000A02', 'HB20',      2023, 1.47, 1.73, 4, 13000, TRUE, TRUE,  FALSE, 119.00, 1),
  (3,  'BIG0A03', '9BBGA0300000000A03', 'Mobi',      2021, 1.48, 1.67, 4, 30000, TRUE, FALSE, FALSE, 109.00, 1),
  (4,  'BIG0A04', '9BBGA0400000000A04', 'Kwid',      2022, 1.48, 1.59, 5, 19000, TRUE, FALSE, TRUE,  109.00, 1),
  (5,  'BIG0B01', '9BBGB0100000000B01', 'Polo',      2023, 1.46, 1.75, 4, 10000, TRUE, TRUE,  FALSE, 179.00, 2),
  (6,  'BIG0B02', '9BBGB0200000000B02', 'Argo',      2022, 1.51, 1.72, 4, 22000, TRUE, FALSE, FALSE, 169.00, 2),
  (7,  'BIG0B03', '9BBGB0300000000B03', 'HB20S',     2023, 1.46, 1.73, 4, 12000, TRUE, FALSE, FALSE, 179.00, 2),
  (8,  'BIG0B04', '9BBGB0400000000B04', 'Onix Plus', 2024, 1.46, 1.72, 4, 5500,  TRUE, TRUE,  FALSE, 189.00, 2),
  (9,  'BIG0C01', '9BBGC0100000000C01', 'Corolla',   2023, 1.45, 1.78, 4, 14000, TRUE, FALSE, FALSE, 259.00, 3),
  (10, 'BIG0C02', '9BBGC0200000000C02', 'Civic',     2022, 1.42, 1.80, 4, 19500, TRUE, FALSE, FALSE, 269.00, 3),
  (11, 'BIG0C03', '9BBGC0300000000C03', 'Sentra',    2023, 1.44, 1.76, 4, 9000,  TRUE, FALSE, FALSE, 249.00, 3),
  (12, 'BIG0D01', '9BBGD0100000000D01', 'Compass',   2023, 1.63, 1.82, 4, 16000, TRUE, TRUE,  TRUE,  299.00, 4),
  (13, 'BIG0D02', '9BBGD0200000000D02', 'T-Cross',   2022, 1.58, 1.76, 4, 24000, TRUE, FALSE, FALSE, 289.00, 4),
  (14, 'BIG0D03', '9BBGD0300000000D03', 'Creta',     2024, 1.63, 1.79, 4, 4500,  TRUE, FALSE, TRUE,  309.00, 4),
  (15, 'BIG0D04', '9BBGD0400000000D04', 'Tracker',   2023, 1.65, 1.79, 4, 12500, TRUE, TRUE,  FALSE, 299.00, 4),
  (16, 'BIG0E01', '9BBGE0100000000E01', 'A4',        2023, 1.43, 1.84, 4, 7000,  TRUE, FALSE, FALSE, 499.00, 5),
  (17, 'BIG0E02', '9BBGE0200000000E02', '320i',      2024, 1.44, 1.83, 4, 4000,  TRUE, FALSE, FALSE, 549.00, 5),
  (18, 'BIG0E03', '9BBGE0300000000E03', 'C200',      2023, 1.45, 1.81, 4, 10500, TRUE, FALSE, FALSE, 599.00, 5),
  (19, 'BIG0A05', '9BBGA0500000000A05', 'Gol',       2021, 1.46, 1.65, 4, 32000, TRUE, FALSE, FALSE, 99.00,  1),
  (20, 'BIG0B05', '9BBGB0500000000B05', 'Cronos',    2022, 1.47, 1.73, 4, 21500, TRUE, FALSE, FALSE, 169.00, 2);

-- PessoaFisica (25)
INSERT INTO PessoaFisica (IDFisica, CPF, Nome, DtNascimento, RG, Telefone, IDEndereco)
SELECT gs,
       LPAD(gs::TEXT, 11, '5'),
       'Pessoa Fisica ' || gs,
       (DATE '1985-01-01' + (gs * 137)),
       'RG' || LPAD(gs::TEXT, 8, '0'),
       '(21) 99300-' || LPAD(gs::TEXT, 4, '0'),
       9 + gs  -- enderecos 10..34
FROM generate_series(1, 25) gs;

-- Empresa (5 PJs)
INSERT INTO Empresa (IDEmpresa, CNPJ, RazaoSocial, DtAbertura, Telefone, IDEndereco) VALUES
  (1, '60000000000001', 'Rio Tour Servicos Ltda',   DATE '2010-01-15', '(21) 99300-0026', 35),
  (2, '60000000000002', 'BH Frota Empresarial SA',  DATE '2012-02-20', '(31) 99300-0027', 36),
  (3, '60000000000003', 'SP Move Locacoes ME',      DATE '2014-03-25', '(11) 99300-0028', 37),
  (4, '60000000000004', 'Niteroi Travel Ltda',      DATE '2016-04-30', '(21) 99300-0029', 38),
  (5, '60000000000005', 'ES Cargas SA',             DATE '2018-05-05', '(27) 99300-0030', 39);

-- Motoristas (1 por pessoa fisica)
INSERT INTO Motorista (IDMotorista, CNH, CategoriaCNH, IDFisica)
SELECT gs,
       'BG-CNH' || LPAD(gs::TEXT, 14, '0'),
       'B',
       gs
FROM generate_series(1, 25) gs;

-- CentroCusto: 25 PF + 5 PJ = 30, com IDResponsavel apontando para PF
INSERT INTO CentroCusto (IDCentroCusto, IDEmpresa, IDFisica, IDResponsavel)
SELECT gs, NULL, gs, gs FROM generate_series(1, 25) gs
UNION ALL
SELECT 25 + gs, gs, NULL, gs FROM generate_series(1, 5) gs;

-- Reservas (30). DtLimiteRetirada > DtRetiradaPrevista (strict).
INSERT INTO Reserva (IDReserva, QtVeiculosSolicitados, DtReserva, DtRetiradaPrevista, DtLimiteRetirada, Status, IDCentroCusto)
SELECT
    gs,
    CASE WHEN gs % 5 = 0 THEN 2 ELSE 1 END,
    TIMESTAMP '2024-08-01 10:00:00' + (gs * INTERVAL '8 days'),
    TIMESTAMP '2024-08-01 10:00:00' + (gs * INTERVAL '8 days') + INTERVAL '5 days',
    TIMESTAMP '2024-08-01 10:00:00' + (gs * INTERVAL '8 days') + INTERVAL '12 days',
    CASE WHEN gs % 10 = 0 THEN 'Cancelada'
         WHEN gs % 4 = 0 THEN 'Atendida'
         ELSE 'Confirmada' END,
    ((gs - 1) % 30) + 1
FROM generate_series(1, 30) gs;

-- Reservas-stub adicionais para satisfazer FK 1:1 com Locacao
INSERT INTO Reserva (IDReserva, QtVeiculosSolicitados, DtReserva, DtRetiradaPrevista, DtLimiteRetirada, Status, IDCentroCusto)
SELECT
    100 + gs,
    1,
    TIMESTAMP '2024-09-01 09:00:00' + (gs * INTERVAL '2 days'),
    TIMESTAMP '2024-09-01 09:00:00' + (gs * INTERVAL '2 days') + INTERVAL '1 day',
    TIMESTAMP '2024-09-01 09:00:00' + (gs * INTERVAL '2 days') + INTERVAL '10 days',
    'Atendida',
    ((gs - 1) % 30) + 1
FROM generate_series(1, 60) gs;

-- Locacoes (60). IDVagaRetirada vai pra vaga do patio_retirada.
-- Mapping: patio K (1..6) -> vagas 2*K-1 ou 2*K-1+6.
INSERT INTO Locacao (IDLocacao, ValorDiaria, DtRetirada, DtChegada, IDVagaRetirada, IDVagaDevolvida,
                     IDVeiculo, IDReserva, IDMotorista)
SELECT
    gs,
    120.00 + (gs % 5) * 70,
    TIMESTAMP '2024-09-15 10:00:00' + (gs * INTERVAL '3 days'),
    CASE
      WHEN gs % 10 = 9 THEN NULL
      WHEN gs % 5  = 4 THEN NULL
      ELSE TIMESTAMP '2024-09-15 10:00:00' + (gs * INTERVAL '3 days') + ((3 + gs % 5) * INTERVAL '1 day')
    END,
    ((gs - 1) % 6) + 1,            -- vaga 1..6 corresponde a patio 1..6
    CASE
      WHEN gs % 10 = 9 OR gs % 5 = 4 THEN NULL
      WHEN gs % 10 < 4 THEN ((gs * 5 - 1) % 6) + 1
      ELSE ((gs - 1) % 6) + 1
    END,
    ((gs - 1) % 20) + 1,
    100 + gs,                       -- reserva stub
    ((gs - 1) % 25) + 1
FROM generate_series(1, 60) gs;


-- =====================================================================
-- Limpeza e fim
-- =====================================================================
RESET search_path;

-- =====================================================================
-- Fim do arquivo: staging/02_seed_fontes.sql
-- =====================================================================
