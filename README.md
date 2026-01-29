# Mudra Manager 💸

Mudra Manager is a powerful, modern personal finance management application built with Flutter. It helps users track their expenses, manage budgets, and automatically import transactions from SMS messages, providing a seamless financial tracking experience.

## ✨ Features

-   **📊 Dashboard & Insights**: A comprehensive overview of your financial health with real-time updates.
-   **📩 SMS Transaction Tracking**: Automatically detect and parse financial transactions from bank/wallet SMS messages.
-   **💰 Budget Management**: Set up monthly budgets and stay on top of your spending.
-   **📈 Detailed Statistics**: Visualize your spending habits with beautiful, interactive charts and reports.
-   **📋 Transaction History**: Search, filter, and manage your income, expenses, and transfers.
-   **🌐 Localizations**: Full support for multiple languages.
-   **🔒 Secure & Private**: Local-first architecture using a high-performance local database. Optional biometric authentication.
-   **🎨 Premium Design**: A sleek, modern UI with support for dynamic themes and animations.
-   **📄 Export Reports**: Export your financial data to Excel or PDF formats.

## 🚀 Tech Stack

-   **Frontend**: [Flutter](https://flutter.dev/) (3.7.2+)
-   **State Management**: [Riverpod](https://riverpod.dev/)
-   **Database**: [Isar](https://isar.dev/) (high-performance local NoSQL database)
-   **UI Components**: [Google Fonts](https://fonts.google.com/), [Flutter Animate](https://pub.dev/packages/flutter_animate), [FL Chart](https://pub.dev/packages/fl_chart)
-   **System Integrations**: Telephony (SMS processing), Local Auth (Biometrics), Permission Handler, Local Notifications

## 🛠 Prerequisites

Ensure you have the following installed:

-   [Flutter SDK](https://docs.flutter.dev/get-started/install)
-   [Dart SDK](https://dart.dev/get-started)
-   Android Studio / Xcode (for mobile development)

## 📥 Installation & Setup

1.  **Clone the repository**:
    ```bash
    git clone <repository_url>
    cd mudra_manager
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run Code Generation** (for Isar and other generators):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Launch the app**:
    ```bash
    flutter run
    ```

## 📂 Project Structure

-   `lib/db`: Database schemas and services.
-   `lib/l10n`: Application localizations (ARB files).
-   `lib/providers`: State management logic using Riverpod.
-   `lib/screens`: UI screens and feature modules.
-   `lib/service`: Background services and SMS processing.
-   `lib/theme`: App theme and design system.
-   `lib/util`: Helper functions and utility classes.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is for private use only (as specified in `pubspec.yaml`).
