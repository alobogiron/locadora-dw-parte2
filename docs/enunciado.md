<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Avaliação 02: Modelagem de Data Warehouse — PARTE II

Construir um modelo dimensional de um Data Warehouse para um grupo de empresas de locação de veículos.

## Contexto

A seguir é fornecido, de forma sucinta, o contexto da situação:

Seis empresas independentes de aluguel de automóveis resolveram se associar para compartilhar pátios. Uma delas tem o pátio no Aeroporto do Galeão, a outra no Santos Dumont, a terceira tem pátio na Rodoviária e as demais possuem pátios, respectivamente, no Shopping Rio Sul, Nova América e Barra Shopping. Cada pátio se parece com um grande estacionamento. Cada um possui um certo número de vagas, identificadas por um código alfanumérico, e serviços como os de retirada e entrega de veículos.

Cada uma das empresas possui os seus próprios sistemas operativos (transacionais) para auxiliar nas operações do negócio, incluindo um sistema de controle do cadastro de clientes, controle da frota de veículo, sistema de reserva e locação (na loja física, ou por APP/site), sistema de controle de pátio e outros sistemas auxiliares para o RH, compras, fornecedores etc.

As empresas continuarão a utilizar os seus sistemas operativos já existentes, uma vez que funcionam bem. A alteração que sofrerão é apenas para permitir que os veículos alugados possam ser retirados e entregues em qualquer dos seis pátios. Esta alteração é simples pois será baseada na extensão da identificação das "vagas" no pátio para incluir os outros cinco pátios, sendo que o sistema de Reserva e Locação passará a ter a escolha do pátio de retirada e de entrega do veículo.

Todos os sistemas estão baseados em SGBD Relacionais.

As empresas decidiram constituir uma solução de DW para gerenciar os dados históricos de forma integrada, permitindo tanto gerar os Relatórios Gerenciais globais, como para realizar análises de dados de modo unificado.

O grupo fará o papel de uma empresa de consultoria de TIC que tanto é responsável pelos sistemas operativos de uma das empresas, como também foi a consultoria escolhida para construir: (i) a solução de DW integrado, (ii) os Relatórios Gerenciais Globais e (iii) Dashboards dos dados unificados para apoiar análises e tomada de decisões.

Para que esta tarefa não fique exaustiva, iremo-nos restringir à integração apenas dos dados do sistema de negócio central das empresas, deixando de fora a modelagem dos sistemas auxiliares de RH, Compras, Fornecedores etc., ou seja, serão integrados no DW os dados dos sistemas de controle do cadastro de clientes, controle da frota de veículo, controle de reserva e locação de veículo e controle de pátio.

Os conceitos do universo de discurso envolvidos são apenas cinco: cliente, veículos (frota), pátio, reservas e locações (ou aluguel).

## Relatórios gerenciais

a. **Controle de pátio**: quantitativo de veículos no pátio por "grupo" e "origem". Pode haver agrupamento por marca do veículo, modelos e tipo de mecanização. Por "origem" entenda-se da frota da empresa dona do pátio, ou da frota das outras cinco empresas associadas.

b. **Controle das locações**: quantitativo de veículos alugados por "grupo", e dimensão de tempo de locação e tempo restante para devolução (quando ficarão disponíveis para nova locação).

c. **Controle de reservas**: quantas reservas por "grupo" de veículo (quais veículos os clientes desejam alugar) e "pátio" (onde os clientes desejam retirar os veículos), por tempo de retirada futura (reservas para a semana que vem, para o mês que vem etc.), e/ou tempo de duração das locações, e pelas cidades de origem dos clientes.

d. **Grupos de veículos mais alugados** — cruzando, eventualmente, com a origem dos clientes.

## Análise de previsão de ocupação por cadeia de Markov

A única análise a ser modelada será a previsão de ocupação de pátio, a ser feita por cadeia de Markov. Para realizar esta modelagem devemos ter matriz estocástica com os percentuais de movimentação da frota entre os pátios, ou seja, para cada pátio, levantar o percentual de veículo que retorna ao mesmo pátio de onde foi retirado e o percentual que é entregue em cada um dos outros pátios.

## Tarefas — Parte 2

1. Construir o script de Extração ETL, para uma área staging, das informações das tabelas fontes de dados, tanto a partir do esquema que o grupo projetou, como dos esquemas projetados por outros grupos da turma.
2. Projetar o modelo dimensional, em esquema estrela, do DW.
3. Construir o script SQL de criação desse esquema estrela.
4. Construir o script SQL de Transformação ETL que realiza o tratamento de dados necessários para a integração das fontes de dados escolhidas.
5. Construir o script SQL de Carga ETL das tabelas de fatos e dimensões do DW a partir das tabelas transformadas na área de staging.
6. Construir o script SQL de geração dos relatórios e da matriz de percentuais de movimentação entre pátios.

## Resultados a serem entregues (PARTE II)

- Um pequeno arquivo de texto, em formato PDF, contendo comentários sobre o desenvolvimento do processo ETL e do modelo dimensional do DW. Deve conter as escolhas feitas, problemas e observações gerais encontrados durante o desenvolvimento do trabalho. O texto deve fechar com uma conclusão a respeito dos resultados obtidos, em vistas dos objetivos que nortearam a necessidade por uma solução por Data Warehouse.
- Cópia dos documentos contendo os esquemas das BD dos outros três grupos para justificar as escolhas feitas no projeto do ETL.
- Um texto, em formato PDF, com a descrição do modelo dimensional estrela do DW, apontando a ligação entre as fontes de dados e as tabelas de fatos e dimensões, bem como justificando cada um dos campos dessas tabelas.
- Um link para um repositório GitHub contendo os scripts SQL para: Extração, Transformação, Carga, e Geração dos Relatórios + Matriz de Markov.

Todos os arquivos PDF e scripts SQL devem conter um cabeçalho com a identificação clara do grupo (nomes e DRE). Arquivos sem essa identificação não serão considerados.
