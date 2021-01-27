-- 1. Oblicz sumę transakcji w podziale na kategorie transakcji. W wyniku wyświetl nazwę
--    kategorii i całkowitą sumę.

   SELECT tc.category_name,
          sum(t.transaction_value) total_expenses
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc  ON tc.id_trans_cat = t.id_trans_cat
 GROUP BY tc.category_name;

-- 2. Oblicz sumę wydatków na Używki dokonana przez Janusza (Janusz Kowalski) z jego
--    konta prywatnego (ROR - Janusz) w obecnym roku 2020.
SELECT * FROM expense_tracker.transaction_category tc;
SELECT * FROM expense_tracker.bank_account_types;
SELECT * FROM expense_tracker.users;

SELECT * 
FROM expense_tracker.bank_account_types bat 
JOIN expense_tracker.users u ON u.id_user = bat.id_ba_own
AND u.user_name = 'Janusz Kowalski'
AND bat.ba_type = 'ROR';

SELECT *
FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
                                                 WHERE tc.category_name = 'UŻYWKI';

WITH uzywki_exp AS (
                       SELECT *
                         FROM expense_tracker.transactions t 
                    LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
                        WHERE tc.category_name = 'UŻYWKI'
                   ),
     janusz_ror AS (
                    SELECT * 
                      FROM expense_tracker.bank_account_types bat 
                      JOIN expense_tracker.users u ON u.id_user = bat.id_ba_own
                                                  AND u.user_name = 'Janusz Kowalski'
                                                  AND bat.ba_type = 'ROR')
SELECT uzywki_exp.*
FROM uzywki_exp
JOIN janusz_ror ON janusz_ror.id_trans_ba = ue.id_trans_ba;

-- 3. Stwórz zapytanie, które będzie podsumowywać wydatki (typ transakcji: Obciążenie) na
--    wspólnym koncie RoR - Janusza i Grażynki w taki sposób, aby widoczny był podział
--    sumy wydatków, ze względu na rok, rok i kwartał (format: 2019_1), rok i miesiąc (format:
--    2019_12) w roku 2019. Skorzystaj z funkcji ROLLUP.
-- 4. Stwórz zapytanie podsumowujące sumę wydatków na koncie wspólnym Janusza i
--    Grażynki (ROR- Wspólny), wydatki (typ: Obciążenie), w podziale na poszczególne lata
--    od roku 2015 wzwyż. Do wyników (rok, suma wydatków) dodaj korzystając z funkcji
--    okna atrybut, który będzie różnicą pomiędzy danym rokiem a poprzednim (balans rok
--    do roku).