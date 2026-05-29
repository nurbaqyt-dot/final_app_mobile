# FlowDay 📅

> AI-powered daily planner for JIHC students — built with Flutter & Firebase.

FlowDay helps students at JIHC keep their schedule, deadlines, tasks, and free time under control inside one clean, dark purple interface.

---

## Features

### 🔐 Authentication
- Email & password sign-in and registration via Firebase Auth
- Persistent session — stays logged in across app restarts
- Profile editing: display name, student ID, and avatar upload

### 🗓 Today Screen
- Personalized daily schedule view
- **"Собрать план"** button — generates a structured day plan with study blocks, rest, and sport
- At-a-glance overview of what's ahead

### 📆 Events & Calendar
- Beautiful calendar UI with event markers
- Create, view, and manage events by date
- Event list view alongside the calendar for quick scanning

### ✅ Tasks
- Add tasks with **priority** (high / medium / low) and **status**
- Mark tasks as done or undone with a single tap
- **Filter** tasks by completion status
- Task counter stats shown on the Profile screen

### 👤 Profile
- Student ID card with name, email, and college
- Live task stats: completed, active, and overall progress %
- Built-in menu with:
  - **Статистика** — task completion statistics
  - **Достижения** — unlockable achievements (e.g. close 1 / 5 / 10 tasks)
  - **Уведомления** — configure morning plan, deadline, and break reminders
  - **Настройки** — push notifications, daily summary, plan hints, sign out
  - **О приложении** — app version, developer info, AI model used
  - **Поддержка** — FAQ

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend / Auth | Firebase Authentication |
| Database | Firebase Firestore |
| Storage | Firebase Storage (avatar upload) |
| Navigation | go_router (ShellRoute) |
| State management | Provider |
| AI planning | Anthropic Claude API |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # AppConstants (app name, college, AI model, etc.)
│   ├── theme/          # AppColors, dark purple theme
│   └── utils/          # Snackbar helpers, formatters
├── models/             # TaskModel, EventModel, UserModel
├── providers/          # AuthProvider, TaskProvider, ProfileProvider
├── router/             # AppRouter, AppRoutes (go_router config)
├── screens/
│   ├── auth/           # SignIn, Register
│   ├── today/          # Today plan screen
│   ├── events/         # Calendar + event list
│   ├── tasks/          # Task list + filters
│   └── profile/        # Profile + sub-screens
└── widgets/            # FlowScaffold, FlowCard, FlowButton, AdaptiveAvatar…
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication**, **Firestore**, and **Storage** enabled
- An Anthropic API key (for plan generation)

### Setup

1. Clone the repo and install dependencies:
   ```bash
   git clone <repo-url>
   cd final_mobile_dev
   flutter pub get
   ```

2. Add your Firebase config:
   ```bash
   # Install FlutterFire CLI if needed
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` automatically.

3. Set your Anthropic API key in `lib/core/constants/app_constants.dart`:
   ```dart
   static const String anthropicModel = 'claude-sonnet-4-20250514';
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## Firebase Rules (Firestore)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Design

- **Primary color:** `#6C3EE8` (deep violet)
- Dark-only theme — no light mode toggle
- Frosted glass bottom navigation bar with blur effect
- Rounded cards (`28px` radius) throughout

---
##Screenshot
![image alt](https://raw.githubusercontent.com/nurbaqyt-dot/final_app_mobile/a64233e3a3d740fe9dc6841b7fdd1cd2396a882b/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-05-29%20%D0%B2%2008.54.36.png)
---

## Developer

Built by a JIHC student as a final mobile development project.

College: **JIHC** — Jayaswal Institute of Higher Creativity  
App: **FlowDay** — *stay in the flow, every day.*
