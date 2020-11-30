# Moduł 6 projekt

![Modu%C5%82%206%20projekt%20f4c8508a58014e18ad0aac1dbee0687b/Untitled.png](Modu%C5%82%206%20projekt%20f4c8508a58014e18ad0aac1dbee0687b/Untitled.png)

- nie wiem czy dobrze rozumiem przeznaczenie tej tabeli, ale czy **transaction_bank_accounts** jest taką "tabelą pośrednią", której celem jest przechowywanie info o typie konta i jego właścicielu? Jeśli tak, to czy atrybut *bank_account_desc* nie jest powieleniem tej samej informacji, którą przechowujemy w *ba_desc* w tabeli **bank_account_types?**
- czy tabela **users** i **bank_account_owner** nie powinny być bezpośrednio połączone jakąś relacją many-to-many (jedno konto może mieć kilkoro userów oraz jeden user wiele kont)? Atrybut *user_login* w tabeli **users** jest typu char, a w tabeli **bank_account_owner** typu int - przy łączeniu tabel trzeba ujednolicić typ tej zmiennej (a może i bez łączenia należy to zrobić?)
- wydaje mi się, że tabele **transactions_subcategory** i **transaction_category** powinny być połączone relacją many-to-many tak, żeby
    - wiele różnych transakcji mogło należeć do tej samej kategorii i subkategorii,
    - dało się w miarę elastycznie dzielić kategorie (np. żeby podkategoria "gry na playstation" mogła należeć jednocześnie do kategorii "prezenty" jak i "artykuły pierwszej potrzeby" :)?

    Wydaje mi się, że do pierwszego z powyższych podpunktów może wystarczyć relacja one-to-many pomiędzy **transactions** a **transaction_category**, ale do podzielenia jednej transakcji na kilka (pod)kategorii potrzebujemy już many-to-many.

- czy celem atrybutu *active* w każdej tabeli jest informacja o tym, że konto, którego właścicielem był user bądź sam user przestał być klientem? Pytanie wynika stąd, że nie umiem zrozumieć jaką informację powinien nieść ten atrybut w tabeli typu **transaction_type :)**
- czy fakt, że nigdzie nie przechowujemy aktualnego stanu konta to celowy zabieg? Teoretycznie możemy obliczać go na bieżąco na podstawie historii transakcji, ale wydajność tego rozwiązania będzie spadać wraz z wzrastającą liczbą transakcji.