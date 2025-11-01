# Kalkulator Szkła - System Zarządzania Wysyłkami

Aplikacja desktopowa stworzona dla firmy Różycki GLASS do szybkiego i wygodnego liczenia parametrów wysyłkowych szkła do transportu. Projekt powstał w ramach praktycznego zastosowania umiejętności programistycznych w rzeczywistych warunkach biznesowych.

## 📋 O projekcie

Kalkulator Szkła to aplikacja stworzona z myślą o optymalizacji procesu przygotowywania dokumentacji wysyłkowej w firmie zajmującej się obróbką szkła. Program umożliwia szybkie obliczanie parametrów technicznych zamówień, generowanie dokumentów PDF oraz eksport danych do formatu Excel.

Jest to projekt stworzony dla firmy w celu szybkiego i wygodnego liczenia parametrów wysyłkowych szkła do transportu. Aplikacja działa w pełni lokalnie, bez połączenia z internetem, co zapewnia bezpieczeństwo danych firmowych.

## 🔑 Licencja i Prawa

**Oprogramowanie jest w pełni legalnie stworzone przeze mnie, posiadam do niego pełne prawa autorskie i mogę je udostępniać publicznie.** Każdy może z niego korzystać, modyfikować i dystrybuować zgodnie z własnymi potrzebami. Projekt jest udostępniony jako open-source.

## ✨ Funkcjonalności

### Główne możliwości:

- **Obliczenia parametrów szkła** - automatyczne wyliczanie powierzchni (m²), wagi i kosztów na podstawie wymiarów
- **Zarządzanie projektami** - tworzenie, zapisywanie i wczytywanie wielu projektów
- **Historia projektów** - przeglądanie wcześniej utworzonych kalkulacji
- **Generowanie PDF** - automatyczne tworzenie profesjonalnych dokumentów WZ (Wydanie Zewnętrzne)
- **Eksport do Excel** - eksport danych do arkusza kalkulacyjnego z formatowaniem
- **Zestawienia zbiorcze** - automatyczne grupowanie według grubości szkła
- **Konfiguracja danych firmowych** - możliwość dostosowania danych sprzedawcy i odbiorcy
- **Autozapis** - automatyczne zapisywanie pracy co minutę
- **Praca offline** - aplikacja działa w pełni lokalnie, bez połączenia z internetem

### Szczegółowe funkcje:

#### 📊 Kalkulator

- Wprowadzanie parametrów: grubość, długość, szerokość, ilość sztuk
- Automatyczne obliczanie:
  - Powierzchni pojedynczej tafli (m²/szt)
  - Całkowitej powierzchni (m²)
  - Wagi (kg) - na podstawie współczynnika 2.5 kg/m²/mm grubości
  - Kosztu - na podstawie konfigurowalnej ceny za tonę

#### 📝 Zestawienia

- Grupowanie pozycji według grubości szkła
- Automatyczne sumowanie ilości, powierzchni i wagi
- Przejrzyste prezentowanie danych w formie tabelarycznej

#### 💰 Konfiguracja kosztów

- Ustawianie ceny za tonę szkła
- Podgląd całkowitych kosztów transportu
- Natychmiastowe przeliczanie przy zmianie parametrów

#### 🏢 Dane firmowe

- Pełna konfiguracja danych sprzedawcy (Twojej firmy)
- Dane odbiorcy (klienta/hartowni)
- Informacje o dokumencie (numer bieżący, data wystawienia)
- Rodzaj usługi (np. "Hartowanie szkła")

#### 📄 Eksport dokumentów

- **PDF** - profesjonalny dokument WZ z kompletną tabelą i danymi firmowymi
- **Excel** - szczegółowy arkusz kalkulacyjny z formatowaniem i stylizacją
- Automatyczne nazewnictwo plików: `[Nazwa klienta]-[Data].[rozszerzenie]`
- Konfigurowalna ścieżka zapisu dokumentów

## 🛠️ Technologie

Projekt został zbudowany przy użyciu:

- **Flutter 3.5.3** - framework do tworzenia aplikacji wieloplatformowych
- **Dart** - język programowania

### Wykorzystane biblioteki:

- `pdf` (3.11.3) - generowanie dokumentów PDF
- `excel` (4.0.6) - tworzenie plików Excel
- `shared_preferences` (2.5.3) - lokalne przechowywanie danych
- `path_provider` (2.1.5) - zarządzanie ścieżkami plików
- `intl` (0.20.2) - formatowanie dat i liczb
- `printing` (5.14.2) - obsługa wydruku i zapisu PDF

## 📦 Instalacja i uruchomienie

### Wymagania wstępne:

- Flutter SDK w wersji 3.5.3 lub nowszej
- Dart SDK
- System operacyjny: Windows, Linux lub macOS

### Kroki instalacji:

1. Sklonuj repozytorium:

```bash
git clone https://github.com/GKacperG2/KalkulatorSzkla.git
cd KalkulatorSzkla/kal2
```

2. Pobierz zależności:

```bash
flutter pub get
```

3. Uruchom aplikację:

```bash
flutter run -d windows
```

(lub `-d linux` / `-d macos` w zależności od systemu)

4. Zbuduj wersję produkcyjną:

```bash
flutter build windows --release
```

## 📸 Zrzuty ekranu

Aplikacja składa się z 6 głównych zakładek:

1. **Kalkulator** - wprowadzanie danych i obliczenia
2. **Zestawienie** - zbiorcze grupowanie według grubości
3. **Koszt** - zarządzanie cenami i kosztami
4. **Dane** - konfiguracja danych firmowych
5. **Historia** - przeglądanie zapisanych projektów
6. **Ustawienia** - konfiguracja ścieżek zapisu

## 🚀 Korzystanie z aplikacji

### Podstawowy workflow:

1. **Stwórz nowy projekt** - kliknij przycisk "Nowy projekt" i nadaj mu nazwę
2. **Dodaj pozycje** - wprowadź parametry szkła (grubość, wymiary, ilość)
3. **Skonfiguruj dane** - przejdź do zakładki "Dane" i uzupełnij informacje o kliencie
4. **Sprawdź zestawienie** - w zakładce "Zestawienie" zobacz podsumowanie
5. **Wygeneruj dokumenty** - użyj przycisków "Generuj PDF" lub "Generuj Excel"
6. **Projekt zapisuje się automatycznie** - co minutę i przy każdej zmianie

### Skróty klawiszowe:

- **Spacja** - dodanie nowej pozycji w kalkulatorze
- **Strzałki** - nawigacja między polami tabeli (w trakcie implementacji)

## 📋 Struktura projektu

```
kal2/
├── lib/
│   └── main.dart              # Główny plik aplikacji
├── assets/
│   └── fonts/
│       └── DejaVuSans.ttf    # Czcionka do PDF (obsługa polskich znaków)
├── android/                   # Konfiguracja Android
├── windows/                   # Konfiguracja Windows
├── linux/                     # Konfiguracja Linux
├── macos/                     # Konfiguracja macOS
└── pubspec.yaml              # Zależności projektu
```

## 🔐 Bezpieczeństwo i Prywatność

- **Aplikacja działa w pełni lokalnie** - wszystkie dane są przechowywane wyłącznie na Twoim komputerze
- **Brak połączenia z internetem** - żadne dane nie są wysyłane na zewnętrzne serwery
- **Pełna kontrola nad danymi** - dokumenty zapisywane są w wybranym przez użytkownika folderze
- **Bezpieczne przechowywanie** - dane projektów zapisywane lokalnie przy użyciu `shared_preferences`

## 🤝 Wkład w projekt

Projekt jest otwarty na propozycje zmian i ulepszenia. Jeśli chcesz przyczynić się do rozwoju:

1. Forkuj repozytorium
2. Stwórz branch z nową funkcjonalnością (`git checkout -b feature/NowaFunkcja`)
3. Commituj zmiany (`git commit -m 'Dodanie nowej funkcji'`)
4. Wypchnij branch (`git push origin feature/NowaFunkcja`)
5. Otwórz Pull Request

## 📝 Historia zmian

### v1.0.0 (2024)

- Pierwsza wersja aplikacji
- Podstawowe funkcje kalkulacji
- Generowanie PDF i Excel
- System zarządzania projektami
- Autozapis
- Pełna lokalizacja polska

## 🎯 Roadmap (planowane funkcje)

- [ ] Obsługa szablonów dla różnych klientów
- [ ] Import danych z plików Excel
- [ ] Rozszerzona nawigacja klawiaturą
- [ ] Eksport do dodatkowych formatów (CSV, JSON)
- [ ] Motywy kolorystyczne (jasny/ciemny)
- [ ] Statystyki i raporty miesięczne
- [ ] Obsługa wielu walut

## 👨‍💻 Autor

Projekt stworzony przez studenta informatyki III roku jako praktyczne rozwiązanie dla rzeczywistego problemu biznesowego.

## 📧 Kontakt

W razie pytań lub sugestii dotyczących projektu, zapraszam do kontaktu poprzez Issues na GitHubie.

## ⚖️ Licencja

Projekt jest udostępniony jako open-source. Każdy może z niego swobodnie korzystać, modyfikować i dystrybuować. Oprogramowanie jest w pełni legalnie stworzone przez autora, który posiada pełne prawa autorskie.

---

**Uwaga:** Aplikacja została stworzona z myślą o firmie Różycki GLASS, ale może być łatwo dostosowana do potrzeb innych przedsiębiorstw z branży szklarskiej.
