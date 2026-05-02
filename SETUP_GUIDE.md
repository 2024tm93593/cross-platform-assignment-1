# 🛠️ Complete Back4App Setup Guide

Follow these steps **before running the Flutter app**.

---

## Step 1 — Create Back4App App

1. Sign up at https://www.back4app.com (free)
2. Click **"Build new app"**
3. Choose **"Backend as a Service"**
4. Name your app: `TaskManagerApp`
5. Click **Create**

---

## Step 2 — Get Your API Keys

1. In the Dashboard, click **App Settings** (left sidebar)
2. Click **Security & Keys**
3. You'll see:
   - **Application ID** → copy this
   - **Client Key** → copy this

---

## Step 3 — Add Keys to Flutter App

Open `lib/main.dart`:

```dart
const String kApplicationId = 'PASTE_YOUR_APPLICATION_ID_HERE';
const String kClientKey    = 'PASTE_YOUR_CLIENT_KEY_HERE';
const String kParseServerUrl = 'https://parseapi.back4app.com';
```

> ⚠️ Never commit real keys to a public GitHub repo!

---

## Step 4 — Create the Task Class in Database

1. Go to **Database** in the left sidebar
2. Click **Browser**
3. Click **Create a class**
4. Select **Custom** and name it: `Task`
5. Add these columns one by one:

### Columns to Add:

| Column Name | Data Type | Default Value |
|---|---|---|
| `title` | String | *(none)* |
| `description` | String | *(none)* |
| `isCompleted` | Boolean | `false` |
| `priority` | String | `medium` |

> The `objectId`, `createdAt`, `updatedAt`, and `ACL` columns are added automatically by Parse.

---

## Step 5 — Enable User Authentication

Back4App includes Parse User class by default — no setup needed!

When users register via the app, they appear under:
**Database → Browser → _User class**

---

## Step 6 — Run the App

```bash
cd task_manager_app
flutter pub get
flutter run
```

---

## Step 7 — Verify Data in Dashboard

After testing in the app:
1. Go to **Database → Browser → Task**
2. You should see your created tasks listed
3. Go to **Database → Browser → _User** to see registered users

---

## 🔍 Troubleshooting

| Problem | Fix |
|---|---|
| "Invalid session token" error | Check Application ID + Client Key are correct |
| Tasks not loading | Ensure `Task` class exists in Back4App database |
| Network error | Add `INTERNET` permission to `AndroidManifest.xml` |
| Login fails | Ensure user is registered first |
| App crashes on start | Check `flutter pub get` was run |

---

## 📊 Back4App Dashboard Overview

```
Back4App Dashboard
├── App Settings
│   └── Security & Keys  ← Get Application ID + Client Key here
├── Database
│   └── Browser
│       ├── _User         ← Registered users appear here
│       └── Task          ← Your tasks appear here
├── Analytics            ← API call stats
└── Logs                 ← Debug request/response logs
```

---

##  You're Ready!

Once keys are set and the `Task` class is created, the app is fully functional:
- Register → Login → Create/Read/Update/Delete Tasks → Logout
