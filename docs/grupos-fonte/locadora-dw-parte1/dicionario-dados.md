# Dicionário de Dados — OLTP da Locadora de Veículos

**Trabalho:** Avaliação 01 — Parte I — Modelagem de Data Warehouse
**Grupo:**
- Gustavo Oliveira Pessanha da Silva — DRE 122051824
- André Vinícius Lobo Giron — DRE 122050404

Convenções: PK = chave primária; FK = chave estrangeira; U = UNIQUE; N = nullable.

---

## `patio` — pátios da locadora ou parceiros

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_patio | SERIAL | PK | Identificador do pátio |
| nome | VARCHAR(100) | NOT NULL | Nome do pátio (ex.: "Galeão") |
| endereco | VARCHAR(200) | NOT NULL | Endereço completo |
| capacidade_vagas | INTEGER | NOT NULL, ≥0 | Capacidade total |

## `vaga` — vaga física dentro de um pátio (entidade fraca)

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| patio_id | INTEGER | PK, FK→patio | Pátio dono da vaga |
| codigo | VARCHAR(20) | PK | Código alfanumérico |
| setor | VARCHAR(30) | N | Setor (A, B, ...) |
| ocupada | BOOLEAN | NOT NULL, default FALSE | Vaga ocupada agora |

## `grupo` — categoria/grupo de veículos com tarifa associada

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_grupo | SERIAL | PK | Identificador do grupo |
| codigo | VARCHAR(10) | NOT NULL, U | Código curto (ex.: "A", "B") |
| nome | VARCHAR(50) | NOT NULL | Nome (ex.: "Econômico") |
| classe_luxo | VARCHAR(20) | NOT NULL | Classe de luxo |
| valor_diaria | NUMERIC(10,2) | NOT NULL, ≥0 | Tarifa diária atual |
| franquia_km_diaria | INTEGER | NOT NULL, ≥0 | Franquia de km/dia |

## `veiculo` — instância física de um veículo

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_veiculo | SERIAL | PK | Identificador |
| grupo_id | INTEGER | NOT NULL, FK→grupo | Grupo de tarifação |
| patio_origem_id | INTEGER | NOT NULL, FK→patio | Pátio da frota proprietária |
| placa | VARCHAR(8) | NOT NULL, U | Placa |
| chassi | VARCHAR(17) | NOT NULL, U | Chassi |
| renavam | VARCHAR(11) | NOT NULL, U | RENAVAM |
| marca | VARCHAR(30) | NOT NULL | Ex.: Fiat |
| modelo | VARCHAR(50) | NOT NULL | Ex.: Argo S-Design |
| cor | VARCHAR(20) | NOT NULL | Cor da pintura |
| ano_fabricacao | INTEGER | NOT NULL | Ano de fabricação |
| mecanizacao | VARCHAR(10) | CHECK IN ('MANUAL','AUTOMATICA') | Tipo de câmbio |
| tem_ar_condicionado | BOOLEAN | NOT NULL, default TRUE | Tem A/C |
| km_atual | INTEGER | NOT NULL, ≥0 | Hodômetro atual |
| situacao | VARCHAR(15) | CHECK IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO') | Situação atual |

## `cliente` — cliente (superclasse)

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_cliente | SERIAL | PK | Identificador |
| tipo_pessoa | VARCHAR(2) | CHECK IN ('PF','PJ') | Discriminador |
| nome | VARCHAR(150) | NOT NULL | Nome ou razão social |
| email | VARCHAR(150) | NOT NULL, U | E-mail |
| telefone | VARCHAR(20) | N | Telefone principal |
| cidade_origem | VARCHAR(80) | NOT NULL | Cidade de origem |
| data_cadastro | DATE | NOT NULL, default hoje | Data do cadastro |

## `cliente_pf` — cliente pessoa física

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| cliente_id | INTEGER | PK, FK→cliente | Identificador |
| cpf | VARCHAR(11) | NOT NULL, U | CPF |
| rg | VARCHAR(15) | N | RG |
| data_nascimento | DATE | NOT NULL | Nascimento |
| cnh_numero | VARCHAR(15) | NOT NULL, U | Número CNH |
| cnh_categoria | VARCHAR(2) | CHECK IN ('A','B','AB','C','AC','D','AD','E','AE') | Categoria CNH |
| cnh_validade | DATE | NOT NULL | Validade CNH |

## `cliente_pj` — cliente pessoa jurídica

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| cliente_id | INTEGER | PK, FK→cliente | Identificador |
| cnpj | VARCHAR(14) | NOT NULL, U | CNPJ |
| nome_fantasia | VARCHAR(150) | N | Nome fantasia |
| responsavel | VARCHAR(150) | NOT NULL | Responsável pelo contrato |

## `condutor` — funcionário autorizado a dirigir (entidade fraca de cliente_pj)

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| cliente_pj_id | INTEGER | PK, FK→cliente_pj | PJ que autoriza |
| cpf | VARCHAR(11) | PK | CPF do condutor |
| nome | VARCHAR(150) | NOT NULL | Nome |
| cnh_numero | VARCHAR(15) | NOT NULL, U | CNH |
| cnh_categoria | VARCHAR(2) | CHECK IN (...) | Categoria CNH |
| cnh_validade | DATE | NOT NULL | Validade CNH |

## `reserva` — reserva de veículo

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_reserva | SERIAL | PK | Identificador |
| cliente_id | INTEGER | NOT NULL, FK→cliente | Cliente |
| grupo_id | INTEGER | NOT NULL, FK→grupo | Grupo solicitado |
| patio_retirada_id | INTEGER | NOT NULL, FK→patio | Pátio de retirada |
| patio_devolucao_id | INTEGER | NOT NULL, FK→patio | Pátio de devolução |
| data_reserva | TIMESTAMP | NOT NULL, default agora | Quando foi reservado |
| data_retirada_prevista | TIMESTAMP | NOT NULL | Data prevista da retirada |
| data_devolucao_prevista | TIMESTAMP | NOT NULL, > retirada | Data prevista da devolução |
| estado | VARCHAR(20) | CHECK IN ('CONFIRMADA','EM_FILA_ESPERA','CANCELADA','CONCRETIZADA') | Estado atual |

## `locacao` — contrato de locação efetivado

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_locacao | SERIAL | PK | Identificador |
| numero_contrato | VARCHAR(30) | NOT NULL, U | Número do contrato |
| reserva_id | INTEGER | U, N, FK→reserva | Reserva de origem (se houver) |
| cliente_id | INTEGER | NOT NULL, FK→cliente | Cliente |
| veiculo_id | INTEGER | NOT NULL, FK→veiculo | Veículo |
| patio_retirada_id | INTEGER | NOT NULL, FK→patio | Pátio da retirada |
| patio_devolucao_id | INTEGER | NOT NULL, FK→patio | Pátio da devolução |
| data_retirada_real | TIMESTAMP | NOT NULL | Data/hora da retirada |
| data_devolucao_real | TIMESTAMP | N, > retirada | Data/hora da devolução |
| km_saida | INTEGER | NOT NULL, ≥0 | Km na saída |
| km_chegada | INTEGER | N, ≥ km_saida | Km na chegada |
| valor_diaria_aplicada | NUMERIC(10,2) | NOT NULL, ≥0 | Tarifa congelada do contrato |
| status | VARCHAR(15) | CHECK IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA') | Status |

## `cobranca` — cobrança da locação

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| id_cobranca | SERIAL | PK | Identificador |
| locacao_id | INTEGER | NOT NULL, FK→locacao | Locação cobrada |
| data_emissao | DATE | NOT NULL, default hoje | Data da emissão |
| valor_total | NUMERIC(10,2) | NOT NULL, ≥0 | Valor total |
| status | VARCHAR(15) | CHECK IN ('PENDENTE','PAGA','CANCELADA') | Status |

---

## Restrições de integridade resumidas

| ID | Regra | Onde |
|---|---|---|
| R01 | `data_devolucao_prevista > data_retirada_prevista` | CHECK em `reserva` e `locacao` |
| R02 | `km_chegada >= km_saida` | CHECK em `locacao` |
| R03 | Veículo só em uma locação `EM_ANDAMENTO` por vez | UNIQUE INDEX parcial em `locacao` |
| R04 | CNH válida na retirada | regra de aplicação |
| R05 | Domínios enumerados | CHECK IN em cada coluna |
| R06 | Unicidades: numero_contrato, placa, chassi, renavam, cpf, cnpj, email, cnh_numero | UNIQUE |
