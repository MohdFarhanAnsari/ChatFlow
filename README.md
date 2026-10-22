# ChatFlow 💬

**ChatFlow** is a premium, real-time messaging application engineered with **Flutter**, **Riverpod**, **GoRouter**, and the **Google Firebase Ecosystem** (Authentication, Cloud Firestore, Firebase Storage, and Firebase Cloud Messaging).

Crafted with a fintech-grade dark aesthetic (Deep Navy surfaces and Emerald accents), fluid micro-animations, and a robust feature-first architecture, ChatFlow is designed for high-performance, real-time mobile communication.

---

## 🌟 Key Features

- **Real-Time 1:1 Messaging**: Cloud Firestore snapshot listeners deliver reactive message synchronization with sub-100ms updates.
- **Message States & Read Receipts**: Distinct message indicators for `sending` (clock), `sent` (single checkmark), and `read` (emerald double-check). Read receipts are marked only upon entering the conversation.
- **Replies & Context Quoting**: Swipe or long-press any message to quote it with a dedicated reply banner.
- **Interactive Emoji Reactions**: Quick emoji reaction bar (`❤️`, `👍`, `😂`, `😮`, `😢`, `🔥`) with toggle mechanics and live user badge counters.
- **Message Soft-Deletion**: Sender-authorized deletion with audit-safe soft-delete semantics (`isDeleted = true`).
- **High-Resolution Image Sharing**: Firebase Storage upload pipeline with client-side mime-type/size validation (up to 10 MB), progress tracking, and full-screen `InteractiveViewer` with pinch-to-zoom.
- **Presence & Last Seen**: Real-time user online status and contextual timestamps (`Active now`, `Active 15m ago`, `Offline`) synchronized with Flutter app lifecycle states.
- **User Discovery & Search**: Live user search by display name or email to initiate new encrypted chats.
- **User Profiles**: Custom display names, status/bio, and avatar photo uploads with cached network image fallbacks.
- **Push Notifications (FCM)**: Client-side Firebase Cloud Messaging setup, background message handler (`@pragma('vm:entry-point')`), foreground alert presentation, and FCM token synchronization.
- **Theme & Appearance**: Deep Navy Dark Mode, Clean Light Mode, and System Follow with persistent state across app restarts.
- **Dual-Engine Architecture (Interactive Demo + Live Firebase)**: Runs immediately out of the box in zero-config **Interactive Demo Mode** with pre-seeded contacts (Sarah Chen, Alex Rivera, Dr. Maya Patel, Marcus Brooks), local SharedPreferences persistence, realistic simulated replies, and full session retention across app restarts. Seamlessly connects to live Firebase once configured.
- **Interactive Demo Data Reset**: Instant one-tap reset from Settings restoring default profiles, conversations, and seeded message threads.

---

## 🏗️ Architecture

ChatFlow follows a **feature-first, clean architecture** ensuring strict separation of concerns, testability, and sound null safety:

```
lib/
├── core/
│   ├── config/              # Safe Firebase initialization & options templates
│   ├── constants/           # Design system tokens (AppColors, AppDimens, AppStrings)
│   ├── router/              # GoRouter with authentication route guards
│   ├── theme/               # Material 3 Dark (Deep Navy) & Light Themes + Riverpod provider
│   └── utils/               # DateFormatter, form validators
├── shared/
│   ├── models/              # Demo dataset for zero-config portfolio reviews
│   └── widgets/             # Reusable UI primitives (AppAvatar, AppButton, AppTextField, EmptyView, ErrorView)
├── features/
│   ├── auth/                # Authentication (Splash, Onboarding, Login, SignUp, Password Reset, Demo Mode)
│   ├── demo/                # Offline persistence layer (DemoLocalStore) via SharedPreferences
│   ├── profile/             # Profile management & User Discovery / Search
│   ├── chat/                # Real-time messaging, bubbles, reply banner, reactions, input bar
│   ├── media/               # Image picking & Firebase Storage / local media service
│   ├── notifications/       # Firebase Cloud Messaging service & background entry point
│   └── settings/            # Theme switcher, simulated reply toggles, demo data reset, and About screen
└── main.dart                # App bootstrap, lifecycle observer, and Riverpod ProviderScope
```

---

## 📦 Technology Stack & Dependencies

All packages are pinned to stable, mutually compatible versions:

| Package | Purpose |
|---|---|
| `flutter_riverpod` | Reactive state management & dependency injection |
| `go_router` | Declarative routing with authentication state guards |
| `firebase_core` | Core Firebase app initialization |
| `firebase_auth` | Secure email/password authentication & session persistence |
| `cloud_firestore` | Real-time NoSQL database for messages, conversations, and presence |
| `firebase_storage` | Cloud media storage for images and avatars |
| `firebase_messaging` | Push notifications and device token management |
| `image_picker` | Gallery and camera image selection |
| `cached_network_image` | High-performance remote image caching with placeholder fallbacks |
| `shared_preferences` | Local persistence for theme mode, demo sessions, messages, and settings |
| `intl` | Timestamp and date formatting |
| `uuid` | Unique identifier generation for messages and uploaded media |
| `mocktail` | Unit testing and mocking (dev dependency) |

---

## 🔒 Security Rules

ChatFlow includes production-grade security rules restricting database and storage access.

### 1. Cloud Firestore Rules (`firestore.rules`)
- **Authentication Required**: No unauthenticated reads or writes.
- **Data Isolation**: Only participants whose UIDs are in `participantIds` can read or write conversations and their message subcollections.
- **Sender Verification**: Messages can only be created if `request.resource.data.senderId == request.auth.uid`.
- **Profile Protection**: Users can only update their own profile document (`/users/{uid}`). Modifying other users' profiles is blocked.
- **Soft-Delete Integrity**: Deleting messages sets `isDeleted: true` and clears text/media, preventing destructive physical deletes.

To deploy Firestore security rules:
```bash
firebase deploy --only firestore:rules
```

### 2. Cloud Storage Rules (`storage.rules`)
- Uploads restricted to authenticated users.
- Enforces strict image mime-type checking (`image/(jpeg|png|webp|gif)`).
- Caps chat image file sizes to **10 MB** and profile avatars to **5 MB**.
- Restricts avatar uploads to the authenticated account owner (`/profile_avatars/{userId}/`).

To deploy Storage security rules:
```bash
firebase deploy --only storage
```

### 3. Firestore Composite Indexes (`firestore.indexes.json`)
The following composite index is required for querying conversations sorted by `lastTimestamp`:
```json
{
  "collectionGroup": "conversations",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
    { "fieldPath": "lastTimestamp", "order": "DESCENDING" }
  ]
}
```
Deploy via:
```bash
firebase deploy --only firestore:indexes
```

---

## 🚀 Getting Started & Zero-Config Demo Mode

### Prerequisites
- Flutter SDK `>=3.3.0 <4.0.0`
- Android Studio / Android SDK (API 23+)
- Java JDK 17 (recommended for Gradle build compatibility)

### Launching Demo Mode (No Firebase Setup Required)
ChatFlow is engineered with **zero-config resiliency**. You do **not** need a Firebase project or any cloud credentials to review, run, or test the complete application:

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```
2. **Launch the app**:
   ```bash
   flutter run
   ```
3. Tap **"Explore Interactive Demo"** on the onboarding or sign-in screens.

In Demo Mode:
- **Offline Persistence**: Messages, threads, profile changes, and reactions persist locally via `DemoLocalStore` (`SharedPreferences`) across application restarts.
- **Pre-Seeded Contacts**: Engage with simulated colleagues (Sarah Chen, Alex Rivera, Dr. Maya Patel, Marcus Brooks).
- **Simulated Responses**: Incoming messages generate natural, simulated conversational replies.
- **Full Feature Access**: Experience 1:1 messaging, reactions, quote replies, read receipts, soft deletes, user search, profile updates, and dark/light theming out of the box.
- **One-Tap Reset**: Reset demo data at any time from **Settings > Reset Demo Data**.

### Running Automated Tests
```bash
flutter test
```

### Analyzing Code Quality
```bash
flutter analyze
```

### Building the Debug APK
```bash
flutter build apk --debug
```
Output path: `build/app/outputs/flutter-apk/app-debug.apk`

---

## ⚙️ Connecting Your Own Firebase Backend (Optional)

ChatFlow is fully prepared for live Google Firebase cloud services (Authentication, Cloud Firestore, Firebase Storage, and FCM).

### Security Architecture & Safe Local Configuration
> [!IMPORTANT]
> To protect project secrets, real configuration files (`android/app/google-services.json` and `lib/core/config/firebase_options.dart`) are explicitly listed in `.gitignore` and **must never be committed to version control**. Safe example templates with fake placeholders are provided in the repository:
> - [`android/app/google-services.json.example`](android/app/google-services.json.example)
> - [`lib/core/config/firebase_options.dart.example`](lib/core/config/firebase_options.dart.example)

### Step-by-Step Setup Instructions
1. **Create a Firebase Project**:
   - Open the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. **Register Android Application**:
   - Add an Android app with package name `com.chatflow.chatflow`.
   - Download the generated `google-services.json` and place it at:
     ```
     android/app/google-services.json
     ```
3. **Configure Firebase Options**:
   - Recommended: Use the FlutterFire CLI to automatically register your platform configuration:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
   - Alternatively, copy the example template and fill in your project credentials:
     ```bash
     cp lib/core/config/firebase_options.dart.example lib/core/config/firebase_options.dart
     ```
4. **Enable Authentication**:
   - In the Firebase Console, navigate to **Build > Authentication > Sign-in method**.
   - Enable **Email/Password** provider and save.
5. **Deploy Security Rules & Indexes**:
   - Install the Firebase CLI (`npm install -g firebase-tools`) and log in (`firebase login`).
   - Deploy production Firestore security rules, indexes, and Storage rules included in this repo:
     ```bash
     firebase deploy --only firestore:rules,firestore:indexes,storage
     ```
6. **Run the App**:
   - Run `flutter run`. ChatFlow will detect the live credentials, initialize Firebase, and connect to your cloud backend automatically.

---

## 🧪 Manual Testing Steps

Use these structured steps to verify the complete authentication lifecycle on your target device or emulator:

### 1. Form Validation & Password Visibility
- Launch the app and proceed to the **Sign In** screen.
- Leave fields blank and tap **Sign In**: verify error messages appear ("Email address is required", "Password is required").
- Enter an invalid email format (e.g., `user@domain` without TLD): verify "Please enter a valid email address".
- Enter a password shorter than 6 characters: verify "Password must be at least 6 characters".
- Tap the **eye icon** in the password field: verify password characters toggle between obscured dots and plain text.

### 2. User Registration (Sign Up)
- From Sign In, tap **Sign Up** to open the registration screen.
- Enter a display name (e.g., `Alex Vance`), a valid email, and matching passwords.
- Tap **Create Account**: verify loading state displays on the button, duplicate taps are prevented, and the app redirects into the Conversations home screen upon completion.

### 3. Persistent Auth Session
- With the user signed in, completely close or force-kill the app process.
- Re-open ChatFlow: verify the splash screen detects the active Firebase session and routes straight to the **Conversations** screen without showing the Login screen.

### 4. Sign Out
- Open **Settings** from the top-right icon on the Conversations screen.
- Scroll down to the **System & About** section and tap **Sign Out**.
- Confirm in the prompt dialog: verify the user is signed out, local credentials are wiped, and the app navigates back to the **Sign In** screen.

### 5. Existing Email / Duplicate Registration Error Handling
- Navigate back to **Sign Up** and attempt to register using the same email address as in Step 2.
- Tap **Create Account**: verify an error banner appears displaying `"This email is already registered. Please sign in instead."`

### 6. Invalid Credentials on Login
- On the **Sign In** screen, enter a registered email with an incorrect password.
- Tap **Sign In**: verify the error banner displays `"Incorrect email or password. Please verify and try again."`

### 7. Forgot Password Flow
- On the **Sign In** screen, tap **Forgot Password?** to open the dedicated reset screen.
- Enter your registered email address and tap **Send Reset Link**.
- Verify the button shows a loading spinner, followed by a green confirmation card: `"Reset Link Sent: We sent a password reset email..."`.
- Check your email inbox for the Firebase password reset email.
- Tap **Return to Sign In** to return smoothly to the login screen.

### 8. Strict Demo Mode Separation
- On the **Sign In** screen, tap **Explore Interactive Demo**.
- Verify the app logs in as the local demo user (`Devon Vance`), displaying the emerald `DEMO` top banner.
- Open **Settings**: verify the Interactive Demo Mode switch is ON, and "Reset Demo Data" is available.
- Toggle off Demo Mode or tap Sign Out: verify the app returns cleanly to the Sign In screen without corrupting real Firebase accounts.

---

## ⚠️ Demo Mode Architecture & Limitations

- **Strict Separation**: Demo Mode operates on a completely separate local persistence engine (`DemoLocalStore` using `SharedPreferences`). Demo accounts are never submitted to or mixed with real Firebase Auth user registries.
- **Local Persistence**: Demo messages, reactions, read status, and mock profiles persist offline across app restarts.
- **Simulated Responses**: In Demo Mode, pre-seeded contacts (Sarah Chen, Alex Rivera, Dr. Maya Patel, Marcus Brooks) simulate replies with natural delays.
- **Instant Reset**: Tapping "Reset Demo Data" in Settings restores initial sample contacts and threads without affecting real cloud users.
