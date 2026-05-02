# Task Manager App

A Flutter-based mobile application that connects to Back4App as a cloud backend. The app allows users to register with their full name and email, manage personal tasks, and log out securely. All data is stored and retrieved from Back4App in real time without any custom server code.

---

## What This Project Does

The application gives each registered user a private list of tasks. A user can add a new task with a title and description, choose a priority level, mark it as complete, update its details, or delete it by swiping the card. Every action is saved directly to the Back4App cloud database and visible in the Back4App dashboard under the Task class.

The home screen also shows a stats card displaying the total number of tasks alongside the counts for pending and completed tasks. Tasks can be filtered in memory using the All, Pending, and Completed filter chips. The list supports pull-to-refresh so the user can sync with the server on demand.

The project was built as part of a mobile application development assignment to demonstrate practical use of Backend-as-a-Service in a Flutter application.

---

## Technology Used

**Flutter and Dart** handle the entire frontend. All screens, forms, navigation, and state management are written in Dart using Flutter widgets with Material 3 design. The SDK constraint is `>=3.0.0 <4.0.0`.

**Back4App** is the backend platform. It is a hosted Parse Server reachable at `https://parseapi.back4app.com` that provides user authentication, a cloud database, and an ACL-based access control system. No custom backend code was written for this project.

**parse_server_sdk_flutter 10.7.0** is the official Dart package used to communicate between the Flutter app and Back4App. It handles login sessions, database queries, object persistence, ACL assignment, and user pointers.

**provider ^6.1.1** is used for state management, propagating app state changes across the widget tree without manual callbacks.

**shared_preferences ^2.2.2** provides lightweight local key-value persistence for storing user preferences and session-adjacent data on the device.

**intl ^0.18.1** is used for date and time formatting throughout the app.

**flutter_slidable ^3.0.1** powers the swipe-to-delete gesture on task list items, revealing the delete action when a card is swiped left.

**google_fonts ^6.1.0** supplies custom typography used across all screens.

**fluttertoast ^8.2.4** displays short toast notifications to give the user feedback after actions such as saving or deleting a task.

**lottie ^3.0.0** renders Lottie animations used in the splash screen and empty-state views.

**uuid ^4.2.2** generates unique identifiers where locally assigned IDs are needed before a Parse objectId is available.

**GitHub** is used for version control and submission.

---

## Project Structure

```
lib/
    main.dart                   Entry point, Parse initialization, SplashWrapper, ThemeData
    models/
        task_model.dart         TaskModel + TaskPriority enum, fromParse/toParseObject/copyWith
    services/
        parse_service.dart      ParseService: register, login, logout, currentUser, createTask, getTasks, updateTask, deleteTask, toggleTaskComplete
    screens/
        login_screen.dart       Email + password login form with validation
        register_screen.dart    Full name + email + password + confirm password registration
        home_screen.dart        Stats card, filter chips (All/Pending/Completed), task list, swipe-to-delete, toggle complete, FAB
        task_form_screen.dart   Create/edit task form; title (max 100), description (max 500), priority selector, status toggle (edit mode only)
```

---

## Back4App Setup

Before running the app, create a free account at back4app.com and complete the following steps.

**Step 1.** Create a new app named TaskManagerApp from the Back4App dashboard.

**Step 2.** Go to App Settings, then Security and Keys. Copy the Application ID and Client Key.

**Step 3.** Open lib/main.dart and replace the placeholder values:

```dart
const String kApplicationId = 'YOUR_APPLICATION_ID';
const String kClientKey     = 'YOUR_CLIENT_KEY';
```

**Step 4.** In the Back4App dashboard, go to Database, then Browser. Create a new custom class named Task. Add these columns:

| Column Name | Type              | Notes                     |
| ----------- | ----------------- | ------------------------- |
| title       | String            | Max 100 chars             |
| description | String            | Optional, max 500 chars   |
| isCompleted | Boolean           | Default value: false      |
| priority    | String            | One of: low, medium, high |
| user        | Pointer to \_User | Links task to its owner   |

**Step 5.** Click the lock icon on the Task class and set Read, Write, and Add Field permissions to Authenticated under Class Level Permissions. Save the changes.

---

## How to Run the Application

Install Flutter from flutter.dev and Android Studio from developer.android.com. Connect your Android phone via USB with USB Debugging enabled, or start an Android emulator through Android Studio.

Open a terminal in the project folder and run the following commands:

```bash
flutter pub get
flutter run
```

To verify the phone is detected before running:

```bash
flutter devices
```

---

## Visual Design

The app uses a teal color theme derived from Material Design's teal palette, replacing an earlier purple-indigo scheme. The primary color is `#00897B` (Material Teal 600) and the secondary gradient end color is `#4DB6AC` (lighter teal). Input fields use `Colors.teal.shade50` as their fill color. This teal theme is consistently applied across all screens, appearing on the app bar, splash screen, primary buttons, the floating action button, the stats card gradient, filter chips, task completion indicators, focused input borders, link text, and toggle switch controls. The softer light-teal tint is also used as the input field fill color, giving every form a cohesive and calm visual tone throughout the application. All screens use `#F5F6FA` (light grey) as the background color.

Priority badges on task cards are color-coded: green for low priority, orange for medium, and red for high. Status badges follow the same pattern, with green indicating a completed task and orange indicating a pending one.

---

## Application Flow

When the app opens, the SplashWrapper calls `ParseUser.currentUser()` and then `getUpdatedUser()` to validate the stored session token against the Back4App server. If the session is valid, the user is taken directly to the home screen. If not, the login screen is shown.

On the login screen, users enter their registered email and password. The email address is used as both the display username and the Parse credential. First-time users tap the register link and create an account by providing their full name, email, password, and a password confirmation. After registration, they return to the login screen to sign in.

The home screen displays all tasks belonging to the logged-in user alongside a stats card that shows Total, Pending, and Done counts and the logged-in user's email. Tasks are fetched from Back4App using a query filtered by the user pointer stored on each task object. Users can filter the list by status using the All, Pending, and Completed chips, pull down to refresh, create a new task using the floating action button, edit a task by tapping the pencil icon, toggle completion by tapping the circle on the left, or delete a task by swiping the card to the left. A confirmation dialog is shown before deletion. An empty state view is displayed when no tasks match the active filter.

The task form is used for both creating and editing tasks. It contains a title field (max 100 characters), a description field (max 500 characters), and a priority selector. When editing an existing task, a status toggle implemented as a SwitchListTile is also shown, allowing the user to change the completion state directly from the form. Both the AppBar Save button and the full-width bottom Save button trigger the same save action.

Logout calls `user.logout()` to invalidate the session on the Back4App server and then redirects to the login screen.

---

## CRUD Implementation Details

**Create.** A new ParseObject of class Task is built via `task.toParseObject(user)`. The method sets all task fields, attaches the current user as a Parse pointer on the `user` field, and assigns a `ParseACL` configured to allow only the owner to read and write the record. Calling `save()` on the object sends it to Back4App.

**Read.** A `QueryBuilder` on the Task class uses `whereEqualTo('user', user.toPointer())` to fetch only tasks belonging to the current user. Results are ordered by `createdAt` descending so the newest tasks appear first.

**Update.** When editing a task, the same `toParseObject` path is used but with the existing `objectId` already present on the ParseObject. Because the objectId matches a record already on the server, Parse treats the `save()` call as an update rather than creating a duplicate.

**Delete.** A `ParseObject('Task')` is constructed with only the `objectId` of the task to remove. Calling `delete()` on that minimal object removes it from the Back4App database without needing to fetch the full object first.

**Toggle Complete.** The toggle is handled by calling `updateTask(task.copyWith(isCompleted: !task.isCompleted))`, which produces an updated copy of the task model and passes it through the standard update path described above.

---

## Issues Found and Fixed During Development

The initial version of the application had three problems that prevented any CRUD operation from working.

The first issue was in the ACL setup. The code used `ParseUser.forQuery()` to set the task owner, which is a placeholder object used for building queries and not the actual logged-in user. This caused every save operation to fail with a permission error. The fix was to fetch the current user explicitly using `ParseUser.currentUser()` and pass that to the `ParseACL` constructor.

The second issue was in the query that fetches tasks. The code used `whereEqualTo` on the ACL field, which is not a queryable field in Parse. Tasks were not loading at all. The fix was to store the user as a Pointer field named `user` on each task and query by that pointer instead.

The third issue was that no user pointer was being saved on task objects. This meant there was no way to associate a task with the user who created it, and no way to query per-user tasks accurately. Adding the `user` pointer field in `toParseObject` and querying by that pointer resolved both the read isolation and the per-user ownership requirements.

---

## Submission Details

**Name:** Chetan Ranganath

**Email:** 2024tm93593@wilp.bits-pilani.ac.in

**Youtube Link:** :

---

## Notes

The app was developed and tested on a OnePlus 12R running Android 14. The Back4App free tier was used throughout development. Debug mode is enabled in main.dart and should be set to false before any production use.
