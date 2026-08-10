# Modelo de Dados — Procedimentos e Decisões de Modelagem

## 1. Visão geral das entidades

| Entidade | Descrição |
|---|---|
| `users` | Pessoas que usam o sistema |
| `households` | Grupo familiar/domicílio; agrupa usuários e contas |
| `household_members` | Tabela associativa N:N entre `users` e `households`, com papel (admin/membro) |
| `currencies` | Moedas suportadas (ISO 4217) |
| `exchange_rates` | Cotações históricas entre moedas |
| `accounts` | Contas financeiras (corrente, poupança, cartão, dinheiro, investimento) |
| `categories` | Categorias de receita/despesa, com hierarquia opcional |
| `transactions` | Lançamentos financeiros individuais |
| `recurring_transactions` | Modelos de lançamentos recorrentes (ainda não materializados em `transactions`) |
| `budgets` | Orçamento definido por categoria e período |

## 2. Decisões de modelagem

### Multiusuário (household)
Optou-se por um modelo em que várias pessoas (`users`) podem pertencer a um mesmo `household`, através da tabela associativa `household_members`. Isso permite consultas tanto no nível individual (gastos de um usuário) quanto agregadas (gastos da família inteira), sem duplicar estrutura.

### Multi-moeda
Cada `account` e cada `transaction` guardam seu próprio `currency_code`. Isso reflete a realidade de que uma pessoa pode ter, por exemplo, uma conta em BRL e outra em USD. A tabela `exchange_rates` guarda cotações históricas por data, permitindo consolidar relatórios numa moeda-base (`households.base_currency`) quando necessário — essa conversão é feita em tempo de consulta, não armazenada de forma redundante nas transações.

### Transferências entre contas
Uma transferência é modelada como duas linhas em `transactions` (uma de saída, uma de entrada), ligadas pela coluna `linked_transfer_id`. Essa abordagem foi escolhida (em vez de uma tabela separada de transferências) para que a mesma tabela `transactions` sirva de fonte única de verdade para qualquer soma/relatório de saldo, sem necessidade de UNIONs adicionais.

### Categorias hierárquicas
`categories.parent_category_id` permite subcategorias (ex: "Alimentação" → "Mercado", "Restaurante"), mas o uso de subcategorias é opcional — uma categoria sem pai é uma categoria de nível raiz.

### Uso de ENUM
Campos como `account_type`, `category_type`, `transaction_type` e `recurrence_frequency` usam tipos `ENUM` do PostgreSQL em vez de texto livre, para garantir consistência dos dados e evitar erros de digitação (ex: "despesa" vs "Despesa" vs "expense").

### Chaves primárias: UUID vs. BIGSERIAL
- `users`, `households`, `accounts`, `categories` usam `UUID` — adequado para entidades que podem, no futuro, ser sincronizadas entre sistemas distribuídos ou expostas publicamente sem revelar volume de registros.
- `transactions`, `recurring_transactions`, `budgets`, `exchange_rates` usam `BIGSERIAL` (auto-incremento) — entidades de alto volume, onde performance de índice sequencial é mais relevante que opacidade do identificador.

## 3. Views de análise

As views (`vw_saldo_contas`, `vw_gastos_por_categoria_mes`, `vw_acompanhamento_orcamento`) foram criadas para encapsular lógica de agregação recorrente (somas de receita/despesa, agrupamento por mês, comparação orçado vs. realizado), evitando reescrever esses `JOIN`s e `GROUP BY`s em cada consulta manual.

## 4. Procedimento de validação

Para validar o modelo, o banco foi populado com dados de exemplo (`sql/02_seed_data.sql`) cobrindo:
- 2 usuários em um mesmo household
- 2 contas em moeda BRL
- 7 categorias (receita e despesa)
- 16 transações distribuídas em ~3 semanas
- 1 orçamento mensal

A partir desses dados, as views foram consultadas e os resultados conferidos manualmente (ex: saldo inicial − despesas + receitas = saldo apresentado pela view), confirmando a integridade dos cálculos.
