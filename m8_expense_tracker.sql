-- 1. Oblicz sumę transakcji w podziale na kategorie transakcji. W wyniku wyświetl nazwę
--    kategorii i całkowitą sumę.

   SELECT tc.category_name,
          sum(t.transaction_value) total_expenses
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc  ON tc.id_trans_cat = t.id_trans_cat
 GROUP BY tc.category_name;

-- 2. Oblicz sumę wydatków na Używki dokonana przez Janusza (Janusz Kowalski) z jego
--    konta prywatnego (ROR - Janusz) w obecnym roku 2020.


WITH uzywki_exp 
AS 
(
-- wybierz transakcje z kategorii używki z roku 2020
   SELECT *
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
    WHERE tc.category_name = 'UŻYWKI' AND EXTRACT(YEAR FROM t.transaction_date) = 2020 
),
-- wybierz konto typu ROR i właścicielem Janusz
janusz_ror 
AS 
(
SELECT * 
  FROM expense_tracker.bank_account_types bat 
  JOIN expense_tracker.users u ON u.id_user = bat.id_ba_own
                              AND u.user_name = 'Janusz Kowalski'
                              AND bat.ba_type = 'ROR'
)
SELECT sum(ue.transaction_value) sum_ROR_exp_2020
  FROM uzywki_exp ue
  JOIN janusz_ror ON janusz_ror.id_ba_type = ue.id_trans_ba;
 
-- w tym wypadku lepiej nie używać CTE, bo zaciemniają obraz:

SELECT sum(t.transaction_value)
  FROM expense_tracker.transactions t
  JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
                                              AND tc.category_name = 'UŻYWKI'
  JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba
  JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own
  JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = tba.id_ba_typ
										     AND bat.id_ba_own = bao.id_ba_own 
										     AND bat.ba_type = 'ROR'
  JOIN expense_tracker.users u ON u.id_user = bao.user_login 
	 						  AND u.user_login = 'jkowalski'
 WHERE EXTRACT(YEAR FROM t.transaction_date) = 2020;


-- 3. Stwórz zapytanie, które będzie podsumowywać wydatki (typ transakcji: Obciążenie) na
--    wspólnym koncie RoR - Janusza i Grażynki w taki sposób, aby widoczny był podział
--    sumy wydatków, ze względu na rok, rok i kwartał (format: 2019_1), rok i miesiąc (format:
--    2019_12) w roku 2019. Skorzystaj z funkcji ROLLUP.

--SELECT * FROM expense_tracker.transactions;
--SELECT * FROM expense_tracker.bank_account_types bat
-- https://www.sqlpedia.pl/wielokrotne-grupowanie-grouping-sets-rollup-cube/
           
   SELECT EXTRACT(YEAR FROM t.transaction_date) yr,
          EXTRACT(YEAR FROM t.transaction_date) || '_' || EXTRACT(QUARTER FROM t.transaction_date) yr_qtr,
          EXTRACT(YEAR FROM t.transaction_date) || '_' || EXTRACT(MONTH FROM t.transaction_date) yr_mnth,
          sum(t.transaction_value),
          GROUPING(EXTRACT(YEAR FROM t.transaction_date)) grupowanie_po_roku,
          GROUPING(EXTRACT(YEAR FROM t.transaction_date) || '_' || EXTRACT(QUARTER FROM t.transaction_date)) grupowanie_po_kwartale,
          GROUPING(EXTRACT(YEAR FROM t.transaction_date) || '_' || EXTRACT(MONTH FROM t.transaction_date)) grupowanie_po_miesiacu
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = t.id_trans_ba
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
    WHERE tt.transaction_type_name = 'Obciążenie'
      AND bat.id_ba_type = 5
      AND EXTRACT(YEAR FROM t.transaction_date) = 2019
      GROUP BY ROLLUP (yr, 
                       yr_qtr,
                       yr_mnth)
 ORDER BY yr_qtr, yr_mnth;

-- 4. Stwórz zapytanie podsumowujące sumę wydatków na koncie wspólnym Janusza i
--    Grażynki (ROR- Wspólny), wydatki (typ: Obciążenie), w podziale na poszczególne lata
--    od roku 2015 wzwyż. Do wyników (rok, suma wydatków) dodaj korzystając z funkcji
--    okna atrybut, który będzie różnicą pomiędzy danym rokiem a poprzednim (balans rok
--    do roku).
       
-- pierwsza wersja zapytania:

SELECT EXTRACT (YEAR FROM t.transaction_date) transaction_year,
       sum(t.transaction_value) yearly_transaction_value,
       sum(t.transaction_value) - lag(sum(t.transaction_value)) OVER (ORDER BY EXTRACT (YEAR FROM t.transaction_date)) balance_yr_by_yr
  FROM expense_tracker.transactions t
  JOIN (SELECT * 
          FROM expense_tracker.transaction_bank_accounts tba 
         WHERE id_ba_own = 3 AND id_ba_typ = 5) sub1 ON t.id_trans_ba = sub1.id_trans_ba
  JOIN (SELECT * 
           FROM expense_tracker.transaction_type tt WHERE tt.transaction_type_name LIKE '%bciążenie%') sub2 ON t.id_trans_type = sub2.id_trans_type
WHERE EXTRACT (YEAR FROM t.transaction_date) >= 2015
GROUP BY transaction_year;

-- druga wersja zapytania z CTE:
WITH sub1 
AS
-- wybierz typ rachunku ROR i właściciela Janusz i Grażynka
(
SELECT * 
  FROM expense_tracker.transaction_bank_accounts tba 
  JOIN (SELECT *
          FROM expense_tracker.bank_account_owner bao 
         WHERE bao.owner_name = 'Janusz i Grażynka') jg ON tba.id_ba_own = jg.id_ba_own
  JOIN (SELECT *
          FROM expense_tracker.bank_account_types bat 
         WHERE bat.ba_type = 'ROR - WSPÓLNY') jg_ror ON tba.id_ba_typ = jg_ror.id_ba_type
)
SELECT EXTRACT (YEAR FROM t.transaction_date) transaction_year,
       sum(t.transaction_value) yearly_transaction_value
    FROM expense_tracker.transactions t
    JOIN sub1 ON t.id_trans_ba = sub1.id_trans_ba
    JOIN (SELECT * 
            FROM expense_tracker.transaction_type tt 
           WHERE tt.transaction_type_name LIKE '%bciążenie%') sub2 ON t.id_trans_type = sub2.id_trans_type
           WHERE EXTRACT (YEAR FROM t.transaction_date) >= 2015
GROUP BY transaction_year;

-- poprawiona wersja:

WITH common_spendings AS (
	SELECT EXTRACT(YEAR FROM t.transaction_date) AS transaction_year,
	       sum(t.transaction_value) AS yearly_transaction_value
	  FROM expense_tracker.transactions t
	  JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat 
	  JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba
	  JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own 
	  JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = tba.id_ba_typ 
	  											 AND bat.id_ba_own = bao.id_ba_own 
	  											 AND bat.ba_type = 'ROR - WSPÓLNY'
	  JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
	                                          AND tt.transaction_type_name = 'Obciążenie'
     WHERE EXTRACT(YEAR FROM t.transaction_date) >= 2015
     GROUP BY transaction_year
) SELECT *,
         (yearly_transaction_value - prev_year_spend)*(-1) AS increase_of_spend_yoy
    FROM (
    	  SELECT *,
    		     lag(yearly_transaction_value) OVER (ORDER BY transaction_year) AS prev_year_spend
    	    FROM common_spendings 
    	 ) sq;
  

-- 5. Korzystając z funkcji LAST_VALUE pokaż różnicę w dniach, pomiędzy kolejnymi
--    transakcjami (Obciążenie) na prywatnym koncie Janusza (RoR) dla podkategorii
--    Technologie w 1 kwartale roku 2020.

SELECT t.id_transaction,
	 t.transaction_date,	
	 t.transaction_date - last_value(t.transaction_date) 
	 					   		OVER (ORDER BY t.transaction_date ASC
	 			                      GROUPS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS days_from_prev_purchase
  FROM expense_tracker.transactions t
  JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba
  													AND tba.bank_account_name = 'ROR - Janusz'
  JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
  JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_subcat = t.id_trans_subcat
  												 AND ts.subcategory_description = 'Technologie';
 	--WHERE t.transaction_date BETWEEN '2020-01-01' AND '2020-03-31' - w tym kwartale mam tylko 1 rekord, dlatego wziąłem dane dla całego zakresu

-- poprawione rozwiązanie:
SELECT t.id_transaction,
		  t.transaction_date,
		  LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date GROUPS BETWEEN CURRENT ROW 
   																					  AND 1 FOLLOWING) AS next_technology_transaction,		  
		  LAST_VALUE(t.transaction_date) OVER (ORDER BY t.transaction_date GROUPS BETWEEN CURRENT ROW 
   																					  AND 1 FOLLOWING)
			-
			 t.transaction_date AS days_since_previous_tech_purchase,
		  t.transaction_value,		  
		  t.transaction_description
     FROM expense_tracker.transactions t 
     JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
     JOIN expense_tracker.transaction_subcategory ts ON ts.id_trans_cat = tc.id_trans_cat 
	 												AND ts.id_trans_subcat = t.id_trans_subcat 
     												AND ts.subcategory_name = 'Technologie'
 	 JOIN expense_tracker.transaction_bank_accounts tba ON tba.id_trans_ba = t.id_trans_ba 	 
 	 JOIN expense_tracker.bank_account_owner bao ON bao.id_ba_own = tba.id_ba_own 
	 JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = tba.id_ba_typ 
	 										    AND bat.id_ba_own = bao.id_ba_own 
	 										    AND bat.ba_type = 'ROR'
	 JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type 
	 										 AND tt.transaction_type_name = 'Obciążenie'
 	 JOIN expense_tracker.users u ON u.id_user = bao.user_login 
	 						     AND u.user_login = 'jkowalski'	 										 
    WHERE extract(YEAR FROM t.transaction_date) = 2020	
      AND extract(quarter FROM t.transaction_date) = 1
 	