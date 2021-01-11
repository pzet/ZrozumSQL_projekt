-- ##################################################
--                    MODUŁ 7
-- ##################################################

-- 1. Wyświetl wszystkie informacje o koncie:
--    * nazwa właścieciela (owner_name)
--    * opis właściciela (owner_desc)
--    * typ konta (ba_type)
--    * opis konta (ba_desc)
--    * flaga czy jest aktywne (active)
--    * nazwa konta bankowego (bank_account_name)
--    * razem z użytkownikiem (user_login),
--      który jest do niego przypisany. Dla właściciela, jakim jest Janusz Kowalski.

      SELECT bao.owner_name,
	         bao.owner_desc,
	         bat.ba_type,
	         bat.ba_desc,
	         bat.active,
	         tba.bank_account_name,
	         u.user_login
        FROM expense_tracker.bank_account_owner bao
  INNER JOIN expense_tracker.bank_account_types bat ON bao.id_ba_own = bat.id_ba_own
  INNER JOIN expense_tracker.transaction_bank_accounts tba ON bat.id_ba_own = tba.id_ba_own
  INNER JOIN expense_tracker.users u ON tba.id_ba_own = u.id_user
       WHERE owner_name = 'Janusz Kowalski' AND bat.active = '1';
 

-- 2. Wyświetl wszystkie informacje o dostępnych kategoriach transakcji i ich możliwych
--    podkategoriach.
--    W obu przypadkach powinny to być tylko "aktywne" elementy (active TRUE / 1 / Y / y :)).
--	  W wyniku wyświetl 2 atrybuty, nazwa kategorii i nazwa podkategorii, dane posortuj po
--	  identyfikatorze kategorii rosnąco.


   SELECT tc.id_trans_cat,
          tc.category_name, 
          ts.subcategory_name
     FROM expense_tracker.transaction_category tc
LEFT JOIN expense_tracker.transaction_subcategory ts ON tc.id_trans_cat = ts.id_trans_cat
    WHERE tc.active IN ('1', 'TRUE', 'Y', 'y')
      AND ts.active IN ('1', 'TRUE', 'Y', 'y')
 ORDER BY tc.id_trans_cat;


-- 3. Wyświetl wszystkie transakcje (TRANSACTIONS), które miały miejsce w 2016 roku
--    związane z kategorią JEDZENIE.

       SELECT *
         FROM expense_tracker.transactions t
    LEFT JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
        WHERE EXTRACT(YEAR FROM t.transaction_date) = 2016 
	     AND category_name = 'JEDZENIE';

-- 4. Dodaj nową podkategorię do tabeli TRANSACTION_SUBCATEGORY, która będzie w relacji
--    z kategorią (TRANSACTION_CATEGORY) JEDZENIE.
--    Na podstawie wyników z zadania 3, dla wszystkich wierszy z kategorii jedzenie, które nie
--    mają przypisanej podkategorii (-1) zaktualizuj wartość podkategorii na nową dodaną.
--    Możesz wykorzystać dowolną znaną Ci konstrukcję (UPDATE / UPDATE + WITH /
--    UPDATE + FROM / UPDATE + EXISTS).

-- dodaj nową podkategorię do kategorii jedzenie
INSERT INTO expense_tracker.transaction_subcategory (id_trans_cat, subcategory_name, subcategory_description)
     SELECT expense_tracker.transaction_category.id_trans_cat, 'Nowa podkategoria', 'Nowa podkategoria'
       FROM expense_tracker.transaction_category
      WHERE category_name = 'JEDZENIE';
     


-- rozwiązanie z CTE
WITH no_subcat AS 
	(
	   SELECT *
         FROM expense_tracker.transactions t
    LEFT JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat 
WHERE EXTRACT(YEAR FROM t.transaction_date) = 2016 
          AND category_name = 'JEDZENIE'
          AND id_trans_subcat = -1
	)
UPDATE expense_tracker.transactions ts
SET id_trans_subcat = (
                      SELECT id_trans_subcat 
 					    FROM expense_tracker.transaction_subcategory
 					   WHERE subcategory_name = 'Nowa podkategoria'
 					   )
WHERE EXISTS
     (
     SELECT *
       FROM no_subcat
      WHERE no_subcat.id_trans_subcat = ts.id_trans_subcat
     );


-- rozwiązanie bez CTE
UPDATE expense_tracker.transactions tr
   SET id_trans_subcat = (
				         SELECT id_trans_subcat 
 					       FROM expense_tracker.transaction_subcategory
 					      WHERE subcategory_name = 'Nowa podkategoria'
 					     )
 WHERE id_trans_subcat = -1;
-- https://stackoverflow.com/questions/36908495/update-with-result-from-cte-postgresql

   
-- 5. Wyświetl wszystkie transakcje w roku 2020 dla konta oszczędnościowego Janusz i
--    Grażynka.
--    W wynikach wyświetl informacje o:
--    * nazwie kategorii,
--    * nazwie podkategorii,
--    * typie transakcji,
--    * dacie transakcji
--    * wartości transakcji.


      WITH ror_JG AS
	   (
	   SELECT * 
	     FROM expense_tracker.bank_account_owner bao
	LEFT JOIN expense_tracker.transaction_bank_accounts tba ON bao.id_ba_own = tba.id_ba_own
	    WHERE owner_name = 'Janusz i Grażynka'
	      AND bank_account_name LIKE '%OSZCZ%'
	   )
    SELECT t.id_transaction,
    	   tc.category_name,
    	   ts.subcategory_name,
    	   tt.transaction_type_name,
    	   t.transaction_date,
    	   t.transaction_value 
      FROM expense_tracker.transactions t 
INNER JOIN ror_JG ON t.id_trans_ba = ror_JG.id_trans_ba
 LEFT JOIN expense_tracker.transaction_type tt ON t.id_trans_type = tt.id_trans_type
 LEFT JOIN expense_tracker.transaction_category tc ON t.id_trans_cat = tc.id_trans_cat
 LEFT JOIN expense_tracker.transaction_subcategory ts ON t.id_trans_subcat = ts.id_trans_subcat;
