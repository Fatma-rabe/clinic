# OrthoClinic Pro

Production-ready **Flutter** clinic management system for an orthopedic surgeon practice. Serverless backend on **Firebase** (Auth, Firestore, Storage).

## State management

**Riverpod 2** — compile-safe providers, first-class `StreamProvider` for Firestore realtime queues and financial summaries.

## Architecture (feature-first)

```
lib/
├── main.dart / app.dart
├── core/           # theme, router, constants, Firebase init, image compression
├── data/           # models, repositories, aggregation services
└── features/
    ├── auth/
    ├── reception/  # registration, payments, expenses
    ├── doctor/     # queue, consultation, X-ray, print
    ├── finance/    # PIN-gated dashboard
    └── shared/     # live queue panel
```

## Platforms

- Web (`flutter run -d chrome`)
- Windows (`flutter run -d windows`)

## Setup

See [docs/FIREBASE_SETUP_CHECKLIST.md](docs/FIREBASE_SETUP_CHECKLIST.md).

```bash
flutterfire configure
flutter pub get
flutter run -d windows
```

## Security

- Firestore & Storage rules: `firebase/`
- Doctor financial dashboard access is role-checked at runtime for `doctor` users.

## Workflow

1. **Reception**: Register patient → Payment (cash) → Invoice + Visit → Live queue
2. **Doctor**: Realtime queue → Consultation → X-ray upload (compressed) → Prescription print
3. **Finance**: Doctor-only access → Revenue / expenses / net profit / peak days
