# Documento de Insights

Análise gerada a partir dos dados de exemplo em `sql/02_seed_data.sql` (2 usuários, 2 contas, 7 categorias, 16 transações, 1 orçamento).

## 1. Saldo por conta

Consulta: `SELECT * FROM vw_saldo_contas;`

| Conta | Saldo inicial | Saldo atual |
|---|---|---|
| Conta Corrente Lucas | R$ 1.500,00 | R$ 2.967,00 |
| Conta Corrente Mateus | R$ 800,00 | R$ 1.930,00 |

Ambas as contas fecham em saldo positivo no período analisado, puxadas principalmente pelas entradas de salário no início de julho.

## 2. Categoria de maior peso nos gastos

Consulta: `SELECT * FROM vw_gastos_por_categoria_mes;` (agregado por categoria, todo o período)

| Categoria | Total gasto |
|---|---|
| Moradia | R$ 700,00 |
| Mercado | R$ 835,00 |
| Lazer | R$ 280,00 |
| Saúde | R$ 200,00 |
| Transporte | R$ 138,00 |

**Mercado** é a categoria de maior peso (R$ 835,00 no total do household), seguida de perto por **Moradia** — apesar de Moradia ser um valor fixo único (aluguel) e Mercado ser resultado de várias compras menores somadas.

## 3. Evolução mês a mês

As transações cobrem o intervalo de 22/jun a 12/jul/2026. Como a maior parte do volume está concentrada em julho (salários, aluguel, compras recorrentes), uma comparação mês a mês completa exigiria pelo menos mais um ciclo mensal de dados — recomendação: rodar `vw_gastos_por_categoria_mes` novamente após acumular 2-3 meses reais de uso para identificar tendência de crescimento/queda por categoria.

## 4. Orçamento vs. realizado

Consulta: `SELECT * FROM vw_acompanhamento_orcamento;`

| Categoria | Período | Orçado | Gasto | Restante |
|---|---|---|---|---|
| Mercado | 01/07 a 31/07/2026 | R$ 500,00 | R$ 445,00 | R$ 55,00 |

A categoria Mercado está em **89% do orçamento consumido** (R$ 445 de R$ 500) já na primeira metade do mês — ponto de atenção para o restante do período.

## 5. Diferença entre membros do household

| Usuário | Total despesas | Total receitas |
|---|---|---|
| Lucas | R$ 1.483,00 | R$ 2.950,00 |
| Mateus | R$ 670,00 | R$ 1.800,00 |

Lucas tem tanto receitas quanto despesas maiores em volume absoluto, mas isso reflete o fato de sua conta concentrar itens de maior valor (aluguel de R$ 700 e salário de R$ 2.500). Uma leitura mais justa seria em % da renda — Mateus gasta ~37% do que recebe, Lucas ~50%.

## 6. Recomendações

- Ativar orçamentos também para as categorias **Moradia** e **Lazer**, já que juntas representam quase R$ 1.000 no período analisado.
- Configurar `recurring_transactions` para o aluguel e eventuais assinaturas, evitando lançamento manual repetido e permitindo prever o fluxo de caixa dos próximos meses.
- Reavaliar o orçamento de Mercado (R$ 500/mês) caso o padrão de 89% de consumo até meados do mês se repita nos próximos ciclos — pode ser sinal de orçamento subestimado.
