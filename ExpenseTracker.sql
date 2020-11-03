-- EXPENSE TRACKER

-- rola expense_tracker_user

DROP ROLE IF EXISTS expense_tracker_user;
CREATE ROLE expense_tracker_user WITH LOGIN PASSWORD 'Wujek$knerus';


-- odbierz uprawnienia tworzenia obiektów w schemacie public roli PUBLIC

REVOKE CREATE ON SCHEMA public FROM PUBLIC;


-- usuń schemat expense_tracker jeśli istnieje

DROP SCHEMA IF EXISTS expense_tracker CASCADE;


-- grupa expense_tracker_group

REASSIGN OWNED BY expense_tracker_group TO postgres;
DROP OWNED BY expense_tracker_group;
DROP ROLE IF EXISTS expense_tracker_group;
CREATE ROLE expense_tracker_group;


-- utwórz schemat expense_tracker

CREATE SCHEMA IF NOT EXISTS expense_tracker AUTHORIZATION expense_tracker_group;


-- przywileje grupy expense_tracker_group

GRANT CONNECT ON DATABASE postgres TO expense_tracker_group;

GRANT ALL PRIVILEGES ON SCHEMA expense_tracker TO expense_tracker_group;


-- dodaj rolę expense_tracker_group użytkownikowi expense_tracker_user

GRANT expense_tracker_group TO expense_tracker_user;

-- tabela users

DROP TABLE IF EXISTS expense_tracker.users;

CREATE TABLE IF NOT EXISTS expense_tracker.users (
	id_user SERIAL PRIMARY KEY,
	user_login VARCHAR(25) NOT NULL,
	user_name VARCHAR(50) NOT NULL,
	user_password VARCHAR(100) NOT NULL,
	password_salt VARCHAR(100) NOT NULL,
	transaction_type_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);




-- tabela bank_account_owner

DROP TABLE IF EXISTS expense_tracker.bank_account_owner;

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_owner (
	id_ba_own SERIAL PRIMARY KEY,
	owner_name VARCHAR(50) NOT NULL,
	owner_desc VARCHAR(250),
	user_login INT NOT NULL,
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_type TIMESTAMP DEFAULT current_timestamp
);


-- tabela bank_account_types

DROP TABLE IF EXISTS expense_tracker.bank_account_types;

CREATE TABLE IF NOT EXISTS expense_tracker.bank_account_types (
	id_ba_type SERIAL PRIMARY KEY,
	ba_type VARCHAR(50) NOT NULL,
	ba_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	is_common_account BOOLEAN NOT NULL DEFAULT FALSE,
	id_ba_own INT,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp,
	CONSTRAINT bank_account_owner_fk FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner(id_ba_own)
);


-- tabela transaction_bank_accounts

DROP TABLE IF EXISTS expense_tracker.transaction_bank_accounts;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_bank_accounts (
	id_trans_ba SERIAL PRIMARY KEY,
	id_ba_own INT,
	id_ba_type INT,
	bank_account_name VARCHAR(50) NOT NULL,
	bank_account_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp,
	CONSTRAINT bank_account_owner_fk FOREIGN KEY (id_ba_own) REFERENCES expense_tracker.bank_account_owner(id_ba_own),
	CONSTRAINT bank_account_types_fk FOREIGN KEY (id_ba_type) REFERENCES expense_tracker.bank_account_types(id_ba_type)
);


-- tabela transaction_category

DROP TABLE IF EXISTS expense_tracker.transaction_category;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_category (
	id_trans_cat SERIAL PRIMARY KEY,
	category_name VARCHAR(50) NOT NULL,
	category_description VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);


-- tabela transaction_subcategory

DROP TABLE IF EXISTS expense_tracker.transaction_subcategory;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_subcategory (
	id_trans_subcat SERIAL PRIMARY KEY,
	id_trans_cat INT,
	subcategory_name VARCHAR(50) NOT NULL,
	subcategory_description VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp,
	CONSTRAINT transaction_category_fk FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category(id_trans_cat)
);


-- tabela transaction_type

DROP TABLE IF EXISTS expense_tracker.transaction_type;

CREATE TABLE IF NOT EXISTS expense_tracker.transaction_type (
	id_trans_type SERIAL PRIMARY KEY,
	transaction_type_name VARCHAR(50) NOT NULL,
	transaction_type_desc VARCHAR(250),
	active BOOLEAN NOT NULL DEFAULT TRUE,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp
);


-- tabela transactions

DROP TABLE IF EXISTS expense_tracker.transactions;

CREATE TABLE IF NOT EXISTS expense_tracker.transactions (
	id_trans_ba SERIAL PRIMARY KEY,
	id_trans_cat INT,
	id_trans_subcat INT,
	id_trans_type INT,
	id_user INT,
	transaction_date DATE DEFAULT current_date,
	transaction_value NUMERIC(9, 2),
	transaction_description TEXT,
	insert_date TIMESTAMP DEFAULT current_timestamp,
	update_date TIMESTAMP DEFAULT current_timestamp,
	CONSTRAINT transaction_bank_accounts_fk FOREIGN KEY (id_trans_ba) REFERENCES expense_tracker.transaction_bank_accounts(id_trans_ba),
	CONSTRAINT transaction_category_fk FOREIGN KEY (id_trans_cat) REFERENCES expense_tracker.transaction_category(id_trans_cat),
	CONSTRAINT transaction_subcategory_fk FOREIGN KEY (id_trans_subcat) REFERENCES expense_tracker.transaction_subcategory(id_trans_subcat),
	CONSTRAINT transaction_type_fk FOREIGN KEY (id_trans_type) REFERENCES expense_tracker.transaction_type(id_trans_type),
	CONSTRAINT users_fk FOREIGN KEY (id_user) REFERENCES expense_tracker.users(id_user)
);


-- ######################
-- MODUŁ 5
-- ######################

-- insert do tabeli users

INSERT INTO expense_tracker.users (user_login, user_name, user_password, password_salt, transaction_type_desc, active)
     VALUES ('jnowak', 'Jan Nowak', 'Wujek$knerus', concat(md5(random()::TEXT)), 'transaction description', true);

    
-- insert do tabeli bank_account_owner
     
INSERT INTO expense_tracker.bank_account_owner (owner_name, owner_desc, user_login, active)
	 VALUES ('Piotrek Zawal', 'some description', 999, TRUE);

	
-- insert do tabeli bank_account_types

INSERT INTO expense_tracker.bank_account_types (ba_type, ba_desc, active, is_common_account, id_ba_own)
     VALUES ('checking', 'Konto Osobiste', TRUE, FALSE, 1);
	
    
-- insert do tabeli transaction_bank_accounts

INSERT INTO expense_tracker.transaction_bank_accounts (id_ba_own, id_ba_type, bank_account_name, bank_account_desc, active)
	 VALUES (1, 1, 'Konto Direct', 'Konto Osobiste ING', TRUE);
    
	
-- insert do tabeli transaction_category

INSERT INTO expense_tracker.transaction_category (category_name, category_description, active)
	 VALUES ('spożywcze', 'Żywność i artykuły pierwszej potrzeby', TRUE),
			('subskrypcje', 'Netflix, Spotify etc.', TRUE);

		
-- insert do tabeli transaction_subcategory

INSERT INTO expense_tracker.transaction_subcategory (id_trans_cat, subcategory_name, subcategory_description, active)
     VALUES (1, 'Warzywa i owoce', 'Warzywa i owoce nieprzetworzone', TRUE),
        	(1, 'Pieczywo', 'Chleb, wypieki słodkie', TRUE),
       		(1, 'Napoje', 'Napoje bezalkoholowe (soki, słodzone)', TRUE),
       		(2, 'Netflix', 'Comiesięczna opłata za Netflix', TRUE),
       		(2, 'Spotify', 'Comiesięczna opłata za Spotify', TRUE);
       	
       	
-- insert do tabeli transaction_type

INSERT INTO expense_tracker.transaction_type (transaction_type_name, transaction_type_desc, active)
	 VALUES ('Przelew przychodzący', 'Wpływ na konto', TRUE),
	 		('Przelew wychodzący', 'Wypływ środków z konta', TRUE),
	 		('Karta debetowa', 'Płatność kartą debetową', TRUE),
	 		('Karta kredytowa', 'Płatność kartą kredytową', TRUE);
       	
	 	
-- insert do tabeli transactions 

INSERT INTO expense_tracker.transactions (id_trans_cat, id_trans_subcat, id_trans_type, id_user, transaction_date, transaction_value, transaction_description)
     VALUES (1, 1, 3, 1, '18/10/2020', 32.19, 'zakupy w Żabce');

    
-- wyświetl zawartość tabel

SELECT * FROM expense_tracker.bank_account_owner;
SELECT * FROM expense_tracker.bank_account_types;
SELECT * FROM expense_tracker.transaction_bank_accounts;
SELECT * FROM expense_tracker.transaction_category;
SELECT * FROM expense_tracker.transaction_subcategory;
SELECT * FROM expense_tracker.transaction_type;
SELECT * FROM expense_tracker.transactions;
SELECT * FROM expense_tracker.users;


-- kopia zapasowa bazy danych

pg_dump --host localhost ^
		--port 5432 ^
		--username postgres ^
		--format plain ^
		--clean ^
		--file "C:\PostgreSQL_dump\expense_tracker_bp.sql" ^
		postgres
		
-- przywrócenie kopii zapasowej
		
psql -U postgres -p 5432 -h localhost -d postgres -f "C:\PostgreSQL_dump\expense_tracker_bp.sql"
