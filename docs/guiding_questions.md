# Board — Guiding Questions

Perguntas norteadoras usadas para orientar a análise dos dados financeiros. Cada pergunta pode ser respondida com uma query específica sobre o schema.

## Visão geral
- [ ] Qual é o saldo atual de cada conta? (`vw_saldo_contas`)
- [ ] Qual a proporção entre receitas e despesas no período?

## Padrões de gasto
- [ ] Qual categoria concentra o maior volume de despesas? (`vw_gastos_por_categoria_mes`)
- [ ] Os gastos estão aumentando, diminuindo ou estáveis mês a mês?
- [ ] Existe algum gasto atípico (fora do padrão) no período analisado?

## Orçamento
- [ ] Alguma categoria já ultrapassou o valor orçado? (`vw_acompanhamento_orcamento`)
- [ ] Quanto ainda resta de orçamento disponível por categoria até o fim do período?

## Household / multiusuário
- [ ] Como se compara o padrão de gastos entre os membros do household?
- [ ] Existem contas compartilhadas com movimentação significativa de mais de um usuário?

## Multi-moeda
- [ ] Existem transações em moedas diferentes da moeda-base do household?
- [ ] O câmbio aplicado nas conversões está atualizado (`exchange_rates`)?

## Recorrência
- [ ] Quais são as despesas recorrentes fixas (aluguel, assinaturas) e qual seu peso no total mensal?
