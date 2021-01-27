-- 1. Oblicz sumę transakcji w podziale na kategorie transakcji. W wyniku wyświetl nazwę
--    kategorii i całkowitą sumę.

   SELECT tc.category_name,
          sum(t.transaction_value) total_expenses
     FROM expense_tracker.transactions t 
LEFT JOIN expense_tracker.transaction_category tc  ON tc.id_trans_cat = t.id_trans_cat
 GROUP BY tc.category_name;

-- 2. Oblicz sumę wydatków na Używki dokonana przez Janusza (Janusz Kowalski) z jego
--    konta prywatnego (ROR - Janusz) w obecnym roku 2020.
WITH uzywki_exp AS (
                       SELECT *
                         FROM expense_tracker.transactions t 
                    LEFT JOIN expense_tracker.transaction_category tc ON tc.id_trans_cat = t.id_trans_cat
                        WHERE tc.category_name = 'UŻYWKI' AND EXTRACT(YEAR FROM t.transaction_date) = 2020 
                   ),
     janusz_ror AS (
                    SELECT * 
                      FROM expense_tracker.bank_account_types bat 
                      JOIN expense_tracker.users u ON u.id_user = bat.id_ba_own
                                                  AND u.user_name = 'Janusz Kowalski'
                                                  AND bat.ba_type = 'ROR'
                   )
SELECT sum(ue.transaction_value)
FROM uzywki_exp ue
JOIN janusz_ror ON janusz_ror.id_ba_type = ue.id_trans_ba;

-- 3. Stwórz zapytanie, które będzie podsumowywać wydatki (typ transakcji: Obciążenie) na
--    wspólnym koncie RoR - Janusza i Grażynki w taki sposób, aby widoczny był podział
--    sumy wydatków, ze względu na rok, rok i kwartał (format: 2019_1), rok i miesiąc (format:
--    2019_12) w roku 2019. Skorzystaj z funkcji ROLLUP.

SELECT * FROM expense_tracker.transactions;
SELECT * FROM expense_tracker.bank_account_owner bao;

   SELECT sum(t.transaction_value)
     FROM expense_tracker.transactions t 
     JOIN expense_tracker.bank_account_types bat ON bat.id_ba_type = t.id_trans_ba
LEFT JOIN expense_tracker.transaction_type tt ON tt.id_trans_type = t.id_trans_type
    WHERE tt.transaction_type_name = 'Obciążenie'
      AND bat.id_ba_type = 6; -- jak zastapic to dodatkowym joinem?

-- 4. Stwórz zapytanie podsumowujące sumę wydatków na koncie wspólnym Janusza i
--    Grażynki (ROR- Wspólny), wydatki (typ: Obciążenie), w podziale na poszczególne lata
--    od roku 2015 wzwyż. Do wyników (rok, suma wydatków) dodaj korzystając z funkcji
--    okna atrybut, który będzie różnicą pomiędzy danym rokiem a poprzednim (balans rok
--    do roku).