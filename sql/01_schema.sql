-- =====================================================================
-- SISTEMA DE ORGANIZAÇÃO FINANCEIRA PESSOAL
-- Escopo: multiusuário (household) + suporte multi-moeda
-- SGBD: PostgreSQL (testado para uso via pgAdmin)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. EXTENSÕES E CONFIGURAÇÕES GERAIS
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- para gen_random_uuid()

-- ---------------------------------------------------------------------
-- 1. TIPOS ENUM
-- ---------------------------------------------------------------------
CREATE TYPE household_role AS ENUM ('admin', 'membro');
CREATE TYPE account_type AS ENUM ('corrente', 'poupanca', 'cartao_credito', 'dinheiro', 'investimento');
CREATE TYPE category_type AS ENUM ('receita', 'despesa');
CREATE TYPE transaction_type AS ENUM ('receita', 'despesa', 'transferencia');
CREATE TYPE recurrence_frequency AS ENUM ('diaria', 'semanal', 'mensal', 'anual');

-- ---------------------------------------------------------------------
-- 2. MOEDAS E COTAÇÕES
-- ---------------------------------------------------------------------
CREATE TABLE currencies (
    code        CHAR(3) PRIMARY KEY,          -- ISO 4217: BRL, USD, EUR...
    name        VARCHAR(50) NOT NULL,
    symbol      VARCHAR(5)  NOT NULL
);

CREATE TABLE exchange_rates (
    id              BIGSERIAL PRIMARY KEY,
    base_currency   CHAR(3) NOT NULL REFERENCES currencies(code),
    target_currency CHAR(3) NOT NULL REFERENCES currencies(code),
    rate            NUMERIC(18,8) NOT NULL CHECK (rate > 0),
    rate_date       DATE NOT NULL,
    UNIQUE (base_currency, target_currency, rate_date)
);

-- ---------------------------------------------------------------------
-- 3. USUÁRIOS E HOUSEHOLDS (GRUPOS FAMILIARES)
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(120) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE households (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(120) NOT NULL,
    base_currency   CHAR(3) NOT NULL REFERENCES currencies(code),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE household_members (
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            household_role NOT NULL DEFAULT 'membro',
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (household_id, user_id)
);

-- ---------------------------------------------------------------------
-- 4. CONTAS FINANCEIRAS
-- ---------------------------------------------------------------------
CREATE TABLE accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    owner_user_id   UUID REFERENCES users(id) ON DELETE SET NULL, -- NULL = conta compartilhada
    name            VARCHAR(100) NOT NULL,
    type            account_type NOT NULL,
    currency_code   CHAR(3) NOT NULL REFERENCES currencies(code),
    initial_balance NUMERIC(14,2) NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 5. CATEGORIAS (com suporte a subcategorias)
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id        UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    parent_category_id  UUID REFERENCES categories(id) ON DELETE CASCADE,
    name                VARCHAR(80) NOT NULL,
    type                category_type NOT NULL,
    UNIQUE (household_id, name, type)
);

-- ---------------------------------------------------------------------
-- 6. TRANSAÇÕES
-- ---------------------------------------------------------------------
CREATE TABLE transactions (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
    user_id             UUID NOT NULL REFERENCES users(id), -- quem registrou
    type                transaction_type NOT NULL,
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency_code       CHAR(3) NOT NULL REFERENCES currencies(code),
    description         VARCHAR(255),
    transaction_date    DATE NOT NULL,
    linked_transfer_id  BIGINT REFERENCES transactions(id), -- aponta para a "perna" espelhada de uma transferência
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transactions_account_date ON transactions(account_id, transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category_id);

-- ---------------------------------------------------------------------
-- 7. TRANSAÇÕES RECORRENTES
-- ---------------------------------------------------------------------
CREATE TABLE recurring_transactions (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
    user_id             UUID NOT NULL REFERENCES users(id),
    type                transaction_type NOT NULL,
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency_code       CHAR(3) NOT NULL REFERENCES currencies(code),
    description         VARCHAR(255),
    frequency           recurrence_frequency NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE,
    next_occurrence     DATE NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 8. ORÇAMENTOS (BUDGETS)
-- ---------------------------------------------------------------------
CREATE TABLE budgets (
    id              BIGSERIAL PRIMARY KEY,
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    category_id     UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency_code   CHAR(3) NOT NULL REFERENCES currencies(code),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    CHECK (period_end > period_start)
);

-- =====================================================================
-- 9. VIEWS DE APOIO PARA ANÁLISE (INSIGHTS)
-- =====================================================================

-- Saldo atual de cada conta (na moeda da própria conta)
CREATE VIEW vw_saldo_contas AS
SELECT
    a.id AS account_id,
    a.household_id,
    a.name AS account_name,
    a.currency_code,
    a.initial_balance
      + COALESCE(SUM(CASE WHEN t.type = 'receita' THEN t.amount
                           WHEN t.type = 'despesa' THEN -t.amount
                           WHEN t.type = 'transferencia' THEN -t.amount
                      END), 0) AS saldo_atual
FROM accounts a
LEFT JOIN transactions t ON t.account_id = a.id
GROUP BY a.id, a.household_id, a.name, a.currency_code, a.initial_balance;

-- Gastos por categoria e por mês (household)
CREATE VIEW vw_gastos_por_categoria_mes AS
SELECT
    a.household_id,
    c.name AS category_name,
    date_trunc('month', t.transaction_date)::date AS mes,
    t.currency_code,
    SUM(t.amount) AS total_gasto
FROM transactions t
JOIN accounts a ON a.id = t.account_id
LEFT JOIN categories c ON c.id = t.category_id
WHERE t.type = 'despesa'
GROUP BY a.household_id, c.name, date_trunc('month', t.transaction_date), t.currency_code;

-- Acompanhamento de orçamento: quanto já foi gasto vs orçado por categoria/período
CREATE VIEW vw_acompanhamento_orcamento AS
SELECT
    b.id AS budget_id,
    b.household_id,
    c.name AS category_name,
    b.period_start,
    b.period_end,
    b.amount AS valor_orcado,
    b.currency_code,
    COALESCE(SUM(t.amount), 0) AS valor_gasto,
    b.amount - COALESCE(SUM(t.amount), 0) AS saldo_restante
FROM budgets b
JOIN categories c ON c.id = b.category_id
LEFT JOIN transactions t
    ON t.category_id = b.category_id
   AND t.type = 'despesa'
   AND t.transaction_date BETWEEN b.period_start AND b.period_end
LEFT JOIN accounts acc ON acc.id = t.account_id AND acc.household_id = b.household_id
GROUP BY b.id, b.household_id, c.name, b.period_start, b.period_end, b.amount, b.currency_code;

-- =====================================================================
-- FIM DO SCRIPT
-- =====================================================================
