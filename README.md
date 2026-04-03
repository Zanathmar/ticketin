# Ticketin — Flutter Mobile App

> Event discovery, registration, and QR-based check-in/out — powered by the **Ticketin Laravel REST API**.

---

## 📱 App Overview

Ticketin is a Flutter mobile application that lets users:

- **Browse & search events** — view all or upcoming events with real-time capacity indicators
- **Register for events** — one-tap registration that returns a unique QR ticket
- **View their tickets** — see all registrations with live status (Registered / Inside / Checked Out)
- **Scan QR codes** — camera-based scanner for event check-in and check-out
- **Manage their profile** — view account info, role badge, quick actions

---

## 🗂 Project Structure (Clean Architecture)

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart        # All API endpoints in one place
│   ├── network/
│   │   ├── api_client.dart           # Dio HTTP client + token interceptor
│   │   └── api_result.dart           # ApiResult<T> + ApiFailure wrapper
│   └── router/
│       └── app_router.dart           # go_router with auth-guard redirect
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_datasource.dart   # login, register, logout, me
│   │   │   └── models/user_model.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart   # AuthBloc — events & states
│   │       └── pages/
│   │           ├── login_page.dart
│   │           └── register_page.dart
│   │
│   ├── events/
│   │   ├── data/
│   │   │   ├── datasources/events_datasource.dart # getEvents, register, qrCode
│   │   │   └── models/event_model.dart
│   │   └── presentation/
│   │       ├── bloc/events_bloc.dart
│   │       └── pages/home_page.dart
│   │
│   ├── checkin/
│   │   ├── data/
│   │   │   ├── datasources/checkin_datasource.dart # checkIn, checkOut
│   │   │   └── models/registration_model.dart
│   │   └── presentation/
│   │       ├── bloc/checkin_bloc.dart
│   │       └── pages/
│   │           ├── qr_scanner_page.dart
│   │           └── my_tickets_page.dart
│   │
│   └── profile/
│       └── presentation/pages/profile_page.dart
│
├── shared/
│   ├── theme/app_theme.dart          # AppColors, AppTheme, AppTextStyles
│   └── widgets/
│       ├── app_button.dart           # AppButton, AppTextField, ShimmerCard, SnackHelper
│       └── main_shell.dart           # Bottom nav shell
│
└── main.dart                         # App entry + DI wiring
```

---

## 🔌 API Integration

### Base URL
Set your server address in `lib/core/constants/api_constants.dart`:
```dart
static const baseUrl = 'http://YOUR_SERVER_IP/api';
```

### Authentication — Sanctum Tokens
- **POST /api/register** → returns `{ user, token }`
- **POST /api/login** → returns `{ user, token }`
- **POST /api/logout** → invalidates current token
- **GET /api/me** → returns current authenticated user

The token is stored securely via `flutter_secure_storage` and automatically injected into every request by a Dio interceptor:

```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  },
));
```

### Events
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/events` | List all events (supports `?upcoming=true&search=`) |
| GET | `/api/events/{id}` | Single event detail |
| POST | `/api/events/{id}/register` | Register user for event, returns QR data |
| GET | `/api/events/{id}/qr-code` | Re-fetch QR for existing registration |
| GET | `/api/my-registrations` | All registrations for current user |

### QR Check-in/out
| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| POST | `/api/check-in` | `{ qr_data }` | Mark attendee as inside |
| POST | `/api/check-out` | `{ qr_data }` | Mark attendee as left |

The `qr_data` payload is a JSON string:
```json
{
  "registration_id": 1,
  "event_id": 2,
  "user_id": 3,
  "nonce": "hmac_sha256_nonce"
}
```

### Error Handling
All API calls return `ApiResult<T>` — never throw to the UI:

```dart
final result = await _datasource.login(email: email, password: password);
if (result.isSuccess) {
  // use result.data
} else {
  // show result.failure.message
}
```

---

## 🏗 State Management — BLoC

| BLoC | States |
|------|--------|
| `AuthBloc` | AuthInitial → AuthLoading → AuthAuthenticated / AuthUnauthenticated / AuthError |
| `EventsBloc` | EventsInitial → EventsLoading → EventsLoaded / EventsError / EventRegistered |
| `CheckInBloc` | CheckInInitial → CheckInLoading → CheckInSuccess / CheckInError |

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `go_router` | Navigation + auth redirect |
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure token storage |
| `mobile_scanner` | Camera-based QR code scanning |
| `qr_flutter` | Render QR codes from ticket data |
| `shimmer` | Skeleton loading UI |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin
- A running instance of the Ticketin Laravel API

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/ticketin-flutter.git
cd ticketin-flutter

# 2. Set your API base URL
# Edit lib/core/constants/api_constants.dart
# static const baseUrl = 'http://YOUR_API_IP/api';

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run

# 5. Build release APK (arm64-v8a)
flutter build apk --release --target-platform android-arm64
# Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Android Permissions
Already configured in `android/app/src/main/AndroidManifest.xml`:
- `INTERNET` — API requests
- `CAMERA` — QR code scanning

---

## 🔑 Test Credentials (from seeder)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@ticketin.com | password |
| Organizer | organizer@ticketin.com | password |
| Attendee | attendee@ticketin.com | password |

---

## 🧪 Flow Walkthrough

1. **Launch** → App checks for stored token (`GET /me`)
2. **Unauthenticated** → Redirect to `/login`
3. **Login** → Token stored, redirect to `/home`
4. **Browse events** → `GET /events?upcoming=true`
5. **Register** → `POST /events/{id}/register` → receives QR data
6. **My Tickets** → `GET /my-registrations`
7. **View ticket** → Renders QR from stored ticket nonce
8. **Scan QR** → Camera captures QR → `POST /check-in`
9. **Success** → Bottom sheet shows confirmation

---

## 📋 APK Build

```bash
flutter build apk --release --target-platform android-arm64
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

> **Note:** The API server must be accessible from the device (use your local IP or a deployed server).  
> For local testing: set `baseUrl = 'http://192.168.x.x:8000/api'` and ensure `usesCleartextTraffic="true"` in AndroidManifest.

---

## 📸 Mockups

Open `mockups.html` in any browser to view all app screens with phone skin:
- Login & Register
- Home / Event List (with shimmer loading & error states)
- QR Scanner (idle, success, error)
- My Tickets + QR Modal
- Profile

---

## 👤 Author

Built as a mobile client for the Ticketin Laravel API.  
No new backend logic — 100% consuming the existing REST API.
