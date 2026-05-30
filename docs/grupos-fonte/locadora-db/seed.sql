-- =====================================
-- Nome: Tadeu Belfort Neto
-- DRE: 119034813 
-- Arquivo: seed.sql (versão revisada)
-- =====================================

-- EMPRESA
INSERT INTO empresa_locadora (nome, cnpj) VALUES
  ('Localiza', '16.670.085/0001-55'),
  ('Movida', '21.314.559/0001-66'),
  ('Unidas', '04.437.534/0001-30');

-- CLIENTE
INSERT INTO cliente (nome, tipo, cidade) VALUES
  ('Ana Paula Ribeiro', 'PF', 'Rio de Janeiro'),
  ('Bruno Henrique Souza', 'PF', 'Sao Paulo'),
  ('Carla Fernanda Almeida', 'PF', 'Belo Horizonte'),
  ('Diego Martins Oliveira', 'PF', 'Rio de Janeiro'),
  ('Fernanda Costa Lima', 'PF', 'Sao Paulo'),
  ('TechRio Consultoria Ltda', 'PJ', 'Rio de Janeiro');

-- CONDUTOR
INSERT INTO condutor (cliente_id, nome, cnh, validade, categoria, telefone) VALUES
  ((SELECT id FROM cliente WHERE nome = 'Ana Paula Ribeiro'), 'Ana Paula Ribeiro', '05246891320', '2030-05-14', 'B', '(21) 98811-2233'),
  ((SELECT id FROM cliente WHERE nome = 'Bruno Henrique Souza'), 'Bruno Henrique Souza', '06135792481', '2029-09-22', 'B', '(11) 97722-3344'),
  ((SELECT id FROM cliente WHERE nome = 'Carla Fernanda Almeida'), 'Carla Fernanda Almeida', '07315984620', '2031-01-30', 'B', '(31) 96633-4455'),
  ((SELECT id FROM cliente WHERE nome = 'Diego Martins Oliveira'), 'Diego Martins Oliveira', '08426013579', '2028-11-18', 'AB', '(21) 95544-5566'),
  ((SELECT id FROM cliente WHERE nome = 'Fernanda Costa Lima'), 'Fernanda Costa Lima', '09537124680', '2032-03-09', 'B', '(11) 94455-6677');

-- GRUPO_VEICULO
INSERT INTO grupo_veiculo (nome, categoria) VALUES
  ('Economico', 'Hatch compacto'),
  ('Intermediario', 'Hatch e sedan medio'),
  ('SUV', 'Utilitario esportivo'),
  ('Executivo', 'Sedan executivo');

-- PATIO
INSERT INTO patio (nome, cidade) VALUES
  ('Centro', 'Rio de Janeiro'),
  ('Aeroporto', 'Rio de Janeiro'),
  ('Zona Sul', 'Rio de Janeiro'),
  ('Centro', 'Sao Paulo'),
  ('Aeroporto', 'Belo Horizonte');

-- VEICULO
INSERT INTO veiculo (
  placa,
  chassi,
  modelo,
  marca,
  cor,
  tipo_mecanizacao,
  ar_condicionado,
  status,
  adaptado_cadeirante,
  grupo_id,
  empresa_id
) VALUES
  (
    'ABC1234',
    '9BGKS48U0MG123456',
    'Onix',
    'Chevrolet',
    'Prata',
    'manual',
    TRUE,
    'disponivel',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Localiza')
  ),
  (
    'DEF5678',
    '9BHHB20A0PG234567',
    'HB20',
    'Hyundai',
    'Branco',
    'automatico',
    TRUE,
    'disponivel',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Movida')
  ),
  (
    'GHI9012',
    '9BDARGOJ0NG345678',
    'Argo',
    'Fiat',
    'Vermelho',
    'manual',
    TRUE,
    'disponivel',
    TRUE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Intermediario'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Unidas')
  ),
  (
    'JKL3456',
    '9BWGOL5U0LP456789',
    'Gol',
    'Volkswagen',
    'Preto',
    'manual',
    FALSE,
    'alugado',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Localiza')
  ),
  (
    'MNO7890',
    '988COMPASS0K567890',
    'Compass',
    'Jeep',
    'Cinza',
    'automatico',
    TRUE,
    'manutencao',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'SUV'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Movida')
  ),
  (
    'PQR2345',
    '9BRBC3HE0N678901',
    'Corolla',
    'Toyota',
    'Azul',
    'automatico',
    TRUE,
    'disponivel',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Executivo'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Unidas')
  ),
  (
    'STU6789',
    '93YKWIDR0NJ789012',
    'Kwid',
    'Renault',
    'Laranja',
    'manual',
    TRUE,
    'disponivel',
    FALSE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Localiza')
  ),
  (
    'VWX0123',
    '9BDMOBIL0P890123',
    'Mobi',
    'Fiat',
    'Branco',
    'manual',
    FALSE,
    'manutencao',
    TRUE,
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM empresa_locadora WHERE nome = 'Movida')
  );

-- ACESSORIO
INSERT INTO acessorio (nome) VALUES
  ('GPS'),
  ('Bluetooth'),
  ('Airbag'),
  ('Sensor de re'),
  ('Central multimidia'),
  ('Camera de re');

-- VEICULO_ACESSORIO
INSERT INTO veiculo_acessorio (veiculo_id, acessorio_id) VALUES
  ((SELECT id FROM veiculo WHERE placa = 'ABC1234'), (SELECT id FROM acessorio WHERE nome = 'GPS')),
  ((SELECT id FROM veiculo WHERE placa = 'ABC1234'), (SELECT id FROM acessorio WHERE nome = 'Bluetooth')),
  ((SELECT id FROM veiculo WHERE placa = 'ABC1234'), (SELECT id FROM acessorio WHERE nome = 'Airbag')),
  ((SELECT id FROM veiculo WHERE placa = 'DEF5678'), (SELECT id FROM acessorio WHERE nome = 'Bluetooth')),
  ((SELECT id FROM veiculo WHERE placa = 'DEF5678'), (SELECT id FROM acessorio WHERE nome = 'Airbag')),
  ((SELECT id FROM veiculo WHERE placa = 'GHI9012'), (SELECT id FROM acessorio WHERE nome = 'GPS')),
  ((SELECT id FROM veiculo WHERE placa = 'GHI9012'), (SELECT id FROM acessorio WHERE nome = 'Sensor de re')),
  ((SELECT id FROM veiculo WHERE placa = 'JKL3456'), (SELECT id FROM acessorio WHERE nome = 'Bluetooth')),
  ((SELECT id FROM veiculo WHERE placa = 'MNO7890'), (SELECT id FROM acessorio WHERE nome = 'GPS')),
  ((SELECT id FROM veiculo WHERE placa = 'MNO7890'), (SELECT id FROM acessorio WHERE nome = 'Central multimidia')),
  ((SELECT id FROM veiculo WHERE placa = 'PQR2345'), (SELECT id FROM acessorio WHERE nome = 'Sensor de re')),
  ((SELECT id FROM veiculo WHERE placa = 'PQR2345'), (SELECT id FROM acessorio WHERE nome = 'Central multimidia')),
  ((SELECT id FROM veiculo WHERE placa = 'PQR2345'), (SELECT id FROM acessorio WHERE nome = 'Camera de re')),
  ((SELECT id FROM veiculo WHERE placa = 'STU6789'), (SELECT id FROM acessorio WHERE nome = 'Airbag')),
  ((SELECT id FROM veiculo WHERE placa = 'VWX0123'), (SELECT id FROM acessorio WHERE nome = 'Bluetooth'));

-- VAGA
INSERT INTO vaga (codigo, patio_id, status) VALUES
  ('A1', (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'), 'ocupada'),
  ('A2', (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'), 'livre'),
  ('A3', (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'), 'livre'),
  ('B1', (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'), 'ocupada'),
  ('B2', (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'), 'livre'),
  ('ZS1', (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'), 'ocupada'),
  ('ZS2', (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'), 'livre'),
  ('C1', (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'), 'ocupada'),
  ('C2', (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'), 'livre'),
  ('D1', (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Belo Horizonte'), 'ocupada'),
  ('D2', (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Belo Horizonte'), 'livre');

-- RESERVA
INSERT INTO reserva (
  cliente_id,
  grupo_id,
  patio_retirada_id,
  patio_devolucao_id,
  data_inicio,
  data_fim,
  status
) VALUES
  (
    (SELECT id FROM cliente WHERE nome = 'Ana Paula Ribeiro'),
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'),
    '2026-04-10',
    '2026-04-15',
    'confirmada'
  ),
  (
    (SELECT id FROM cliente WHERE nome = 'Bruno Henrique Souza'),
    (SELECT id FROM grupo_veiculo WHERE nome = 'Economico'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'),
    '2026-04-12',
    '2026-04-18',
    'confirmada'
  ),
  (
    (SELECT id FROM cliente WHERE nome = 'Carla Fernanda Almeida'),
    (SELECT id FROM grupo_veiculo WHERE nome = 'SUV'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Belo Horizonte'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    '2026-05-02',
    '2026-05-08',
    'espera'
  ),
  (
    (SELECT id FROM cliente WHERE nome = 'Diego Martins Oliveira'),
    (SELECT id FROM grupo_veiculo WHERE nome = 'Executivo'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'),
    '2026-05-10',
    '2026-05-12',
    'cancelada'
  ),
  (
    (SELECT id FROM cliente WHERE nome = 'Fernanda Costa Lima'),
    (SELECT id FROM grupo_veiculo WHERE nome = 'Intermediario'),
    (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    '2026-05-15',
    '2026-05-20',
    'ativa'
  );

-- LOCACAO
INSERT INTO locacao (
  reserva_id,
  veiculo_id,
  condutor_id,
  patio_retirada_id,
  patio_devolucao_id,
  data_retirada_prevista,
  data_retirada_realizada,
  data_devolucao_prevista,
  data_devolucao_realizada,
  estado_entrega,
  estado_devolucao,
  km_entrega,
  km_devolucao
) VALUES
  (
    (
      SELECT r.id
      FROM reserva r
      JOIN cliente c ON c.id = r.cliente_id
      WHERE c.nome = 'Ana Paula Ribeiro'
        AND r.data_inicio = '2026-04-10'
    ),
    (SELECT id FROM veiculo WHERE placa = 'ABC1234'),
    (SELECT id FROM condutor WHERE cnh = '05246891320'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'),
    '2026-04-10 09:00:00',
    '2026-04-10 09:20:00',
    '2026-04-15 18:00:00',
    '2026-04-15 16:45:00',
    'Sem avarias; Tanque cheio',
    'Arranhao leve; Tanque cheio',
    15000,
    15240
  ),
  (
    (
      SELECT r.id
      FROM reserva r
      JOIN cliente c ON c.id = r.cliente_id
      WHERE c.nome = 'Bruno Henrique Souza'
        AND r.data_inicio = '2026-04-12'
    ),
    (SELECT id FROM veiculo WHERE placa = 'JKL3456'),
    (SELECT id FROM condutor WHERE cnh = '06135792481'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Sao Paulo'),
    '2026-04-12 13:30:00',
    '2026-04-12 14:00:00',
    '2026-04-18 18:00:00',
    NULL,
    'Sem avarias; Tanque cheio',
    NULL,
    48210,
    NULL
  ),
  (
    NULL,
    (SELECT id FROM veiculo WHERE placa = 'PQR2345'),
    (SELECT id FROM condutor WHERE cnh = '08426013579'),
    (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    '2026-04-20 08:00:00',
    '2026-04-20 08:10:00',
    '2026-04-22 18:00:00',
    '2026-04-22 17:30:00',
    'Sem avarias; Tanque cheio',
    'Sem avarias; Tanque cheio',
    23150,
    23480
  );

-- COBRANCA
INSERT INTO cobranca (locacao_id, valor, status, data_pagamento) VALUES
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'ABC1234'
    ),
    875.50,
    'pago',
    '2026-04-15'
  ),
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'JKL3456'
    ),
    642.00,
    'pendente',
    NULL
  ),
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'PQR2345'
    ),
    520.00,
    'pago',
    '2026-04-22'
  );

-- SEGURO
INSERT INTO seguro (tipo, valor) VALUES
  ('Basico', 29.90),
  ('Completo', 59.90),
  ('Vidros', 19.90),
  ('Protecao contra terceiros', 39.90);

-- LOCACAO_SEGURO
INSERT INTO locacao_seguro (locacao_id, seguro_id) VALUES
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'ABC1234'
    ),
    (SELECT id FROM seguro WHERE tipo = 'Completo')
  ),
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'ABC1234'
    ),
    (SELECT id FROM seguro WHERE tipo = 'Vidros')
  ),
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'JKL3456'
    ),
    (SELECT id FROM seguro WHERE tipo = 'Basico')
  ),
  (
    (
      SELECT l.id
      FROM locacao l
      JOIN veiculo v ON v.id = l.veiculo_id
      WHERE v.placa = 'PQR2345'
    ),
    (SELECT id FROM seguro WHERE tipo = 'Protecao contra terceiros')
  );

-- FOTO
INSERT INTO foto (veiculo_id, url, tipo) VALUES
  ((SELECT id FROM veiculo WHERE placa = 'ABC1234'), 'http://imagens.locadora.test/veiculos/abc1234/frente.jpg', 'frente'),
  ((SELECT id FROM veiculo WHERE placa = 'DEF5678'), 'http://imagens.locadora.test/veiculos/def5678/frente.jpg', 'frente'),
  ((SELECT id FROM veiculo WHERE placa = 'GHI9012'), 'http://imagens.locadora.test/veiculos/ghi9012/lateral.jpg', 'lateral'),
  ((SELECT id FROM veiculo WHERE placa = 'JKL3456'), 'http://imagens.locadora.test/veiculos/jkl3456/frente.jpg', 'frente'),
  ((SELECT id FROM veiculo WHERE placa = 'MNO7890'), 'http://imagens.locadora.test/veiculos/mno7890/painel.jpg', 'painel'),
  ((SELECT id FROM veiculo WHERE placa = 'PQR2345'), 'http://imagens.locadora.test/veiculos/pqr2345/frente.jpg', 'frente'),
  ((SELECT id FROM veiculo WHERE placa = 'STU6789'), 'http://imagens.locadora.test/veiculos/stu6789/traseira.jpg', 'traseira'),
  ((SELECT id FROM veiculo WHERE placa = 'VWX0123'), 'http://imagens.locadora.test/veiculos/vwx0123/lateral.jpg', 'lateral');

-- MANUTENCAO
INSERT INTO manutencao (veiculo_id, data, descricao) VALUES
  (
    (SELECT id FROM veiculo WHERE placa = 'MNO7890'),
    '2026-04-16',
    'Revisao do sistema de freios e troca de pastilhas.'
  ),
  (
    (SELECT id FROM veiculo WHERE placa = 'VWX0123'),
    '2026-04-17',
    'Diagnostico eletrico e substituicao da bateria.'
  );

-- MOVIMENTACAO_PATIO
INSERT INTO movimentacao_patio (veiculo_id, origem_patio_id, destino_patio_id, data_movimentacao, motivo) VALUES
  (
    (SELECT id FROM veiculo WHERE placa = 'ABC1234'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'),
    '2026-04-15 17:20:00',
    'Devolucao em patio diferente'
  ),
  (
    (SELECT id FROM veiculo WHERE placa = 'PQR2345'),
    (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    '2026-04-22 18:10:00',
    'Reposicionamento de frota'
  ),
  (
    (SELECT id FROM veiculo WHERE placa = 'MNO7890'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Belo Horizonte'),
    (SELECT id FROM patio WHERE nome = 'Centro' AND cidade = 'Rio de Janeiro'),
    '2026-04-16 10:30:00',
    'Envio para manutencao'
  ),
  (
    (SELECT id FROM veiculo WHERE placa = 'DEF5678'),
    (SELECT id FROM patio WHERE nome = 'Aeroporto' AND cidade = 'Rio de Janeiro'),
    (SELECT id FROM patio WHERE nome = 'Zona Sul' AND cidade = 'Rio de Janeiro'),
    '2026-04-19 09:15:00',
    'Ajuste de disponibilidade'
  );
