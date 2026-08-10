# Sistema de Organização Financeira Pessoal (PostgreSQL)

Modelagem e implementação de um banco de dados relacional para registrar, organizar, analisar e consultar gastos pessoais/familiares ao longo do tempo. Projeto desenvolvido para o curso de banco de dados da residência Full Stack 5.0 (Eldorado Research Institute & Petrobras).

## Contexto

O desafio pedia uma solução capaz de registrar, organizar, analisar e consultar dados de gastos pessoais de forma eficiente ao longo do tempo, com suporte a múltiplos usuários de um mesmo grupo familiar (*household*) e múltiplas moedas.

## Stack

- **SGBD:** PostgreSQL
- **Ferramenta:** pgAdmin / psql
- **Modelagem:** SQL puro (DDL), sem ORM

## Estrutura do repositório

```
financas-household-postgres/
├── sql/
│   ├── 01_schema.sql       # DDL: tipos, tabelas, índices e views
│   └── 02_seed_data.sql    # Dados de exemplo para testes
├── docs/
│   ├── modelo_dados.md     # Descrição das entidades e relacionamentos
│   ├── insights.md         # Documento de insights extraídos dos dados
│   └── guiding_questions.md # Board de perguntas norteadoras
└── README.md
```

## Modelo de dados (visão geral)

- **households / users / household_members** — suportam múltiplos usuários por grupo familiar, com papéis (admin/membro).
- **currencies / exchange_rates** — base para suporte multi-moeda; cada conta e cada transação guardam sua própria moeda.
- **accounts** — contas financeiras (corrente, poupança, cartão de crédito, dinheiro, investimento), podendo ser individuais ou compartilhadas.
- **categories** — categorias de receita/despesa, com suporte a subcategorias (hierarquia via `parent_category_id`).
- **transactions** — lançamentos de receita, despesa ou transferência entre contas.
- **recurring_transactions** — modelo para lançamentos recorrentes (assinaturas, salário, aluguel).
- **budgets** — orçamentos por categoria e período.

O detalhamento de cada entidade e as decisões de modelagem estão em [`docs/modelo_dados.md`](docs/modelo_dados.md).

## Views de análise

O schema já inclui views prontas para consulta e geração de insights:

| View | Finalidade |
|---|---|
| `vw_saldo_contas` | Saldo atual de cada conta |
| `vw_gastos_por_categoria_mes` | Evolução de gastos por categoria e mês |
| `vw_acompanhamento_orcamento` | Comparativo orçado vs. gasto por categoria/período |

## Como rodar

1. Crie um banco de dados no PostgreSQL (ex: `financas_household`).
2. Execute o schema:
   ```bash
   psql -d financas_household -f sql/01_schema.sql
   ```
3. (Opcional) Popule com dados de exemplo:
   ```bash
   psql -d financas_household -f sql/02_seed_data.sql
   ```
4. Explore as views, por exemplo:
   ```sql
   SELECT * FROM vw_gastos_por_categoria_mes;
   ```

## Entregáveis do desafio

- [x] Documento com insights dos dados → [`docs/insights.md`](docs/insights.md)
- [x] Procedimentos utilizados para chegar às respostas → [`docs/modelo_dados.md`](docs/modelo_dados.md)
- [x] Board com guiding questions → [`docs/guiding_questions.md`](docs/guiding_questions.md)

## Autor

Lucas — Residência Full Stack 5.0 (Eldorado Research Institute & Petrobras)
