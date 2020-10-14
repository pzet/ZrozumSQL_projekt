-- schemat expense_tracker

--DROP SCHEMA IF EXISTS expense_tracker CASCADE;

--CREATE SCHEMA expense_tracker;

-- tabela bank_account_owner

DROP TABLE IF EXISTS expense_tracker.bank_account_owner;

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner (
	id_ba_own INT PRIMARY KEY,
	owner_name VARCHAR(50) NOT NULL,
	owner_desc VARCHAR(250),
	user_login INT NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_type TIMESTAMP DEFAULT current_timestamp
);

-- tabela bank_account_types

DROP TABLE IF EXISTS expense_tracker.bank_account_types

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_types (
	id_ba_type INT PRIMARY KEY,
	ba_type VARCHAR(50) NOT NULL,
	ba_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	is_common_account BOOLEAN NOT NULL DEFAULT FALSE,
	id_ba_own INT,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela transactions

DROP TABLE IF EXISTS expense_tracker.transactions;

CREATE TABLE IF NOT EXISTS expense_tracker.transactions (
	id_trans_ba INT PRIMARY KEY,
	id_trans_cat INT,
	id_trans_subcat INT,
	id_trans_type INT,
	id_user INT,
	transaction_date DATE DEFAULT current_date,
	transaction_value NUMERIC(9, 2),
	transaction_description TEXT,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela transaction_bank_accounts

DROP TABLE IF EXISTS expense_tracker.transaction_bank_accounts;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_bank_accounts (
	id_trans_ba INT PRIMARY KEY,
	id_ba_own INT,
	id_ba_typ INT,
	bank_account_name VARCHAR(50) NOT NULL,
	bank_account_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela transaction_category

DROP TABLE IF EXISTS expense_tracker.transaction_category;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_category (
	id_trans_cat INT PRIMARY KEY,
	category_name VARCHAR(50) NOT NULL,
	category_description VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela transaction_subcategory

DROP TABLE IF EXISTS expense_tracker.transaction_subcategory;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_subcategory (
	id_trans_subcat INT PRIMARY KEY,
	id_trans_cat INT,
	subcategory_name VARCHAR(50) NOT NULL,
	subcategory_description VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela transaction_type

DROP TABLE IF EXISTS expense_tracker.transaction_type;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_type (
	id_trans_type INT PRIMARY KEY,
	transaction_type_name VARCHAR(50) NOT NULL,
	transaction_type_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);

-- tabela users

DROP TABLE IF EXISTS expense_tracker.users;

CREATE TABLE IF NOT EXISTS expense_tracker.users (
	id_user INT PRIMARY KEY,
	user_login VARCHAR(25) NOT NULL,
	user_name VARCHAR(50) NOT NULL,
	user_password VARCHAR(100) NOT NULL,
	password_salt VARCHAR(100) NOT NULL,
	transaction_type_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);
