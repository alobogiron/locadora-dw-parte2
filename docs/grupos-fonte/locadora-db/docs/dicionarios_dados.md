-- =====================================
Grupo: Tadeu Belfort Neto -119034813 

         Vicente Alves 120044148 
         
-- Dicionario de Dados
-- =====================================

# Dicionário de Dados - Sistema de Locação de Veículos

Este documento descreve as tabelas, atributos, restrições e relacionamentos do banco de dados.

---

## Tabela: empresa_locadora

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da empresa | PK |
| nome | VARCHAR(100) | Nome da empresa | NOT NULL |
| cnpj | VARCHAR(20) | CNPJ da empresa | UNIQUE, NOT NULL |

---

## Tabela: cliente

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do cliente | PK |
| nome | VARCHAR(100) | Nome do cliente | NOT NULL |
| tipo | VARCHAR(2) | Tipo de cliente (PF/PJ) | CHECK ('PF','PJ'), NOT NULL |
| cidade | VARCHAR(50) | Cidade do cliente | NOT NULL |

---

## Tabela: condutor

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do condutor | PK |
| cliente_id | INT | Cliente associado | FK, NOT NULL |
| nome | VARCHAR(100) | Nome do condutor | NOT NULL |
| cnh | VARCHAR(20) | Número da CNH | UNIQUE, NOT NULL |
| validade | DATE | Data de validade da CNH | NOT NULL |
| categoria | VARCHAR(5) | Categoria da CNH | NOT NULL |
| telefone | VARCHAR(20) | Telefone do condutor | |

---

## Tabela: grupo_veiculo

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do grupo | PK |
| nome | VARCHAR(50) | Nome do grupo | NOT NULL |
| categoria | VARCHAR(50) | Categoria do grupo | NOT NULL |

---

## Tabela: veiculo

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do veículo | PK |
| placa | VARCHAR(10) | Placa do veículo | UNIQUE, NOT NULL |
| chassi | VARCHAR(30) | Número do chassi | UNIQUE, NOT NULL |
| modelo | VARCHAR(50) | Modelo do veículo | NOT NULL |
| marca | VARCHAR(50) | Marca do veículo | NOT NULL |
| cor | VARCHAR(30) | Cor do veículo | NOT NULL |
| tipo_mecanizacao | VARCHAR(20) | Tipo (manual/automático) | CHECK ('manual','automatico'), NOT NULL |
| ar_condicionado | BOOLEAN | Possui ar condicionado | NOT NULL |
| status | VARCHAR(20) | Status do veículo | CHECK ('disponivel','alugado','manutencao') |
| adaptado_cadeirante | BOOLEAN | Veículo adaptado | DEFAULT FALSE |
| grupo_id | INT | Grupo do veículo | FK, NOT NULL |
| empresa_id | INT | Empresa proprietária | FK, NOT NULL |

---

## Tabela: acessorio

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do acessório | PK |
| nome | VARCHAR(50) | Nome do acessório | UNIQUE, NOT NULL |

---

## Tabela: veiculo_acessorio

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| veiculo_id | INT | Veículo | PK, FK |
| acessorio_id | INT | Acessório | PK, FK |

---

## Tabela: patio

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do pátio | PK |
| nome | VARCHAR(50) | Nome do pátio | NOT NULL |
| cidade | VARCHAR(50) | Cidade do pátio | NOT NULL |

---

## Tabela: vaga

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| codigo | VARCHAR(10) | Código da vaga | PK |
| patio_id | INT | Pátio da vaga | PK, FK |
| status | VARCHAR(20) | Status da vaga | CHECK ('livre','ocupada') |

---

## Tabela: reserva

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da reserva | PK |
| cliente_id | INT | Cliente | FK, NOT NULL |
| grupo_id | INT | Grupo de veículo | FK, NOT NULL |
| patio_retirada_id | INT | Pátio de retirada | FK, NOT NULL |
| patio_devolucao_id | INT | Pátio de devolução | FK, NOT NULL |
| data_inicio | DATE | Data de início | NOT NULL |
| data_fim | DATE | Data de fim | NOT NULL |
| status | VARCHAR(20) | Status da reserva | CHECK ('ativa','confirmada','cancelada','espera') |

---

## Tabela: locacao

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da locação | PK |
| reserva_id | INT | Reserva associada | FK, UNIQUE |
| veiculo_id | INT | Veículo alugado | FK, NOT NULL |
| condutor_id | INT | Condutor | FK, NOT NULL |
| patio_retirada_id | INT | Pátio de retirada | FK, NOT NULL |
| patio_devolucao_id | INT | Pátio de devolução | FK, NOT NULL |
| data_retirada_prevista | TIMESTAMP | Data prevista de retirada | NOT NULL |
| data_retirada_realizada | TIMESTAMP | Data real de retirada | |
| data_devolucao_prevista | TIMESTAMP | Data prevista de devolução | NOT NULL |
| data_devolucao_realizada | TIMESTAMP | Data real de devolução | |
| estado_entrega | TEXT | Estado do veículo na retirada | |
| estado_devolucao | TEXT | Estado do veículo na devolução | |
| km_entrega | INT | Quilometragem inicial | |
| km_devolucao | INT | Quilometragem final | |
| created_at | TIMESTAMP | Data de criação do registro | DEFAULT now() |
| updated_at | TIMESTAMP | Última atualização | |

---

## Tabela: cobranca

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da cobrança | PK |
| locacao_id | INT | Locação associada | FK, UNIQUE |
| valor | DECIMAL(10,2) | Valor da cobrança | CHECK (valor >= 0) |
| status | VARCHAR(20) | Status | CHECK ('pendente','pago','cancelado') |
| data_pagamento | DATE | Data de pagamento | |

---

## Tabela: seguro

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador do seguro | PK |
| tipo | VARCHAR(50) | Tipo de proteção | NOT NULL |
| valor | DECIMAL(10,2) | Valor do seguro | CHECK (valor >= 0) |

---

## Tabela: locacao_seguro

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| locacao_id | INT | Locação | PK, FK |
| seguro_id | INT | Seguro | PK, FK |

---

## Tabela: foto

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da foto | PK |
| veiculo_id | INT | Veículo associado | FK, NOT NULL |
| url | TEXT | URL da imagem | NOT NULL |
| tipo | VARCHAR(50) | Tipo da foto | |
| created_at | TIMESTAMP | Data de criação | DEFAULT now() |

---

## Tabela: manutencao

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da manutenção | PK |
| veiculo_id | INT | Veículo associado | FK, NOT NULL |
| data | DATE | Data da manutenção | NOT NULL |
| descricao | TEXT | Descrição da manutenção | NOT NULL |
| created_at | TIMESTAMP | Data de registro | DEFAULT now() |

---

## Tabela: movimentacao_patio

| Campo | Tipo | Descrição | Restrição |
|------|------|----------|----------|
| id | SERIAL | Identificador da movimentação | PK |
| veiculo_id | INT | Veículo movimentado | FK, NOT NULL |
| origem_patio_id | INT | Pátio de origem | FK, NOT NULL |
| destino_patio_id | INT | Pátio de destino | FK, NOT NULL |
| data_movimentacao | TIMESTAMP | Data da movimentação | NOT NULL |
| motivo | VARCHAR(100) | Motivo da movimentação | |

---

## Observações Gerais

- O modelo utiliza chaves primárias (PK) e estrangeiras (FK) para garantir integridade referencial.
- Relacionamentos N:N são representados por tabelas associativas (`veiculo_acessorio` e `locacao_seguro`).
- As tabelas incluem restrições de domínio (`CHECK`) para garantir consistência dos dados.
- O sistema permite controle completo do ciclo de locação, incluindo planejamento, execução e retorno do veículo.