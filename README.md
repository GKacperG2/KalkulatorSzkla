<div align="center">

# 🪟 Glass Calculator & Shipment Manager

_Professional desktop application for glass‑industry logistics_

[![Flutter](https://img.shields.io/badge/Flutter-3.5.3-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.3-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Open%20Source-success?style=for-the-badge)](LICENSE)
[![Made%20with%20Love](https://img.shields.io/badge/Made%20with-Love-red?style=for-the-badge&logo=heart)](https://github.com/GKacperG2/KalkulatorSzkla)
[![Offline%20First](https://img.shields.io/badge/100%25-Offline-orange?style=for-the-badge&logo=wifi)](README.md)

**Developed by:**  
<a href="https://github.com/GKacperG2"><img src="https://img.shields.io/badge/Kacper%20Gorzkiewicz-✏️-blue?style=for-the-badge" /></a>
<a href="https://github.com/GKacperG2"><img src="https://img.shields.io/badge/Paweł%20Gałusza-✏️-blue?style=for-the-badge" /></a>

_3rd‑year Computer Science students_

[GitHub](https://github.com/GKacperG2/KalkulatorSzkla) •
[Report Bug](https://github.com/GKacperG2/KalkulatorSzkla/issues) •
[Request Feature](https://github.com/GKacperG2/KalkulatorSzkla/issues)

</div>

---

## 📖 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Usage Guide](#-usage-guide)
- [Project Structure](#-project-structure)
- [Security & Privacy](#-security--privacy)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Authors](#-authors)
- [Contact & Support](#-contact--support)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 About the Project

**Glass Calculator** is a cross‑platform desktop application created for **Różycki GLASS**.  
It automates the calculation of glass‑transport parameters, generates professional PDF and Excel reports, and stores all data locally, making it **100% offline‑first**.

The project serves as a **portfolio piece** that demonstrates:

- Real‑world business problem solving
- Advanced Flutter desktop development (Windows, macOS, Linux)
- State management, data persistence, and document generation
- Offline‑first architecture with full data privacy

---

## ✨ Key Features

| Feature                        | Description                                                                                                  |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| **Smart Calculations**         | Area, weight (2.5 kg / m² / mm) and cost are computed automatically with 3‑decimal precision.                |
| **Multi‑Project Handling**     | Create, rename, switch, and browse any number of projects. Auto‑save every minute.                           |
| **Document Generation**        | One‑click PDF (WZ) and Excel export with company headers, Polish character support, and print‑ready layouts. |
| **Configurable Cost Settings** | Set price per ton, custom save paths, and instant cost recalculation.                                        |
| **Company Data Management**    | Store seller, client, and document metadata locally.                                                         |
| **Offline‑First**              | No internet connection, no external APIs – all data stays on the user's machine.                             |
| **Cross‑Platform UI**          | Material Design, responsive layout for Windows, macOS, and Linux.                                            |

---

## 🛠️ Tech Stack

| Layer                    | Technology                                     |
| ------------------------ | ---------------------------------------------- |
| **Framework**            | Flutter 3.5.3                                  |
| **Language**             | Dart 3.5.3                                     |
| **State Management**     | StatefulWidget + manual setState (lightweight) |
| **Persistence**          | `shared_preferences` (JSON)                    |
| **File System**          | `path_provider`                                |
| **PDF Generation**       | `pdf` 3.11.3, `printing` 5.14.2                |
| **Excel Generation**     | `excel` 4.0.6                                  |
| **Internationalisation** | `intl` 0.20.2                                  |
| **UI**                   | Material Design components                     |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.5.3 (including the desktop toolchain)
- **Dart SDK** ≥ 3.5.3 (bundled with Flutter)
- **Git**
- An IDE (VS Code, Android Studio, IntelliJ IDEA)

### Installation

```bash
# Clone the repository
git clone https://github.com/GKacperG2/KalkulatorSzkla.git
cd KalkulatorSzkla/kal2

# Install Dart/Flutter dependencies
flutter pub get

# Verify the Flutter setup
flutter doctor
```

### Running the App

```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

#### Building for Production

```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

The compiled executable can be found in `build/<platform>/.../Release/`.

---

## 📱 Usage Guide

1. **Create a new project** – click **„Nowy projekt"** and give it a name.
2. **Add glass items** – specify thickness (mm), length (mm), width (mm) and quantity. All calculations update instantly.
3. **Configure company data** – fill seller and client information on the **„Dane"** tab.
4. **Review the summary** – the **„Zestawienie"** tab groups items by thickness and shows totals (quantity, area, weight, cost).
5. **Generate documents** – press **„Generuj PDF"** or **„Generuj Excel"**. Files are saved as `[ClientName]-[yyyyMMdd].[pdf|xlsx]` in the folder you selected in **„Ustawienia"**.

### Keyboard shortcuts

| Key                | Action                                |
| ------------------ | ------------------------------------- |
| <kbd>Space</kbd>   | Add a new glass row                   |
| <kbd>← → ↑ ↓</kbd> | Navigate cells in the table (partial) |

---

## 📂 Project Structure

```
kal2/
├─ lib/
│  ├─ models/
│  │   ├─ glass_item.dart          # Glass piece data
│  │   ├─ company_data.dart        # Seller / client data
│  │   └─ project.dart             # Project container
│  ├─ screens/
│  │   ├─ main_screen.dart
│  │   ├─ calculator_tab.dart
│  │   ├─ summary_tab.dart
│  │   ├─ cost_tab.dart
│  │   ├─ data_tab.dart
│  │   ├─ history_tab.dart
│  │   └─ settings_tab.dart
│  └─ utils/
│      ├─ pdf_generator.dart
│      └─ excel_generator.dart
├─ assets/
│   └─ fonts/DejaVuSans.ttf        # Polish characters in PDFs
├─ windows/  linux/  macos/        # Desktop build configs
├─ pubspec.yaml                    # Dependencies & assets
└─ README.md
```

---

## 🔐 Security & Privacy

- **100% offline** – the app never contacts the internet.
- **Local storage only** – all data is kept in the user's profile directory via `shared_preferences`.
- **No analytics / telemetry** – nothing is sent to external services.
- **User‑controlled exports** – you decide where PDFs/Excel files are saved.

---

## 🗺️ Roadmap

- [ ] Template system for reusable client configurations
- [ ] Import data from existing Excel files
- [ ] Dark/light theme toggle
- [ ] Multi‑currency support & automatic conversion
- [ ] Batch document generation for several projects at once
- [ ] Advanced filtering & search in project history
- [ ] Export to CSV & JSON formats
- [ ] Comprehensive keyboard navigation (full support)

---

## 🤝 Contributing

Contributions are welcome! Follow these steps:

1. **Fork** the repository
2. **Create a feature branch**
   ```bash
   git checkout -b feature/awesome-feature
   ```
3. **Commit** your changes
   ```bash
   git commit -m "Add awesome feature"
   ```
4. **Push** the branch
   ```bash
   git push origin feature/awesome-feature
   ```
5. **Open a Pull Request** on the original repo

### Guidelines

- Respect Dart & Flutter style guides (`flutter format` & `flutter analyze`).
- Write clear commit messages.
- Update the README if you add user‑visible functionality.
- Test on at least one desktop platform (Windows/macOS/Linux).

---

## ⚖️ License

This project is **open‑source** and released under the **MIT License**. See the [LICENSE](LICENSE) file for full details.

You are free to:

- Use the software for personal or commercial purposes
- Modify, distribute, and sublicense the code
- Contribute improvements back to the project

No warranty is provided; use at your own risk.

---

## 👨‍💻 Authors

<div align="center">

<a href="https://github.com/GKacperG2">
  <img src="https://avatars.githubusercontent.com/u/XXXXX?s=100" width="100" alt="Kacper Gorzkiewicz"/>
  <p>Kacper Gorzkiewicz</p>
</a>
&nbsp;&nbsp;
<a href="https://github.com/GKacperG2">
  <img src="https://avatars.githubusercontent.com/u/YYYYY?s=100" width="100" alt="Paweł Gałusza"/>
  <p>Paweł Gałusza</p>
</a>

_Computer Science Students – 3rd Year_

[GitHub Profiles](https://github.com/GKacperG2)

</div>

---

## 📞 Contact & Support

- **Bug reports & feature requests** – [GitHub Issues](https://github.com/GKacperG2/KalkulatorSzkla/issues)
- **Pull requests** – [GitHub PRs](https://github.com/GKacperG2/KalkulatorSzkla/pulls)

---

## 🌟 Acknowledgments

- **Różycki GLASS** – for providing real‑world requirements and test data.
- **Flutter Team** – for the powerful cross‑platform framework.
- **Open‑source community** – for the packages (`pdf`, `excel`, `shared_preferences`, …) that make this project possible.

<div align="center">

**Made with ❤️ by Computer Science Students**

If you find this project useful, please give it a ⭐!

</div>
