-- 1. Zmień tabelę USERS w taki sposób, aby pozbyć się pola password_salt (wykorzystaj
--    gen_salt()), i hasło przetrzymywane w tabeli, powinno być hasłem zaszyfrowanym
--    funkcją crypt().

CREATE EXTENSION pgcrypto;

ALTER TABLE expense_tracker.users 
ADD COLUMN user_password_encrypted varchar(100);

UPDATE expense_tracker.users u
SET user_password_encrypted = crypt(user_password, gen_salt('md5'));

ALTER TABLE expense_tracker.users 
 DROP COLUMN IF EXISTS user_password,
 DROP COLUMN IF EXISTS password_salt;

SELECT * FROM expense_tracker.users;

-- da się to zrobić w trzech linijkach, ale nie wiem która
-- wersja jest preferowana w profesjonalnych rozwiązaniach:
UPDATE expense_tracker.users 
   SET user_password = crypt(user_password, gen_salt('md5'));
 ALTER TABLE expense_tracker.users DROP COLUMN password_salt;

-- 2. Przygotuj audyt tabel w schemacie EXPENSE_TRACKER. (skorzystaj z lekcji "Nieśmiał
--    Data Science" / Tabele administracyjne).
--     a. Zobacz ile wierszy dla tabel posiadających klucze obce ma w sobie wartość -1
--        (<unknown>).

-- tabele posiadajace klucze obce
SELECT * 
FROM information_schema.table_constraints
WHERE table_schema = 'expense_tracker'
AND constraint_type = 'FOREIGN KEY';

-- na jakich kolumnach zalozone sa foreign keys
SELECT *
FROM information_schema.constraint_column_usage ccu
WHERE constraint_schema = 'expense_tracker';

SELECT * FROM pg_stats WHERE schemaname = 'expense_tracker';
--     b. Czy w atrybutach tabeli TRANSACTIONS są wartości nieokreślone (NULL) - na
--        jakich atrybutach? Jaki procent całego zbioru danych one stanowią?

-- w jakich atrybutach tabeli są wartości nieokreslone i procent
SELECT attname, 
       null_frac * 100
  FROM pg_stats
 WHERE schemaname = 'expense_tracker' 
   AND tablename = 'transactions'
   AND null_frac > 0;
  
SELECT count(*) FROM expense_tracker.transactions t WHERE id_user IS NULL;

-- 3. Zastanów się i rozpisz w kilku krokach, Twoje podejście do wykorzystania
--    przygotowanego schematu, jako rzeczywistego elementu aplikacji.
--    Wymagania:
--    - Korzysta z niej wiele rodzin / osób (czy trzymasz wszystko w jednym
--      schemacie / czy schemat per użytkownik (rodzina) ?)
-- budżet zwykle dotyczy domu, więc umieściłbym wszystko w jednym schemacie tak, żeby wiele osób mogło jednocześcnie
-- z niego korzystać (tj. dodawac wydatki etc.)
--    - Jak zarządzasz użytkownikami i hasłami?
-- nie przechowujemy hasel w formie tektstowej. Uzywamy rozszerzenia pgcrypto do zaszyfrowania hasel
-- nazwy uzytkownikow - 
--    - Jak wykorzystasz wnioski z poprzednich modułów (które tabele, klucze obce
--      zostają / nie zostają, jak podejdziesz do wydajności itd.)

-- 4. Przygotuj finalny skrypt projektu, w którym będą wszystkie potrzebne elementy
--    składni do:
--    a. Stworzenia użytkowników i grup
--    b. Stworzenia tabel, kluczy obcych, partycji etc.
--    c. Stworzenia indeksów
--    d. Stworzenia innych typów obiektów (funkcji / procedur / triggerów)
--       bez danych tylko potrzebne struktury.

--#############
--create schema
--#############
DROP ROLE IF EXISTS expense_tracker_group;
DROP SCHEMA IF EXISTS expense_tracker CASCADE;
CREATE SCHEMA expense_tracker;

--##################################
--create roles and define privileges
--##################################

REVOKE CREATE ON SCHEMA public FROM public;
REVOKE ALL ON DATABASE postgres FROM public;

-- create role admin
DROP ROLE IF EXISTS expense_tracker_admin_group;
CREATE ROLE expense_tracker_admin_group;
GRANT ALL PRIVILEGES ON SCHEMA expense_tracker TO expense_tracker_admin_group;

CREATE ROLE expense_tracker_admin WITH login PASSWORD 'admin_pwd';
GRANT expense_tracker_admin TO expense_tracker_admin_group;

-- create role user

CREATE ROLE expense_tracker_user;
GRANT USAGE ON SCHEMA expense_tracker TO expense_tracker_user;
REVOKE CREATE ON SCHEMA expense_tracker FROM expense_tracker_user;

CREATE ROLE user_1 WITH login PASSWORD 'user_1_pwd';
CREATE ROLE user_2 WITH login PASSWORD 'user_2_pwd';

GRANT user_1 TO expense_tracker_user;
GRANT user_2 TO expense_tracker_user;

CREATE SCHEMA AUTHORIZATION user_1;
CREATE SCHEMA AUTHORIZATION user_2;


--SELECT * FROM pg_catalog.pg_roles WHERE rolname LIKE '%tracker%';
--SELECT * FROM pg_catalog.pg_user WHERE usename LIKE '%tracker%';


--#############
--CREATE TABLES
--#############
DROP EXTENSION IF EXISTS pgcrypto;
CREATE EXTENSION pgcrypto;


--################################
--create tables related with users 
--################################


DROP TABLE IF EXISTS expense_tracker.users CASCADE;
CREATE TABLE expense_tracker.users ( 
	       id_user integer NOT NULL GENERATED ALWAYS AS IDENTITY,
	       user_login CHARACTER VARYING(25) NOT NULL,
	       user_name CHARACTER VARYING(50) NOT NULL,
	       user_password CHARACTER VARYING(100) NOT NULL,
           user_desc CHARACTER varying(250),
	       active BOOLEAN DEFAULT TRUE NOT NULL,
	       insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
       	   update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT users_pk PRIMARY KEY(id_user)
);


--########################################
--create tabled related with bank accounts 
--########################################


-- dodano FK id_user do tabeli
DROP TABLE IF EXISTS expense_tracker.bank_account_owner CASCADE;
CREATE TABLE expense_tracker.bank_account_owner (
		   id_ba_own integer NOT NULL GENERATED ALWAYS AS IDENTITY,
		   id_user integer NOT NULL,
		   owner_name CHARACTER varying(50) NOT NULL,
		   owner_desc CHARACTER varying(250),
		   ba_type CHARACTER varying(50) NOT NULL,
		   ba_desc CHARACTER varying(250),
	       is_common_account character(1) DEFAULT 0 NOT NULL,
		   active character(1) DEFAULT 1 NOT NULL,
		   insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
		   update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT bank_account_owner_pk PRIMARY KEY(id_ba_own)
--CONSTRAINT bank_account_owner_users_fk FOREIGN KEY(id_user) REFERENCES expense_tracker.users(id_user)
);


--#######################################
--create tables related with transactions
--#######################################


--DROP TABLE IF EXISTS expense_tracker.transaction_category CASCADE;
--CREATE TABLE expense_tracker.transaction_category (
--	       id_trans_cat integer NOT NULL GENERATED ALWAYS AS IDENTITY,
--	       category_name CHARACTER VARYING(50) NOT NULL,
--	       category_description CHARACTER VARYING(250),
--	       active character(1) DEFAULT 1 NOT NULL,
--	       insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--	       update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--CONSTRAINT id_trans_cat_pk PRIMARY KEY(id_trans_cat)
--);

--DROP TABLE IF EXISTS expense_tracker.transaction_subcategory CASCADE;
--CREATE TABLE expense_tracker.transaction_subcategory (
--	       id_trans_subcat integer NOT NULL GENERATED ALWAYS AS IDENTITY,
--	       subcategory_name CHARACTER VARYING(50) NOT NULL,
--	       subcategory_description CHARACTER VARYING(250),
--	       active character(1) DEFAULT 1 NOT NULL,
--	       insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--	       update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--CONSTRAINT id_trans_subcat PRIMARY KEY(id_trans_subcat)
--);

DROP TABLE IF EXISTS expense_tracker.transaction_category_subcategory;
CREATE TABLE expense_tracker.transaction_category_subcategory (
	id_trans_cat_subcat integer NOT NULL GENERATED ALWAYS AS IDENTITY,
	category_name CHARACTER VARYING(50) NOT NULL,
	category_description CHARACTER VARYING(250),
	subcategory_name CHARACTER VARYING(50) NOT NULL UNIQUE,
	subcategory_description CHARACTER VARYING(250),
	active character(1) DEFAULT 1 NOT NULL,
	insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
	update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT id_trans_cat_subcat_pk PRIMARY KEY(id_trans_cat_subcat)
);

DROP TABLE IF EXISTS expense_tracker.transaction_type CASCADE;
CREATE TABLE expense_tracker.transaction_type (
           id_trans_type integer NOT NULL GENERATED ALWAYS AS IDENTITY,
           transaction_type_name character varying(50) NOT NULL,
           transaction_type_desc character varying(250),
           active character(1) DEFAULT 1 NOT NULL,
           insert_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
           update_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT transaction_type_pk PRIMARY KEY(id_trans_type)
);


DROP TABLE IF EXISTS expense_tracker.transactions_partitioned CASCADE;
CREATE TABLE expense_tracker.transactions_partitioned (
           id_transaction integer NOT NULL GENERATED ALWAYS AS IDENTITY,
           id_trans_ba integer,
           id_trans_bao integer,
           id_trans_cat_subcat integer NOT NULL,
           id_trans_type integer,
           id_user integer,
           transaction_date date DEFAULT CURRENT_DATE,
           transaction_value numeric(9,2),
           transaction_description text,
           insert_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
           update_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT id_transaction_pk PRIMARY KEY(id_transaction, transaction_date),
CONSTRAINT transactions_partitioned_transaction_category_subcategory_fk FOREIGN KEY(id_trans_cat_subcat) REFERENCES expense_tracker.transaction_category_subcategory(id_trans_cat_subcat),
CONSTRAINT transactions_partitioned_users_fk FOREIGN KEY(id_user) REFERENCES expense_tracker.users(id_user),
CONSTRAINT transactions_partitioned_bank_account_owner_fk FOREIGN KEY(id_trans_bao) REFERENCES expense_tracker.bank_account_owner(id_ba_own),
CONSTRAINT transactions_partitioned_transaction_type FOREIGN KEY(id_trans_type) REFERENCES expense_tracker.transaction_type(id_trans_type)
) PARTITION BY RANGE(transaction_date);

CREATE TABLE expense_tracker.transactions_y2015 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE expense_tracker.transactions_y2016 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE expense_tracker.transactions_y2017 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE expense_tracker.transactions_y2018 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE expense_tracker.transactions_y2019 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE expense_tracker.transactions_y2020 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE expense_tracker.transactions_y2021 PARTITION OF expense_tracker.transactions_partitioned FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');


--################
--define functions
--################
-- function returns transactions from given time interval (day, month, quarter, year). 
-- Accepts 'day', 'month', 'quarter' or 'year' as argument. Returns table with transactions sum in selected time interval
DROP FUNCTION expense_tracker.transactions_per_interval;
CREATE OR REPLACE FUNCTION expense_tracker.transactions_per_interval(t_int TEXT)
		RETURNS TABLE (transaction_date varchar, sum_of_transactions float)
		LANGUAGE plpgsql
		AS $$
			DECLARE transactions_by_interval float;
			BEGIN
				IF $1 = 'year' THEN 
						  SELECT EXTRACT(YEAR FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM expense_tracker.transactions_partitioned t
						GROUP BY EXTRACT(YEAR FROM t.transaction_date);
				ELSIF $1 = 'month' THEN 
						  SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM expense_tracker.transactions_partitioned t
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date);
				ELSIF $1 = 'quarter' THEN 
						  SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date),
						         sum(t.transaction_value)
						    FROM expense_tracker.transactions_partitioned t
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date);
				ELSIF $1 = 'day' THEN 
						  SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date) || '-' || EXTRACT(DAY FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM expense_tracker.transactions_partitioned t
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date) || '-' || EXTRACT(DAY FROM t.transaction_date);
				END IF;				
			END 
		$$;


--############
--define views
--############
CREATE MATERIALIZED VIEW expense_tracker.transactions_per_year_mv AS
				SELECT EXTRACT(YEAR FROM t.transaction_date) transaction_year,
				sum(t.transaction_value) total_amount,
				avg(t.transaction_value) avg_amount
				FROM expense_tracker.transactions_partitioned t
				GROUP BY EXTRACT(YEAR FROM t.transaction_date);
			
CREATE MATERIALIZED VIEW expense_tracker.transactions_per_month_mv AS
				SELECT EXTRACT(YEAR FROM t.transaction_date) transaction_year,
					   EXTRACT(MONTH FROM t.transaction_date) transaction_month,
				sum(t.transaction_value) total_amount,
				avg(t.transaction_value) avg_amount
				FROM expense_tracker.transactions_partitioned t
				GROUP BY transaction_year, transaction_month;


-- function returns all transactions made by given user. Arguments: user_name
DROP FUNCTION IF EXISTS expense_tracker.transactions_by_user;
CREATE OR REPLACE FUNCTION expense_tracker.transactions_by_user(user_name TEXT)
	RETURNS float
	LANGUAGE plpgsql
	AS $$
		DECLARE transactions_by_user float;
		BEGIN
			SELECT sum(t.transaction_value)
			INTO transactions_by_user
			FROM expense_tracker.transactions_partitioned t
			INNER JOIN expense_tracker.users u ON u.id_user = t.id_user
			WHERE u.user_name = $1;
		END
	$$;

--##############
--create indexes
--##############

CREATE INDEX transactions_partitioned_year_idx ON expense_tracker.transactions_partitioned(EXTRACT (YEAR FROM transaction_date));
CREATE INDEX transactions_partitioned_month_idx ON expense_tracker.transactions_partitioned(EXTRACT (MONTH FROM transaction_date));

--create trigger

CREATE TRIGGER no_input_if_subcat_dont_match_cat
AFTER INSERT ON transactions_partitioned
WHEN NOT EXISTS (SELECT * FROM transaction_category tc WHERE tc.id = transaction_subcategory.id)
BEGIN
	SELECT RAISE(FAIL, 'the subcategory must match a category');
END;
END

SELECT * FROM pg_catalog.pg_roles pr;