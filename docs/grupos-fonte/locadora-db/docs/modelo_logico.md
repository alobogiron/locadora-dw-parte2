-- =====================================
Grupo: Tadeu Belfort Neto -119034813 
         Vicente Alves 120044148 
-- Arquivo: modelo lógico 
-- =====================================

# Modelo Lógico - Sistema de Locação de Veículos

O modelo lógico foi derivado do modelo conceitual (MER), definindo as tabelas, atributos, chaves primárias (PK) e chaves estrangeiras (FK), garantindo integridade referencial e consistência dos dados.

Este modelo reflete a versão final do schema, incluindo refinamentos como separação de pátios de retirada e devolução, controle de datas previstas e realizadas na locação e rastreamento de movimentação de veículos.

---

## Tabela: empresa_locadora
- id (PK)
- nome
- cnpj (UNIQUE)

---

## Tabela: cliente
- id (PK)
- nome
- tipo (CHECK: 'PF','PJ')
- cidade

---

## Tabela: condutor
- id (PK)
- cliente_id (FK → cliente.id)
- nome
- cnh (UNIQUE)
- validade
- categoria
- telefone

---

## Tabela: grupo_veiculo
- id (PK)
- nome
- categoria

---

## Tabela: veiculo
- id (PK)
- placa (UNIQUE)
- chassi (UNIQUE)
- modelo
- marca
- cor
- tipo_mecanizacao (CHECK: 'manual','automatico')
- ar_condicionado
- status (CHECK: 'disponivel','alugado','manutencao')
- adaptado_cadeirante (DEFAULT FALSE)
- grupo_id (FK → grupo_veiculo.id)
- empresa_id (FK → empresa_locadora.id)

---

## Tabela: acessorio
- id (PK)
- nome (UNIQUE)

---

## Tabela: veiculo_acessorio
- veiculo_id (PK, FK → veiculo.id)
- acessorio_id (PK, FK → acessorio.id)

---

## Tabela: patio
- id (PK)
- nome
- cidade

---

## Tabela: vaga
- codigo (PK)
- patio_id (PK, FK → patio.id)
- status (CHECK: 'livre','ocupada')

---

## Tabela: reserva
- id (PK)
- cliente_id (FK → cliente.id)
- grupo_id (FK → grupo_veiculo.id)
- patio_retirada_id (FK → patio.id)
- patio_devolucao_id (FK → patio.id)
- data_inicio
- data_fim
- status (CHECK: 'ativa','confirmada','cancelada','espera')

---

## Tabela: locacao
- id (PK)
- reserva_id (FK → reserva.id, UNIQUE)
- veiculo_id (FK → veiculo.id)
- condutor_id (FK → condutor.id)
- patio_retirada_id (FK → patio.id)
- patio_devolucao_id (FK → patio.id)

### Datas (controle previsto vs realizado)
- data_retirada_prevista (NOT NULL)
- data_retirada_realizada
- data_devolucao_prevista (NOT NULL)
- data_devolucao_realizada

### Estado do veículo
- estado_entrega
- estado_devolucao

### Quilometragem
- km_entrega
- km_devolucao

### Auditoria
- created_at
- updated_at

---

## Tabela: cobranca
- id (PK)
- locacao_id (FK → locacao.id, UNIQUE)
- valor (CHECK ≥ 0)
- status (CHECK: 'pendente','pago','cancelado')
- data_pagamento

---

## Tabela: seguro
- id (PK)
- tipo
- valor (CHECK ≥ 0)

---

## Tabela: locacao_seguro
- locacao_id (PK, FK → locacao.id)
- seguro_id (PK, FK → seguro.id)

---

## Tabela: foto
- id (PK)
- veiculo_id (FK → veiculo.id)
- url
- tipo
- created_at

---

## Tabela: manutencao
- id (PK)
- veiculo_id (FK → veiculo.id)
- data
- descricao
- created_at

---

## Tabela: movimentacao_patio
- id (PK)
- veiculo_id (FK → veiculo.id)
- origem_patio_id (FK → patio.id)
- destino_patio_id (FK → patio.id)
- data_movimentacao
- motivo