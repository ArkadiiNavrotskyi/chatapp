# FlutterChat — Assignment 6

Chat app with registration (with profile image), login, a chat screen,
notifications for new messages, and logout.

## Backend

I could not get access to the Firebase console, so the app uses a **local
backend with the same structure as Firebase** (`lib/backend/`):

| Local class | Replaces | What it does |
|---|---|---|
| `LocalAuth` | Firebase Auth | Email/password sign-up and sign-in, `authStateChanges()` stream, Firebase-style error codes. Passwords are stored as salted SHA-256 hashes. |
| `LocalDb` | Cloud Firestore | `users` and `chat` collections with live snapshot streams. |
| `LocalStorage` | Firebase Storage | Stores profile images (`user_images/{uid}.jpg`). |
| `NotificationService` | Firebase Cloud Messaging | Shows a notification when a message from another user arrives while the app is in the background. |
| `SimulatedUser` | — | A second user ("Maximilian") that replies, so incoming messages can be shown on one device. |

All data is stored on the device. The screens only talk to the services in
`lib/services/`, so switching to Firebase means replacing those services.
A Firebase version of the services is kept in `_firebase_version/` (not
connected to a project).

## Run

```
flutter pub get
flutter run            # Android emulator / phone
flutter run -d chrome  # browser
```

To see a notification: send a message, then press Home. The reply arrives
after ~4 seconds.
