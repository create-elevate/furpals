# FurPals — Developer's Guide /Roadmap

## 1. Directory Tree

```
furpals/
├── android/                        # Android-specific config, manifests, build files
│   └── app/
│       ├── google-services.json    # Firebase Android credentials (do not expose publicly)
│       └── src/main/               # AndroidManifest, MainActivity, and drawable resources
├── fonts/
│   └── Modak-Regular.ttf           # Custom font used on the splash screen title
├── assets/
│   └── images/                     # App logo, icons, and UI image assets
├── lib/                            # All Dart source code (main application logic)
│   ├── main.dart                   # App entry point; route definitions
│   ├── firebase_options.dart       # Auto-generated Firebase config for all platforms
│   ├── models.dart                 # Shared data models (Pet, Appointment, PetEvent, etc.)
│   ├── splash_screen.dart          # Animated splash screen with auth redirect logic
│   ├── login.dart                  # Login screen with Firebase Auth
│   ├── signup.dart                 # Sign-up screen with Firestore user creation
│   ├── Homescreen.dart             # Main shell with bottom nav, feed, post modal, drawer
│   ├── petmanagement.dart          # Pet profiles, appointments list, events list
│   ├── newappointment.dart         # Calendar UI for creating/editing appointments
│   ├── calendar.dart               # Standalone calendar screen (legacy/unused variant)
│   ├── addevent.dart               # Form screen for creating/editing pet events
│   ├── eventdetail.dart            # Event detail view with member management
│   ├── lost&found.dart             # Lost & Found listing screen
│   ├── lf_add_missing.dart         # Form for reporting a missing pet
│   ├── lostfoundprofile.dart       # Individual lost/found pet profile screen
│   ├── NotificationScreen.dart     # Notification feed with read/mute/delete actions
│   └── settings.dart               # Settings screen (toggles and account actions)
├── pubspec.yaml                    # Flutter dependencies and asset declarations
├── firebase.json                   # FlutterFire CLI project configuration
└── .firebaserc                     # Firebase project alias
```

## 2. Entry Point & Logic

**Entry point:** `lib/main.dart`

- `main()` initializes Firebase via `Firebase.initializeApp()` using platform-specific options from `firebase_options.dart`, then runs `MyApp`.
- `MyApp` is a `MaterialApp` with named routes. The initial route `/` loads `SplashScreen`.
- `SplashScreen` checks `FirebaseAuth.instance.currentUser` and the `remember_me` flag in `SharedPreferences` to decide whether to redirect to `/home` or `/login`.
- **Authentication** uses Firebase Auth (email/password). On login/signup, the user's UID is used to read/write their profile document in the `users` Firestore collection.
- **Feed posts** are stored in the `posts` Firestore collection with subcollections for `likes` and `comments`.
- **Notifications** are stored in a top-level `notifications` collection, queried by `toUserId`.
- **Media uploads** (photos/videos) go to Firebase Storage under `posts/{uid}/`.

---

## 3. Unimplemented Features & Gaps

### Navigation & Routing
- **Profile tab (index 4)** in the bottom nav is wired to a placeholder `ProfileBody` widget — no actual profile screen exists.
- **Calendar tab (index 4)** in `_MainShellState` renders `CalendarScreen` from `calendar.dart` (the legacy standalone version), which has no save logic and is disconnected from the real appointment system in `newappointment.dart`.

### Social Features
- **Follow / Unfollow:** The "Follow" button in the Likes modal is purely cosmetic — no follow relationship is stored in Firestore.
- **Share Post:** The share sheet UI exists but all platform share actions just show a snackbar; no actual sharing or deep-linking is implemented.
- **Saved Posts:** The "Saved Posts" drawer item calls `Navigator.pop()` — no saved posts feature exists.

### Lost & Found
- **Pet cards** in the grid display hardcoded placeholder data (`'Pet Name'`, `'pet breed'`, etc.); no Firestore integration is present for Lost & Found listings.
- **Lost & Found profile screen** (`lostfoundprofile.dart`) accepts a `pet` map but is only reachable via the route `/lostandfoundprofile` with an empty map `{}` — no real data flows into it.
- **Location** on the Lost & Found screen shows `'Current Location...'` as a static string; no GPS or location service is connected.

### Settings Screen
- All toggle switches (Dark Mode, notifications, location, etc.) only update local state — none are persisted to Firestore or device preferences.
- **Edit Profile, Change Password, Change Email, Phone Number, Blocked Users, Help & Support, Rate the App** — all buttons have empty `onTap: () {}` handlers with no implementation.
- **Deactivate** calls `pushReplacementNamed('/login')` without actually deactivating the Firebase Auth account.
- **Delete Account** shows a dialog but does nothing on confirm.

### Drawer
- **Saved Posts** and **About** and **Help & Support** drawer items call `Navigator.pop()` only — no screens exist for these.

### Pet Management
- Pets and appointments are stored **in-memory only** (local `List` state in `_PetsScreenState`). None of the pet profiles or appointments are persisted to Firestore. A full refresh loses all data.
- Vaccination records are hardcoded sample data with no CRUD capability.

### Admin Side — **MISSING ENTIRELY**
> **There is no Admin Dashboard or Admin Panel of any kind.** The next team must design and build this from scratch. Required admin capabilities should include:
> - User account management (view, suspend, delete accounts)
> - Post moderation (review reported posts and comments)
> - Lost & Found listing approval/removal
> - Notification broadcasting
> - Event moderation
> - Analytics overview (user counts, post counts, active sessions)

---

## 4. Known Issues

| # | File | Issue |
|---|------|-------|
| 1 | `Homescreen.dart` | `FurPalsColors` class is re-declared across multiple files (`Homescreen.dart`, `petmanagement.dart`, `calendar.dart`, `lost&found.dart`, `NotificationScreen.dart`, etc.), causing potential conflicts. It should live only in `models.dart` and be imported everywhere. |
| 2 | `calendar.dart` | This is a legacy/duplicate calendar screen. It has no `pets` parameter and no save logic. It is routed from the bottom nav but is functionally disconnected from the appointment system. Should be removed or merged with `newappointment.dart`. |
| 3 | `lost&found.dart` | `_pets` list is hardcoded placeholder data — the grid always shows the same three dummy cards regardless of any real Firestore data. |
| 4 | `petmanagement.dart` | `samplePets` and `sampleAppointments` are hardcoded at the top of the file. All pet and appointment data is lost on hot restart or app reload. |
| 5 | `Homescreen.dart` | Video upload can silently fail if Firebase Storage quota is exceeded; the error dialog is generic and gives no actionable feedback to the user. |
| 6 | `lost&found.dart` | The top bar hardcodes the username as `'Mickaluvsyou'` instead of reading from `FirebaseAuth` or Firestore. |
| 7 | `splash_screen.dart` | `remember_me` check is done with `SharedPreferences` but the Firebase Auth session persists independently. A user who is not "remembered" but still has an active session will be incorrectly redirected to `/login`. |
| 8 | `newappointment.dart` vs `calendar.dart` | Both export a class named `CalendarScreen`, which requires aliased imports and causes confusion. |

---

## 5. What to build? 

- **Persist Pet & Appointment Data to Firestore.** Replace the in-memory `samplePets` and `sampleAppointments` lists with real Firestore reads/writes scoped to the authenticated user's UID. This is the most critical gap for the core pet management feature to be usable.

- **Build the Admin Dashboard.** Design and implement a separate admin interface (web app or Flutter web target recommended) that connects to the same Firebase project. At minimum, it must support user management, post/report moderation, and Lost & Found listing control. Without this, there is no way to manage or moderate the platform.

- **Complete the Lost & Found Feature End-to-End.** Wire `lf_add_missing.dart` to write submissions to Firestore, update `lost&found.dart` to read and display real listings, and connect `lostfoundprofile.dart` to receive and render actual pet data. Add geolocation support for the "Current Location" display.