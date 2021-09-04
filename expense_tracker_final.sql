REVOKE CREATE ON SCHEMA public FROM public;
REVOKE ALL ON DATABASE postgres FROM public;




CREATE OR REPLACE PROCEDURE setup_expense_tracker(user_schema_name varchar) AS 
$$
DECLARE username TEXT := user_schema_name || '_user';
BEGIN
	RAISE NOTICE 'New schema name: %', user_schema_name;
	RAISE NOTICE 'New user name: %', username;

--check if schema already exists and if not, create new schema
	IF NOT EXISTS(SELECT 1 FROM information_schema.schemata
				   WHERE schema_name = user_schema_name) THEN
--	EXECUTE 'DROP SCHEMA IF EXISTS ' || user_schema_name || ' CASCADE';
	EXECUTE 'CREATE SCHEMA ' || user_schema_name;
	END IF;
	

	IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user 
					WHERE usename = username) THEN
		EXECUTE 'CREATE USER ' || username;
		EXECUTE 'GRANT USAGE ON SCHEMA ' || user_schema_name || ' TO ' || username;
		EXECUTE 'REVOKE CREATE ON SCHEMA ' || user_schema_name || ' FROM ' || username;
	END IF;

--#############
--create tables
--#############

	EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.users CASCADE';
	EXECUTE 'CREATE TABLE ' || user_schema_name || '.users ( 
	       id_user integer NOT NULL GENERATED ALWAYS AS IDENTITY,
	       user_login CHARACTER VARYING(25) NOT NULL,
	       user_name CHARACTER VARYING(50) NOT NULL,
	       user_password CHARACTER VARYING(100) NOT NULL,
           user_desc CHARACTER varying(250),
	       active BOOLEAN DEFAULT TRUE NOT NULL,
	       insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
       	   update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT users_pk PRIMARY KEY(id_user)
	);';

	EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.bank_account_owner CASCADE';
	EXECUTE 'CREATE TABLE ' || user_schema_name || '.bank_account_owner (
		   id_ba_own integer NOT NULL GENERATED ALWAYS AS IDENTITY,
		   id_user integer NOT NULL,
		   owner_name CHARACTER varying(50) NOT NULL,
		   owner_desc CHARACTER varying(250),
		   ba_type CHARACTER varying(50) NOT NULL,
		   ba_desc CHARACTER varying(250),
	       is_common_account character(1) DEFAULT 0 NOT NULL,
		   active BOOLEAN DEFAULT TRUE NOT NULL,
		   insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
		   update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT bank_account_owner_pk PRIMARY KEY(id_ba_own)
);';

	EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.transaction_category_subcategory CASCADE';
	EXECUTE 'CREATE TABLE ' || user_schema_name || '.transaction_category_subcategory (
		       id_trans_cat_subcat integer NOT NULL GENERATED ALWAYS AS IDENTITY,
				category_name CHARACTER VARYING(50) NOT NULL,
				category_description CHARACTER VARYING(250),
				subcategory_name CHARACTER VARYING(50) NOT NULL UNIQUE,
				subcategory_description CHARACTER VARYING(250),
				active character(1) DEFAULT 1 NOT NULL,
				insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
				update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT id_trans_cat_subcat_pk PRIMARY KEY(id_trans_cat_subcat)
);';

--	EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.transaction_subcategory';
--	EXECUTE 'CREATE TABLE ' || user_schema_name || '.transaction_subcategory (
--		       id_trans_subcat integer NOT NULL GENERATED ALWAYS AS IDENTITY,
--		       subcategory_name CHARACTER VARYING(50) NOT NULL,
--		       subcategory_description CHARACTER VARYING(250),
--		       active BOOLEAN DEFAULT TRUE NOT NULL,
--		       insert_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--		       update_date timestamp WITHOUT time ZONE DEFAULT CURRENT_TIMESTAMP,
--	CONSTRAINT id_trans_subcat PRIMARY KEY(id_trans_subcat)
--	);';

	EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.transaction_type CASCADE';
	EXECUTE 'CREATE TABLE ' || user_schema_name || '.transaction_type (
	           id_trans_type integer NOT NULL GENERATED ALWAYS AS IDENTITY,
	           transaction_type_name character varying(50) NOT NULL,
	           transaction_type_desc character varying(250),
	           active BOOLEAN DEFAULT TRUE NOT NULL,
	           insert_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
	           update_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT transaction_type_pk PRIMARY KEY(id_trans_type)
	);';

EXECUTE 'DROP TABLE IF EXISTS ' || user_schema_name || '.transactions_partitioned CASCADE';

EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_partitioned (
           id_transaction integer NOT NULL GENERATED ALWAYS AS IDENTITY,
--           id_trans_ba integer,
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
CONSTRAINT transactions_partitioned_transaction_category_subcategory_fk FOREIGN KEY(id_trans_cat_subcat) REFERENCES ' || user_schema_name || '.transaction_category_subcategory(id_trans_cat_subcat),
CONSTRAINT transactions_partitioned_users_fk FOREIGN KEY(id_user) REFERENCES ' || user_schema_name || '.users(id_user),
CONSTRAINT transactions_partitioned_bank_account_owner_fk FOREIGN KEY(id_trans_bao) REFERENCES ' || user_schema_name || '.bank_account_owner(id_ba_own),
CONSTRAINT transactions_partitioned_transaction_type FOREIGN KEY(id_trans_type) REFERENCES ' || user_schema_name || '.transaction_type(id_trans_type)
) PARTITION BY RANGE(transaction_date);';
                                                                                                                                                                                     
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2015 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2015-01-01'') TO (''2016-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2016 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2016-01-01'') TO (''2017-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2017 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2017-01-01'') TO (''2018-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2018 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2018-01-01'') TO (''2019-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2019 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2019-01-01'') TO (''2020-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2020 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2020-01-01'') TO (''2021-01-01'')';
EXECUTE 'CREATE TABLE ' || user_schema_name || '.transactions_y2021 PARTITION OF ' || user_schema_name || '.transactions_partitioned FOR VALUES FROM (''2021-01-01'') TO (''2022-01-01'')';

--##############
--create indexes
--##############

EXECUTE 'CREATE INDEX transactions_partitioned_year_idx ON ' || user_schema_name || '.transactions_partitioned(EXTRACT (YEAR FROM transaction_date))';
EXECUTE 'CREATE INDEX transactions_partitioned_month_idx ON ' || user_schema_name || '.transactions_partitioned(EXTRACT (MONTH FROM transaction_date))';

--#######################################
--create materialized views for analytics
--#######################################

EXECUTE 'CREATE MATERIALIZED VIEW IF NOT EXISTS ' || user_schema_name || '.transactions_per_year_mv AS
				SELECT EXTRACT(YEAR FROM t.transaction_date) transaction_year,
				sum(t.transaction_value) total_amount,
				avg(t.transaction_value) avg_amount
				FROM ' || user_schema_name || '.transactions_partitioned t
				GROUP BY EXTRACT(YEAR FROM t.transaction_date);';
			
EXECUTE 'CREATE MATERIALIZED VIEW IF NOT EXISTS ' || user_schema_name || '.transactions_per_month_mv AS
				SELECT EXTRACT(YEAR FROM t.transaction_date) transaction_year,
					   EXTRACT(MONTH FROM t.transaction_date) transaction_month,
				sum(t.transaction_value) total_amount,
				avg(t.transaction_value) avg_amount
				FROM ' || user_schema_name || '.transactions_partitioned t
				GROUP BY transaction_year, transaction_month;';
END; 
$$
LANGUAGE plpgsql;

--###################################################################################################
--create function returning transaction summary for given time interval (year, quarter, month or day)
--###################################################################################################
			
DROP FUNCTION transactions_per_interval;
CREATE OR REPLACE FUNCTION transactions_per_interval(t_int TEXT, user_schema_name TEXT)
		RETURNS TABLE (transaction_date varchar, sum_of_transactions float)
		LANGUAGE plpgsql
		AS $$
			DECLARE transactions_by_interval float;
			BEGIN
				IF $1 = 'year' THEN 
						 EXECUTE 'SELECT EXTRACT(YEAR FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM ' || quote_ident($2) || '.transactions_partitioned t 
						GROUP BY EXTRACT(YEAR FROM t.transaction_date);';
				ELSIF $1 = 'month' THEN 
						  EXECUTE 'SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM ' || quote_ident($2) || '.transactions_partitioned t 
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date);';
				ELSIF $1 = 'quarter' THEN 
						  EXECUTE 'SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date),
						         sum(t.transaction_value)
						    FROM ' || quote_ident($2) || '.transactions_partitioned t
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(QUARTER FROM t.transaction_date);';
				ELSIF $1 = 'day' THEN 
						  EXECUTE 'SELECT EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date) || '-' || EXTRACT(DAY FROM t.transaction_date),
							     sum(t.transaction_value)
						    FROM ' || quote_ident($2) || '.transactions_partitioned t
						GROUP BY EXTRACT(YEAR  FROM t.transaction_date) || '-' || EXTRACT(MONTH FROM t.transaction_date) || '-' || EXTRACT(DAY FROM t.transaction_date);';
				END IF;				
			END 
		$$;


--############################################
--call the procedure to create schema for user
--############################################

CALL setup_expense_tracker('testuser5');
REVOKE CREATE ON SCHEMA testuser5
'REVOKE CREATE ON SCHEMA ' || user_schema_name || ' TO ' || username;
