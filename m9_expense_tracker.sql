-- https://edu.datacraze.pl/zrozum-sql/modul-9-pozostale-struktury-danych/lekcja-13-praca-domowa/?bpmj_eddpc_url=1Zk1%2BQW5MSdgWWsitIUGSzgGauccCsFd52rAGLX5A5bgiY24jinwe6bOhQKD1BUetZtLPYVWiHRrWaDinWdHwIJ93%2Ff8wk%2FfdRaXxW7P4RdTF194PBnhY1WKQKfi4khRyclwthxoHtFvRqpzWSQ05NFUFsqU2ADgSsn6ju%2F7p%2FjGYCrCTVdytqbmhJdGcmRtFP2NmQ%3D%3D
--
-- UWAGA: W poniższych zadań niektóre wymagania dotyczą danych z udostępnionej w Moduł
-- 6 kopii schematu Expense Tracker. Jeżeli używasz swoich danych lub zmodyfikowanych danych
-- ze skryptu dopasuj odpowiednio nazwy kont, użytkowników, kategorii, podkategorii lub dat.

-- 1. Stwórz 3 osobne widoki dla wszystkich transakcji z podziałem na rodzaj właściciela
--    konta. W widokach wyświetl informacje o nazwie kategorii, nazwie podkategorii, typie
--    transakcji, dacie transakcji, roku z daty transakcji, wartości transakcji i type konta.


-- transakcje Grazyny Kowalskiej
SELECT t.id_transaction,
   		  bao.owner_name,
	      tc.category_name,
	      ts.subcategory_name,
	      tt.transaction_type_name,
	      t.transaction_date,
	      EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
	      t.transaction_value,
	      bat.ba_type
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
LEFT JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
LEFT JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_subcat =t.id_trans_subcat 
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
LEFT JOIN expense_tracker.bank_account_types bat ON tba.id_ba_typ = bat.id_ba_type
    WHERE owner_name = 'Grażyna Kowalska';   

-- transakcje Janusza Kowalskiego
CREATE OR REPLACE VIEW expense_tracker.transactions_Janusz_Kowalski AS 
   SELECT t.id_transaction,
   		  bao.owner_name,
	      tc.category_name,
	      ts.subcategory_name,
	      tt.transaction_type_name,
	      t.transaction_date,
	      EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
	      t.transaction_value,
	      bat.ba_type
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
LEFT JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
LEFT JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_subcat =t.id_trans_subcat 
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
LEFT JOIN expense_tracker.bank_account_types bat ON tba.id_ba_typ = bat.id_ba_type
    WHERE owner_name = 'Janusz Kowalski';
   
-- transakcje Janusza i Grażyny Kowalskich   
CREATE OR REPLACE VIEW expense_tracker.transactions_Janusz_Grazyna AS 
   SELECT t.id_transaction,
   		  bao.owner_name,
	      tc.category_name,
	      ts.subcategory_name,
	      tt.transaction_type_name,
	      t.transaction_date,
	      EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
	      t.transaction_value,
	      bat.ba_type
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
LEFT JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
LEFT JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_subcat =t.id_trans_subcat 
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
LEFT JOIN expense_tracker.bank_account_types bat ON tba.id_ba_typ = bat.id_ba_type
    WHERE owner_name = 'Janusz i Grażynka';
   
-- sprawdzenie, czy widoki istnieja w schemacie
SELECT *
  FROM information_schema."views" v 
 WHERE table_schema = 'expense_tracker'

-- sprawdzenie działania widoków
SELECT * 
  FROM expense_tracker.transactions_grazyna_kowalska;

SELECT *
  FROM expense_tracker.transactions_janusz_kowalski;

SELECT * 
  FROM expense_tracker.transactions_janusz_grazyna;
 
 
-- 2. Korzystając z widoku konta dla Janusza i Grażynki z zadania 1 przygotuj zapytanie, w
--    którym wyświetlisz, rok transakcji, typ transakcji, nazwę kategorii, zgrupowaną listę
--    unikatowych (DISTINCT) podkategorii razem z sumą transakcji dla grup rok transakcji,
--    typ transakcji, nazwę kategorii.

  SELECT transaction_year,
	     transaction_type_name,
	     category_name,
	     array_agg(DISTINCT subcategory_name),
	     sum(transaction_value)
    FROM expense_tracker.transactions_janusz_grazyna
GROUP BY transaction_year, transaction_type_name, category_name;

-- 3. Dodaj do schematu nową tabelę MONTHLY_BUDGET_PLANNED o atrybutach
--    - YEAR_MONTH VARCHAR(7) PRIMARY_KEY,
--    - BUDGET_PLANNED NUMERIC(10,2)
--    - LEFT_BUDGET NUMERIC(10,2)
--    Dodaj do tej tabeli nowy rekord z planowanym budżetem na dany miesiąc obecnego
--    roku (do obu atrybutów BUDGET_PLANNED, LEFT_BUDGET ta sama wartość)

CREATE TABLE expense_tracker.monthly_budget_planned (
	year_month varchar(7) PRIMARY KEY,
	budget_planned numeric(10, 2),
	budget_left numeric(10, 2)
);

INSERT INTO expense_tracker.monthly_budget_planned (year_month, budget_planned, budget_left)
   	 VALUES ('2019_8', 2430.00, 2430.00);
	
SELECT * 
  FROM expense_tracker.monthly_budget_planned;


-- 4. Dodaj nowy Wyzwalacz do tabeli TRANSACTIONS, który przy każdorazowym dodaniu
--    / zaktualizowaniu lub usunięciu wartości zmieni wartość LEFT_BUDGET odpowiednio
--    w tabeli expense_tracker.monthly_budget_planned.

SELECT column_name
FROM information_schema."columns" c
WHERE table_schema = 'expense_tracker'
	AND table_name = 'transactions';

	
CREATE OR REPLACE FUNCTION expense_tracker.monthly_budget_planned_function() 
	RETURNS TRIGGER 
	LANGUAGE plpgsql
	AS $$
	BEGIN
		IF (TG_OP = 'DELETE') THEN
			UPDATE expense_tracker.monthly_budget_planned SET budget_left = (budget_left - OLD.transaction_value)
			WHERE expense_tracker.monthly_budget_planned.year_month = concat(EXTRACT(YEAR FROM OLD.transaction_date), '_', EXTRACT(MONTH FROM OLD.transaction_date))::TEXT;
		ELSIF (TG_OP = 'UPDATE') THEN
			UPDATE expense_tracker.monthly_budget_planned SET budget_left = (budget_left + OLD.transaction_value - NEW.transaction_value)
			WHERE expense_tracker.monthly_budget_planned.year_month = concat(EXTRACT(YEAR FROM OLD.transaction_date), '_', EXTRACT(MONTH FROM OLD.transaction_date))::TEXT;
		ELSIF (TG_OP = 'INSERT') THEN 
			UPDATE expense_tracker.monthly_budget_planned SET budget_left = (budget_left - NEW.transaction_value)
			WHERE expense_tracker.monthly_budget_planned.year_month = concat(EXTRACT(YEAR FROM NEW.transaction_date), '_', EXTRACT(MONTH FROM NEW.transaction_date))::TEXT;
		END IF;
		RETURN NULL;
	END;
	$$;

CREATE TRIGGER monthly_budget_trigger 
	AFTER UPDATE OR DELETE OR INSERT
		ON expense_tracker.transactions 
	FOR EACH ROW 
		EXECUTE PROCEDURE expense_tracker.monthly_budget_planned_function();

-- 5. Przetestuj działanie wyzwalacza dla kilku przykładowych operacji.

-- dla testów wybrałem miesiąc z największą liczbą transakcji (2019-08), żeby móc swobodnie usuwać:
-- z tego powodu miesiąc ten też jest wpisany w monthly_budget_planned
  SELECT transaction_date, count(*) sum_trans_by_month
    FROM expense_tracker.transactions
GROUP BY transaction_date 
ORDER BY sum_trans_by_month DESC;


/* test DELETE */
SELECT *
  FROM expense_tracker.monthly_budget_planned;
--przed DELETE:
--2019_08	2430.00	2430.00

-- usuwam losowy rekord z tabeli transactions z miesiąca 2019_8
DELETE  
  FROM expense_tracker.transactions t
 WHERE t.id_transaction IN (SELECT t.id_transaction 
                              FROM expense_tracker.transactions t 
                             WHERE t.transaction_date BETWEEN '2019-08-01' AND '2019-08-31' 
                          ORDER BY random() 
                             LIMIT 1);


SELECT *
  FROM expense_tracker.monthly_budget_planned;
-- po DELETE:
-- 2019_8	2430.00	2580.00

/* test INSERT */
 
INSERT INTO expense_tracker.transactions (id_transaction, id_trans_ba, id_trans_cat, id_trans_subcat, id_trans_type, id_user, transaction_date, transaction_value, transaction_description, insert_date, update_date)
VALUES (9999, 1, 1, 6, 2, 1, '2019-08-05', 1000, 'd17', '2020-10-29 19:03:03.849687', '2020-10-29 19:03:03.849687');

SELECT *
  FROM expense_tracker.monthly_budget_planned;
-- po INSERT:
-- 2019_8	2430.00	1580.00

/* test UPDATE */
UPDATE expense_tracker.transactions 
   SET transaction_value = 500,
       update_date = now()
 WHERE id_transaction = (SELECT id_transaction 
						   FROM expense_tracker.transactions t2
						  WHERE t2.id_transaction = 9999);

SELECT *
  FROM expense_tracker.monthly_budget_planned;
-- po UPDATE:
-- 2019_8	2430.00	2080.00
							
-- 6. Czego brakuje w tym triggerze? Jakie potencjalnie spowoduje problemy w kontekście
--    danych w tabeli MONTHLY_BUDGET_PLANNED.
		
-- 1. moim zdaniem powinna być widokiem (zmaterializowanym?) odświeżanym według potrzeby tak, 
--    aby na bieżąco liczył budget_planned i budget_left na podstawie transakcji w danym miesiącu
-- 2. jeśli dodamy rekord, którego DATA transakcji nie istnieje w expense_tracker.monthly_budget_planned, TO funkcja wyrzuci błąd
-- 3. funkcja powinna także różnicować po rodzaju transakcji (dodatkowy warunek where t.id_transactions = ...)
-- 4. użytkownik powinien mieć także możliwość przeprowadzenia operacji UPDATE na każdym z innych atrybutów danej transakcji - 
--    w funkcji powinna być także zaimplementowana sytuacja, co w wypadku, kiedy użytkownik zmieni datę transakcji