-- =====================================================================
-- DADOS DE EXEMPLO (SEED)
-- Pré-requisito: rodar 01_schema.sql antes deste script.
-- =====================================================================

-- Moedas base
INSERT INTO currencies (code, name, symbol) VALUES
('BRL', 'Real Brasileiro', 'R$'),
('USD', 'Dólar Americano', '$'),
('EUR', 'Euro', '€');

-- Household e usuários
INSERT INTO households (name, base_currency) VALUES
('Família Silva', 'BRL');

INSERT INTO users (name, email, password_hash) VALUES
('Lucas', 'lucas@email.com', 'senha_fake_por_enquanto'),
('Mateus', 'mateus@email.com', 'senha_fake_por_enquanto');

-- Vínculo dos usuários ao household
INSERT INTO household_members (household_id, user_id, role) VALUES
((SELECT id FROM households WHERE name = 'Família Silva'), (SELECT id FROM users WHERE name = 'Lucas'), 'admin'),
((SELECT id FROM households WHERE name = 'Família Silva'), (SELECT id FROM users WHERE name = 'Mateus'), 'membro');

-- Contas
INSERT INTO accounts (household_id, owner_user_id, name, type, currency_code, initial_balance) VALUES
((SELECT id FROM households WHERE name = 'Família Silva'), (SELECT id FROM users WHERE name = 'Lucas'), 'Conta Corrente Lucas', 'corrente', 'BRL', 1500.00),
((SELECT id FROM households WHERE name = 'Família Silva'), (SELECT id FROM users WHERE name = 'Mateus'), 'Conta Corrente Mateus', 'corrente', 'BRL', 800.00);

-- Categorias
INSERT INTO categories (household_id, name, type) VALUES
((SELECT id FROM households WHERE name = 'Família Silva'), 'Mercado', 'despesa'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Salário', 'receita'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Transporte', 'despesa'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Lazer', 'despesa'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Saúde', 'despesa'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Moradia', 'despesa'),
((SELECT id FROM households WHERE name = 'Família Silva'), 'Freelance', 'receita');

-- Transações
INSERT INTO transactions (account_id, category_id, user_id, type, amount, currency_code, description, transaction_date) VALUES
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Mercado'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 250.00, 'BRL', 'Compras do mês', '2026-07-10'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Transporte'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 45.00, 'BRL', 'Uber', '2026-06-22'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Lazer'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 60.00, 'BRL', 'Cinema', '2026-06-24'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Mercado'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 180.00, 'BRL', 'Supermercado', '2026-06-27'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Salário'), (SELECT id FROM users WHERE name = 'Lucas'), 'receita', 2500.00, 'BRL', 'Salário bolsa CNPq', '2026-07-01'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Moradia'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 700.00, 'BRL', 'Aluguel', '2026-07-02'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Saúde'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 120.00, 'BRL', 'Farmácia', '2026-07-04'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Transporte'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 38.00, 'BRL', 'Combustível', '2026-07-06'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Freelance'), (SELECT id FROM users WHERE name = 'Lucas'), 'receita', 450.00, 'BRL', 'Projeto freelance', '2026-07-08'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Lucas'), (SELECT id FROM categories WHERE name = 'Lazer'), (SELECT id FROM users WHERE name = 'Lucas'), 'despesa', 90.00, 'BRL', 'Jantar fora', '2026-07-11'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Mercado'), (SELECT id FROM users WHERE name = 'Mateus'), 'despesa', 210.00, 'BRL', 'Supermercado', '2026-06-25'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Transporte'), (SELECT id FROM users WHERE name = 'Mateus'), 'despesa', 55.00, 'BRL', 'Ônibus/App', '2026-06-29'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Salário'), (SELECT id FROM users WHERE name = 'Mateus'), 'receita', 1800.00, 'BRL', 'Salário', '2026-07-01'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Saúde'), (SELECT id FROM users WHERE name = 'Mateus'), 'despesa', 80.00, 'BRL', 'Plano odontológico', '2026-07-05'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Lazer'), (SELECT id FROM users WHERE name = 'Mateus'), 'despesa', 130.00, 'BRL', 'Assinatura streaming + saída', '2026-07-09'),
((SELECT id FROM accounts WHERE name = 'Conta Corrente Mateus'), (SELECT id FROM categories WHERE name = 'Mercado'), (SELECT id FROM users WHERE name = 'Mateus'), 'despesa', 195.00, 'BRL', 'Supermercado', '2026-07-12');

-- Orçamento de exemplo
INSERT INTO budgets (household_id, category_id, amount, currency_code, period_start, period_end) VALUES
((SELECT id FROM households WHERE name = 'Família Silva'),
 (SELECT id FROM categories WHERE name = 'Mercado'),
 500.00, 'BRL', '2026-07-01', '2026-07-31');
