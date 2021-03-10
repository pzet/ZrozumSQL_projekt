-- https://edu.datacraze.pl/zrozum-sql/modul-9-pozostale-struktury-danych/lekcja-13-praca-domowa/?bpmj_eddpc_url=1Zk1%2BQW5MSdgWWsitIUGSzgGauccCsFd52rAGLX5A5bgiY24jinwe6bOhQKD1BUetZtLPYVWiHRrWaDinWdHwIJ93%2Ff8wk%2FfdRaXxW7P4RdTF194PBnhY1WKQKfi4khRyclwthxoHtFvRqpzWSQ05NFUFsqU2ADgSsn6ju%2F7p%2FjGYCrCTVdytqbmhJdGcmRtFP2NmQ%3D%3D
--
-- UWAGA: W poniższych zadań niektóre wymagania dotyczą danych z udostępnionej w Moduł
-- 6 kopii schematu Expense Tracker. Jeżeli używasz swoich danych lub zmodyfikowanych danych
-- ze skryptu dopasuj odpowiednio nazwy kont, użytkowników, kategorii, podkategorii lub dat.

-- 1. Stwórz 3 osobne widoki dla wszystkich transakcji z podziałem na rodzaj właściciela
--    konta. W widokach wyświetl informacje o nazwie kategorii, nazwie podkategorii, typie
--    transakcji, dacie transakcji, roku z daty transakcji, wartości transakcji i type konta.


-- transakcje Grazyny Kowalskiej
CREATE OR REPLACE VIEW expense_tracker.transactions_Grazyna_Kowalska AS 
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
GROUP BY transaction_year, transaction_type_name, category_name

-- 3. Dodaj do schematu nową tabelę MONTHLY_BUDGET_PLANNED o atrybutach
--    - YEAR_MONTH VARCHAR(7) PRIMARY_KEY,
--    - BUDGET_PLANNED NUMERIC(10,2)
--    - LEFT_BUDGET NUMERIC(10,2)
--    Dodaj do tej tabeli nowy rekord z planowanym budżetem na dany miesiąc obecnego
--    roku (do obu atrybutów BUDGET_PLANNED, LEFT_BUDGET ta sama wartość)

-- 4. Dodaj nowy Wyzwalacz do tabeli TRANSACTIONS, który przy każdorazowym dodaniu
--    / zaktualizowaniu lub usunięciu wartości zmieni wartość LEFT_BUDGET odpowiednio
--    w tabeli expense_tracker.monthly_budget_planned.

-- 5. Przetestuj działanie wyzwalacza dla kilku przykładowych operacji.

-- 6. Czego brakuje w tym triggerze? Jakie potencjalnie spowoduje problemy w kontekście
--    danych w tabeli MONTHLY_BUDGET_PLANNED.