# 🚗 Projeto de Banco de Dados Transacional (OLTP) - Locadora de Veículos

## 📌 Sobre o Projeto
Este repositório contém o projeto de Banco de Dados para um grupo associado de 6 empresas de locação de automóveis. O objetivo desta etapa foi projetar e implementar a base de dados transacional (**OLTP**) robusta, normalizada e capaz de suportar as operações de negócio centrais: cadastro de clientes, controle de frotas, reservas, locações, pátios compartilhados e cobrança.

O sistema foi desenhado seguindo os padrões ANSI SQL para garantir integridade e performance, servindo como base sólida para a futura integração de dados em um Data Warehouse (Parte 2).

---

## 🛠️ Tecnologias Utilizadas
* **SGBD:** MySQL
* **Padrão SQL:** ANSI SQL (a partir do SQL99)
* **Modelagem:** draw.io

---

## 📐 Arquitetura da Base de Dados

O projeto está dividido em três níveis de abstração, cujos arquivos encontram-se na pasta `/modelos`:

1. **Modelo Conceitual:** Representação abstrata de alto nível das entidades e seus relacionamentos (MER).
2. **Modelo Lógico:** Mapeamento das entidades em tabelas estruturadas, definição de chaves primárias (PK), chaves estrangeiras (FK) e restrições de integridade.
3. **Modelo Físico:** Script DDL de criação das tabelas, tipos de dados específicos e constraints.

### Diferenciais do Nosso Modelo (Destaques de Modelagem):
* **Especialização de Clientes (Herança):** Separação eficiente de Clientes de Pessoa Física (PF) e Pessoa Jurídica (PJ) através de tabelas especializadas compartilhando a mesma herança de chave primária.
* **Flexibilidade de Motoristas:** Vinculação de motoristas independentes e associados a contas corporativas (PJ), atendendo estritamente às regras de negócio.
* **Pronto para o Compartilhamento de Pátios:** Modelagem flexível da tabela `VEICULO` e `PATIO` que já prevê a identificação da empresa "dona" da frota, permitindo que carros de outras 5 marcas parceiras operem no mesmo pátio físico.

---

## 📂 Estrutura do Repositório

```text
├── parte1_oltp/                  # Módulo Transacional (Operacional)
│   ├── modelos/
│   │   ├── locadora_trabalho_bg_dw.mwb.zip   # Arquivo de modelagem do MySQL Workbench
│   │   ├── modelo Conceitual.drawio.pdf  # Diagrama Conceitual (MER)
│   │   └── Modelo Lógico SDB OLTP.pdf     # Diagrama Lógico Relacional
│   └── scripts_sql/
│       └── script-modelagem.sql          # Script DDL de criação da base OLTP
│
├── parte2_olap/                  # Módulo Analítico (Data Warehouse)
│   └── scripts_sql/
│       ├── 01_script-staging.sql         # Criação das tabelas da Staging Area
│       ├── 02_script-extract.sql         # Extração e ingestão de dados na Staging
│       └── 03_script-dw.sql              # Criação das Dimensões/Fato e carga do DW
│
├── Dicionario de Dados.pdf       # Documentação detalhada de atributos e tabelas
├── Projeto Modelagem SBD OLTP.pdf # Relatório descritivo do projeto operacional
└── README.md                     # Documentação principal do repositório
