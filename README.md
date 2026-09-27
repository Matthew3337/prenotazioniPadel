# 🏓 prenotazioniPadel

A full-stack mobile application for booking padel courts, built with **Flutter** on the frontend and **Spring Boot** on the backend. Designed with a clean, scalable architecture and deployed with a fully automated CI/CD pipeline.

> Backend repository: [serverPadel](https://github.com/Matthew3337/serverPadel)

## ✨ Features

- 🔐 User registration and authentication
- 📅 Browse and book available padel court time slots
- 🧑‍🤝‍🧑 User profile with skill level tracking
- 🔔 Push notifications for booking confirmations *(in progress, via Firebase Cloud Messaging)*
- 🔄 Real-time sync between app and backend via REST APIs

## 🏗️ Architecture

The app follows **Clean Architecture** principles, separating the codebase into clear layers:

```
lib/
├── presentation/     # UI, widgets, BLoC state management
├── domain/           # Business logic, entities, repository interfaces
├── data/             # Repository implementations, API clients, models
└── core/             # Dependency injection, config, shared utilities
```

- **State management:** [BLoC](https://bloclibrary.dev/) pattern for predictable, testable state
- **Dependency injection:** [GetIt](https://pub.dev/packages/get_it), wired up in `injection_container.dart`
- **API configuration:** environment URLs managed via a JSON config, registered as a singleton in GetIt

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter, Dart |
| State management | BLoC |
| Dependency injection | GetIt |
| Backend | Spring Boot (Java) |
| Database | MySQL |
| Deployment | Oracle Cloud VM |
| CI/CD | GitHub Actions → Docker build → GitHub Container Registry → automated SSH deploy |

## 🚀 CI/CD Pipeline

Every push to the backend triggers an automated pipeline:
1. Build a Docker image of the Spring Boot backend
2. Push the image to GitHub Container Registry
3. Deploy automatically to the Oracle Cloud VM via SSH

## 📦 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- A running instance of the [serverPadel](https://github.com/Matthew3337/serverPadel) backend

### Installation
```bash
git clone https://github.com/Matthew3337/prenotazioniPadel.git
cd prenotazioniPadel
flutter pub get
flutter run
```

Update the API base URL in the JSON config file to point to your backend instance.

## 🗺️ Roadmap

- [ ] Firebase Cloud Messaging push notifications
- [ ] Payment integration
- [ ] Match/partner finder based on skill level

## 📄 License

This project is for educational and portfolio purposes.
