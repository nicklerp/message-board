# Message Board — Firebase Flutter Application

**Course:** CSC 4360 — Mobile App Development  
**Assignment:** Homework 02 — The Message Board Vault Hunt  
**Platform:** Flutter / Android  
**Backend:** Firebase Authentication and Cloud Firestore

## Project Overview

Message Board is a Flutter application that allows registered users to communicate through a shared message board. The application uses Firebase Authentication to manage user accounts and Cloud Firestore to store user information and messages.

Authenticated users can create, view, edit, and delete messages. Messages update in real time, allowing users to see new posts and changes without manually refreshing the application.

Firestore security rules protect user information and restrict message modifications to their original authors.

## Features

### Firebase Authentication
- Register new accounts using email and password.
- Log in with existing credentials.
- Sign out of the application.
- Validate registration and login inputs.
- Display feedback when authentication fails.
- Automatically navigate between authentication and message board screens using `authStateChanges()`.
- Preserve authenticated sessions between application launches.

### User Profiles
Upon registration, a user profile is stored in Cloud Firestore under `users/{uid}`.

Each profile contains:

| Field | Description |
|---|---|
| `uid` | Unique Firebase Authentication user ID |
| `firstName` | User's first name |
| `lastName` | User's last name |
| `role` | User role, set to `member` |
| `registrationDateTime` | Server-generated registration timestamp |

If an authenticated user's profile is missing, the application provides a screen for completing the required information.

### Message Board
The application supports all four CRUD operations:

- **Create:** Authenticated users can publish messages.
- **Read:** Users can view messages created by other authenticated users.
- **Update:** Authors can edit their existing messages.
- **Delete:** Authors can permanently remove their messages.

Messages are displayed using a Firestore `snapshots()` stream, so changes are automatically reflected in the interface.

Each message stores its author information, message text, and creation timestamp. Edited messages also receive an updated timestamp.

The interface includes an empty-board message, loading indicators, input validation, and confirmation before deleting messages.

### Splash Screen
A splash screen is displayed while Firebase initializes. If initialization fails, the application displays an error and provides an option to retry.

## Technologies Used

- Flutter and Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- FlutterFire CLI
- Android Emulator

## Project Structure

The main application files are located in the `lib` directory.

| File | Purpose |
|---|---|
| `main.dart` | Application entry point, Firebase initialization, splash screen |
| `firebase_options.dart` | Generated Firebase configuration |
| `auth_service.dart` | Registration, login, logout, authentication state |
| `auth_screen.dart` | Registration and login user interface |
| `auth_gate.dart` | Authentication-based navigation and profile checks |
| `user_service.dart` | Firestore user profile creation and retrieval |
| `board_service.dart` | Firestore message CRUD operations and live stream |
| `message_board_screen.dart` | Message board interface, posting, editing, and deleting |

Firebase operations are separated into services to keep database logic independent of the user interface.

## Firestore Database Structure

The application uses two main Firestore collections.

### Collection: `users`

Document ID: Firebase Authentication UID

Fields:
- `uid`: String
- `firstName`: String
- `lastName`: String
- `role`: String
- `registrationDateTime`: Timestamp

### Collection: `messages`

Document ID: Automatically generated Firestore ID

Fields:
- `text`: String
- `authorUid`: String
- `authorName`: String
- `createdAt`: Timestamp
- `editedAt`: Timestamp (added when a message is edited)

The `authorUid` field identifies the owner of each message. Server-generated timestamps are used to maintain consistent ordering.

## Firestore Security

The application uses Firestore Security Rules to control database access.

**User records:**
- Only authenticated users can access their own profile.
- New profile documents must match the authenticated user's UID.
- Required profile fields are validated during creation.

**Messages:**
- Only authenticated users can read the message board.
- New messages must belong to the authenticated user.
- Only the original author can update or delete a message.
- Message updates cannot change the original author's UID or creation timestamp.
- Empty messages and messages exceeding the character limit are rejected.

The user interface also hides edit and delete actions for messages belonging to other users. However, security is enforced by Firestore rules rather than relying on interface restrictions.

## Setup Instructions

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or a configured Android device
- Firebase project
- FlutterFire CLI

### Installation

1. Clone or download the project repository.
2. Open the project directory in VS Code or Android Studio.
3. Install dependencies using `flutter pub get`.
4. Configure a Firebase project with Authentication and Cloud Firestore.
5. Enable Email/Password as a sign-in method in Firebase Authentication.
6. Configure the Flutter application using `flutterfire configure` and select the Android platform.
7. Ensure the Firestore security rules are configured for the `users` and `messages` collections.
8. Start an Android emulator or connect an Android device.
9. Run the application using `flutter run`.

The `firebase_options.dart` file is generated by FlutterFire and must correspond to the Firebase project being used.

### Build Android APK

Run the following command from the project directory:

`flutter build apk --release`