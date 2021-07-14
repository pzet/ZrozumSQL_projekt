-- gdzie zalozyc indeksy:
-- tam, gdzie czesto mamy selecta (np tabela z datami)
-- tam, gdzie czesto wystepuja joiny
--https://edu.datacraze.pl/zrozum-sql/modul-11-wydajnosc/lekcja-18-praca-domowa/?bpmj_eddpc_url=hAeVfEmLiG6EzkcwyjEl5TdMZYhwPGH0%2BdMojynEtuICIyh0qN3E%2Fmodg7rnzlAForQZNJKdCVZYAnjryp6AxAiM6aClmOhg9eeVcZEPtYG%2FXMpWhYQ%2Fn%2BAj1hCQjpPi4QqZxN%2FiJ3YnwjGg0dX3x5FtsdVXEbEv3CN95yB8YXdnzgtYH6Si7oaOxJpJIC5HDIO9GA%3D%3D

--Na podstawie zadań z poprzednich modułów, zastanów się jak najczęściej odpytujemy
--schemat EXPENSE_TRACKER. Czego zwykle poszukujemy? Jakie ograniczenia / filtry dajem
--w naszych zapytaniach.
--Na podstawie tych informacji przygotuj strategię zwiększającą wydajność rozwiązania
--projektowego EXPENSE_TRACKER. Zastanów się nad zastosowanie znanych Ci konstrukcji:
--* Indeksy BTREE
--* Indeksy GIN (np. wyszukiwanie pełnotekstowe i trigramy)
--* Partycjonowanie
--* Denormalizacja / Normalizacja struktury
--* Widoki vs Widoki Zmaterializowane
--* Etc.
--Przed zaimplementowanie zmian zapisz obecne wyniki dla planu wykonania zapytania tych
--zapytań, na których będziesz testować swoje rozwiązanie.
--Po przygotowaniu strategii, sprawdź wdrożone metody analizując plan zapytania i porównując
--nowy plan z poprzednim.
--Pamiętaj o ewentualnym czyszczeniu pamięci podręcznej dla planów – DISCARD ALL.


-- We wszystkich zapytaniach wykorzystuję indeksy typu Btree, które wydają się najbardziej odpowiednie do typu danych.
-- Indeks GIN dedykowany jest dla tabel, gdzie w jednej kolumnie znajduje się kilka typów danych - w naszej bazie to nie występuje
-- Indeks GiST wydaje się mieć większe zastosowanie w sytuacjach, gdzie np. użytkownik może dodawać własny opis transakcji,
-- który następnie chcemy przeszukać
DISCARD ALL;

-- wszystkie transakcje wydane na kategorie jedzenie
DISCARD ALL;
EXPLAIN ANALYZE 
   SELECT EXTRACT (YEAR FROM t.transaction_date) transaction_year,
	      sum(t.transaction_value) monthly_food_expenditure
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
    WHERE tc.category_name = 'JEDZENIE'
 GROUP BY EXTRACT (YEAR FROM t.transaction_date);
--Execution Time: 7.648 ms

--DROP INDEX expense_tracker.idx_transactions_id_trans_cat;
CREATE INDEX idx_transactions_id_trans_cat
          ON expense_tracker.transactions
       USING btree (id_trans_cat);
--Execution Time: 5.943 ms
-- Po założeniu indeksu na kolumnę id_trans_cat zapytanie wykonuje się ok. 1.7 ms szybciej

DISCARD ALL;
EXPLAIN ANALYZE 
SELECT *
FROM expense_tracker.transactions t
LEFT JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
LEFT JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_subcat = t.id_trans_subcat 
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
    WHERE t.transaction_date BETWEEN '2016-01-01' AND '2017-01-01'
      AND tc.category_name = 'JEDZENIE'
      AND t.transaction_value > 100;
     
--QUERY PLAN                                                                                                                                                        |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
--Nested Loop Left Join  (cost=3.33..216.22 rows=16 width=303) (actual time=2.201..2.204 rows=0 loops=1)                                                            |
--  Join Filter: (tba.id_trans_ba = t.id_trans_ba)                                                                                                                  |
--  ->  Nested Loop  (cost=3.33..213.61 rows=16 width=232) (actual time=2.201..2.203 rows=0 loops=1)                                                                |
--        Join Filter: (t.id_trans_cat = tc.id_trans_cat)                                                                                                           |
--        Rows Removed by Join Filter: 153                                                                                                                          |
--        ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=77) (actual time=0.023..0.025 rows=1 loops=1)                                      |
--              Filter: ((category_name)::text = 'JEDZENIE'::text)                                                                                                  |
--              Rows Removed by Filter: 10                                                                                                                          |
--        ->  Hash Left Join  (cost=3.33..210.26 rows=177 width=155) (actual time=0.254..2.160 rows=153 loops=1)                                                    |
--              Hash Cond: (t.id_trans_type = tt.id_trans_type)                                                                                                     |
--              ->  Hash Left Join  (cost=2.21..208.30 rows=177 width=98) (actual time=0.219..2.044 rows=153 loops=1)                                               |
--                    Hash Cond: (t.id_trans_subcat = ts.id_trans_subcat)                                                                                           |
--                    ->  Seq Scan on transactions t  (cost=0.00..205.58 rows=177 width=54) (actual time=0.164..1.901 rows=153 loops=1)                             |
--                          Filter: ((transaction_date >= '2016-01-01'::date) AND (transaction_date <= '2017-01-01'::date) AND (transaction_value > '100'::numeric))|
--                          Rows Removed by Filter: 6966                                                                                                            |
--                    ->  Hash  (cost=1.54..1.54 rows=54 width=44) (actual time=0.039..0.039 rows=54 loops=1)                                                       |
--                          Buckets: 1024  Batches: 1  Memory Usage: 13kB                                                                                           |
--                          ->  Seq Scan on transaction_subcategory ts  (cost=0.00..1.54 rows=54 width=44) (actual time=0.016..0.021 rows=54 loops=1)               |
--              ->  Hash  (cost=1.05..1.05 rows=5 width=57) (actual time=0.023..0.023 rows=5 loops=1)                                                               |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                  |
--                    ->  Seq Scan on transaction_type tt  (cost=0.00..1.05 rows=5 width=57) (actual time=0.011..0.012 rows=5 loops=1)                              |
--  ->  Materialize  (cost=0.00..1.10 rows=7 width=71) (never executed)                                                                                             |
--        ->  Seq Scan on transaction_bank_accounts tba  (cost=0.00..1.07 rows=7 width=71) (never executed)                                                         |
--Planning Time: 0.927 ms                                                                                                                                           |
--Execution Time: 2.298 ms                                                                                                                                          |                                                                                                                 |

-- indeks na wartość transakcji (tylko)
DROP INDEX IF EXISTS expense_tracker.idx_transactions_trans_val;
CREATE INDEX idx_transactions_trans_val
          ON expense_tracker.transactions
       USING hash (transaction_value);
      
--QUERY PLAN                                                                                                                                                    |
----------------------------------------------------------------------------------------------------------------------------------------------------------------|
--Nested Loop Left Join  (cost=22.92..120.96 rows=16 width=303) (actual time=0.599..0.602 rows=0 loops=1)                                                       |
--  Join Filter: (tt.id_trans_type = t.id_trans_type)                                                                                                           |
--  ->  Hash Left Join  (cost=22.92..118.85 rows=16 width=246) (actual time=0.598..0.601 rows=0 loops=1)                                                        |
--        Hash Cond: (t.id_trans_subcat = ts.id_trans_subcat)                                                                                                   |
--        ->  Hash Left Join  (cost=20.71..116.59 rows=16 width=202) (actual time=0.598..0.600 rows=0 loops=1)                                                  |
--              Hash Cond: (t.id_trans_ba = tba.id_trans_ba)                                                                                                    |
--              ->  Hash Join  (cost=19.55..115.37 rows=16 width=131) (actual time=0.597..0.599 rows=0 loops=1)                                                 |
--                    Hash Cond: (t.id_trans_cat = tc.id_trans_cat)                                                                                             |
--                    ->  Bitmap Heap Scan on transactions t  (cost=18.40..113.58 rows=177 width=54) (actual time=0.264..0.541 rows=153 loops=1)                |
--                          Recheck Cond: (transaction_value > '100'::numeric)                                                                                  |
--                          Filter: ((transaction_date >= '2016-01-01'::date) AND (transaction_date <= '2017-01-01'::date))                                     |
--                          Rows Removed by Filter: 656                                                                                                         |
--                          Heap Blocks: exact=81                                                                                                               |
--                          ->  Bitmap Index Scan on idx_transactions_trans_val  (cost=0.00..18.36 rows=810 width=0) (actual time=0.213..0.213 rows=809 loops=1)|
--                                Index Cond: (transaction_value > '100'::numeric)                                                                              |
--                    ->  Hash  (cost=1.14..1.14 rows=1 width=77) (actual time=0.026..0.027 rows=1 loops=1)                                                     |
--                          Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                        |
--                          ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=77) (actual time=0.017..0.019 rows=1 loops=1)                |
--                                Filter: ((category_name)::text = 'JEDZENIE'::text)                                                                            |
--                                Rows Removed by Filter: 10                                                                                                    |
--              ->  Hash  (cost=1.07..1.07 rows=7 width=71) (never executed)                                                                                    |
--                    ->  Seq Scan on transaction_bank_accounts tba  (cost=0.00..1.07 rows=7 width=71) (never executed)                                         |
--        ->  Hash  (cost=1.54..1.54 rows=54 width=44) (never executed)                                                                                         |
--              ->  Seq Scan on transaction_subcategory ts  (cost=0.00..1.54 rows=54 width=44) (never executed)                                                 |
--  ->  Materialize  (cost=0.00..1.07 rows=5 width=57) (never executed)                                                                                         |
--        ->  Seq Scan on transaction_type tt  (cost=0.00..1.05 rows=5 width=57) (never executed)                                                               |
--Planning Time: 1.510 ms                                                                                                                                       |
--Execution Time: 0.739 ms                                                                                                                                      |

-- dla porównania dla jeśli indeks na transaction_value jest typu hash, to baza danych go nie wykorzystuje

-- próbowałem założyć też indeks na kategorię transakcji, ale wg planu wykonania zapytania nie został wykorzystany
DROP INDEX IF EXISTS expense_tracker.idx_transaction_cat;
CREATE INDEX idx_transaction_cat

          ON expense_tracker.transaction_category 
       USING btree (category_name);

--QUERY PLAN                                                                                                                                                        |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
--Nested Loop Left Join  (cost=3.33..216.22 rows=16 width=303) (actual time=2.218..2.220 rows=0 loops=1)                                                            |
--  Join Filter: (tba.id_trans_ba = t.id_trans_ba)                                                                                                                  |
--  ->  Nested Loop  (cost=3.33..213.61 rows=16 width=232) (actual time=2.217..2.219 rows=0 loops=1)                                                                |
--        Join Filter: (t.id_trans_cat = tc.id_trans_cat)                                                                                                           |
--        Rows Removed by Join Filter: 153                                                                                                                          |
--        ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=77) (actual time=0.024..0.026 rows=1 loops=1)                                      |
--              Filter: ((category_name)::text = 'JEDZENIE'::text)                                                                                                  |
--              Rows Removed by Filter: 10                                                                                                                          |
--        ->  Hash Left Join  (cost=3.33..210.26 rows=177 width=155) (actual time=0.272..2.175 rows=153 loops=1)                                                    |
--              Hash Cond: (t.id_trans_type = tt.id_trans_type)                                                                                                     |
--              ->  Hash Left Join  (cost=2.21..208.30 rows=177 width=98) (actual time=0.221..2.044 rows=153 loops=1)                                               |
--                    Hash Cond: (t.id_trans_subcat = ts.id_trans_subcat)                                                                                           |
--                    ->  Seq Scan on transactions t  (cost=0.00..205.58 rows=177 width=54) (actual time=0.166..1.898 rows=153 loops=1)                             |
--                          Filter: ((transaction_date >= '2016-01-01'::date) AND (transaction_date <= '2017-01-01'::date) AND (transaction_value > '100'::numeric))|
--                          Rows Removed by Filter: 6966                                                                                                            |
--                    ->  Hash  (cost=1.54..1.54 rows=54 width=44) (actual time=0.038..0.039 rows=54 loops=1)                                                       |
--                          Buckets: 1024  Batches: 1  Memory Usage: 13kB                                                                                           |
--                          ->  Seq Scan on transaction_subcategory ts  (cost=0.00..1.54 rows=54 width=44) (actual time=0.015..0.021 rows=54 loops=1)               |
--              ->  Hash  (cost=1.05..1.05 rows=5 width=57) (actual time=0.035..0.035 rows=5 loops=1)                                                               |
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                  |
--                    ->  Seq Scan on transaction_type tt  (cost=0.00..1.05 rows=5 width=57) (actual time=0.017..0.017 rows=5 loops=1)                              |
--  ->  Materialize  (cost=0.00..1.10 rows=7 width=71) (never executed)                                                                                             |
--        ->  Seq Scan on transaction_bank_accounts tba  (cost=0.00..1.07 rows=7 width=71) (never executed)                                                         |
--Planning Time: 1.765 ms                                                                                                                                           |
--Execution Time: 2.317 ms                             

-- WIDOKI
-- Wydaje mi się, że można zastosować widoki dla często używanych opcji w planowaniu budżetu, np. średnich wydatków w miesiącu:

DROP VIEW expense_tracker.budget_monthly;
CREATE VIEW expense_tracker.budget_monthly AS (
   SELECT to_char(t.transaction_date, 'YYYY-MM') AS month_budgeted,
	      tc.category_name,
          sum(t.transaction_value) total_expenditure
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
 GROUP BY to_char(t.transaction_date, 'YYYY-MM'), tc.category_name
 );

EXPLAIN ANALYZE 
SELECT * 
  FROM expense_tracker.budget_monthly
 WHERE category_name = 'PRZYCHÓD'
 
-- podobnie, można też zrobić widok zbierający wszystkie tabele i wszystkie informacje z nich w jedno zapytanie, które
-- następnie można filtrować, ale nie wiem czy takie rozwiązanie jest praktyczne. Wydaje mi się, że byłoby w przypadku
-- częstej potrzeby pobierania pełnej informacji np. o użytkowniku (filtrowanie po bank_account_owner).
-- Jako, że transakcje nie są dodawane z wysoką częstotliwością, to być może lepszym wyborem będzie widok zmaterializowany,
-- który zapewni szybsze wykonanie zapytania:
-- MATERIALIZED VIEW: Execution Time: 0.169 ms
-- VIEW: Execution Time: 0.264 ms

 -- NORMALIZACJA
-- nie DO końca jeszcze czuję postaci normalne, ale wydaje mi się, że większość mamy w postaci 3NF. Nie wiem natomiast,
-- czy atrybut "transaction_type_desc" w tabeli transaction_type spełnia warunek atomowości (rozumiem jednak że tak, pomimo
-- bycia wielowyrazowym stringiem)

-- PARTYCJONOWANIE
-- partycjonowanie tabeli transactions wg lat wydaje się być dobrym pomysłem
CREATE TABLE expense_tracker.transactions_partitioned (
    id_transaction integer NOT NULL,
    id_trans_ba integer,
    id_trans_cat integer,
    id_trans_subcat integer,
    id_trans_type integer,
    id_user integer,
    transaction_date date DEFAULT CURRENT_DATE,
    transaction_value numeric(9,2),
    transaction_description text,
    insert_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    update_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (transaction_date);

-- partycje dla trzech ostatnich lat:
CREATE TABLE expense_tracker.sales_y2020_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE expense_tracker.sales_y2019_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

CREATE TABLE expense_tracker.sales_y2018_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE expense_tracker.sales_y2017_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE expense_tracker.sales_y2016_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE expense_tracker.sales_y2015_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE expense_tracker.sales_y2014_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE expense_tracker.sales_y2013_part PARTITION OF expense_tracker.transactions_partitioned
	FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

INSERT INTO expense_tracker.transactions_partitioned
SELECT *
FROM expense_tracker.transactions;

DISCARD ALL;
EXPLAIN ANALYZE
SELECT *
FROM expense_tracker.transactions t;
-- Execution Time: 1.262 ms
 
EXPLAIN ANALYZE 
SELECT *
FROM expense_tracker.transactions_partitioned;
-- Execution Time: 4.567 ms

-- W przypadku tego selecta czas jest niestety zdecydowanie dłuższy, co ma związek
-- z koniecznością wykonania skanu sekwencyjnego na każdej z partycji.