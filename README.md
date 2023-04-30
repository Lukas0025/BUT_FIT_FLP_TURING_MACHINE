# BUT FIT FLP TURING MACHINE
## Implementace Nedeterministického Turingova stroje v Prologu
##### Autor: Lukáš Plevač <xpleva07>
##### Akademický rok: 2022/2023
##### Zadání: Turingův stroj

### Kompilace
Program zkompilujeme pomocí Makefile s cílem flp22-log

```sh
make flp22-log
# nebo
make
```

### Spuštení
Program očekává jden parametr kterým je cesta k souboru s providly a vstupní páskou, pokud nebude tento paremetr uveden bude číst z stdin tento soubor

```sh
./flp22-log < <rules file>
# nebo 
./flp22-log <rules file>
```

soubor s pavidly má formát `<Stav> <Znak pod havou> <Nový stav> <Nový symbol>`, kde nový symbol můžebýt symbol z páskové abecedy nebo znak `L` posun hlavy v levo a `R` posun hlavy v pravo. Stavy jsou psány velkýmy písmeny a pásková abeceda je složená z malých ascii zanků, podle zadání, nicméně implementace toto nevyžaduje a není to nutné dodržovat až na vajímku `L` a `R` v páskové abecedě.

ukázka vtupního souboru:
```txt
S   S R
S a S R
S b S R
S n S  
S . F R
abbbababab babbab ab aba na nnnaaa nbbn. 
```

### Ukázkový výstup

Ukázkový výstup testu 15 řešící XOR dvou binárních čísel (výsledek je zapsán v opačném pořadí znaků)

Pro README upravano na XOR BIN čísel 1 a 0

```txt
S 1.0.
 A1.0.
 I-.0.
 -I.0.
 -.J0.
 -.E-.
 -.-E.
 -.-.H
 -.-.O1
 -.-O.1
 -.O-.1
 -O.-.1
 O-.-.1
O -.-.1
S -.-.1
 Z-.-.1
 F-.-.1
```

### Implementace
Při spuštení programu dojde k načtení vstupního souboru, ze kterého se načtou pravidla a pomocí `assert` se uloží do databáze axiomů, páska je uložena do proměné se kterou je následně spuštěn turingův stroj. Turingův stroj je spuštěn opakovaně pomocí DLS prohledávací metody pro různý maximální počet kroků od 2 do 1000000, přičemž do 100 kroků se stoupá o +1 a pro více jak 100 kroků se násobý 10. Toto je uděláno aby se preferovaly kratší řešení pokud řešení je do malého počtu kroků pokud není je důležitější řešení najít. Samotný běh TS je zajištěn pomocí funkce stepsTM, která využívá vnitřní backtracking pro nalezení řešení. stepsTM definuje možné kroky TS které může provést a pokud jsou provedeny jak se změní páska, pozice hlavy a přidání konfigurace do výstupního seznamu konfigurací (Následné rekurzivní volání). Při tomto kroku se také dělá assert současné konfigurace za účelem detekce cyklů. Na začátku stepsTM se totiž detekuje zda došel počet kroků, nebo zda jsme nešly hlavou mimo pásku nebo zda jsme nedošly do konfigurace ve které jsme již byly pokud ano bude tato cesta označena jako fail a retractem se vrátí potřebné konfigurace přes které se vracíme, to samé se děje i pokud není možné provést krok. Pokud prolog najde nejaké řešení které nekončí fail, uloží současnou konfigutaci do seznamu konfigurací, tento seznam konfigurací se zpětně dosestavý vracením se z rekurze a vytiskne se na výstup, pokud se toto nepodaří vypíše chybovou hlásku a vrací nenulový kód.

### Spuštení s testovacímy vstupy

Testovací vstupy jsou umístěny ve složce `tests` a jsou v txt formátu spuštění tedy testu například 15 se provede následovně:

```sh
./flp22-log tests/15.txt
```

očekávané výstupy jsou v složce `testsExpected`

### Automatické testování

Součásti projektu je jednudechý script pro automatické testovaání který je spustitelný pomocí make s cílem test. Script spustí všechny testy ze složky tests a porovná výstupy s očekávanýmy výstupy testů.

```sh
make test
```

### Omezení

Program je omezen maximálním počtem kroků, které TS smí udělat, pokud by chtěl udělat víc bude detekováno cykletí. Pokud by bylo nutné je tento limit možné zvíšit v `runTM` sučasné maximum je `1 000 000` kroků. Program má také problém detekovat cykli pokud u kterých nedochází k opakování konfigurace například jít stále doprava v takovém případě může program počítat příliš dlouhodu dobu než řekne že není možné nalést řešení. Problematické budou také vtupy které budou umožňovat právě tento typ cyklení a zároveň cestu do cíle, nicméně pokud počet kroků pro nalezení řešení nebude příliš vysoký měl by program řešení nalézst dostatečně brzo.