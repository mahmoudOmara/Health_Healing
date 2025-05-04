## Health Healing App: Estimated Resources & Dependencies per Milestone

This document outlines the estimated resources (packages, services) and dependencies needed for each development milestone.

**General Dependencies:**
*   Flutter SDK (v3.29.3 or latest stable)
*   Dart SDK (comes with Flutter)
*   Firebase Account (Spark plan initially, potentially Blaze for extensive Cloud Functions)
*   Code Editor (e.g., VS Code with Flutter/Dart extensions)
*   Git & GitHub Account
*   Android/iOS Emulators or Physical Devices for testing
*   `Inter` font file (to be added to project assets)

**Milestone 1: Foundation & Authentication**
*   **Flutter Packages:**
    *   `firebase_core`: For initializing Firebase.
    *   `firebase_auth`: For phone OTP authentication.
    *   `provider` or `flutter_riverpod`: For state management.
    *   `google_fonts`: To use the 'Inter' font.
*   **Firebase Services:**
    *   Firebase Authentication (Phone Number method enabled).
    *   Cloud Firestore (Database created).
*   **Other:** Basic UI components (Bottom Nav Bar, Buttons, Text Fields).

**Milestone 2: Core Feature - Health Issues Management**
*   **Flutter Packages:**
    *   `cloud_firestore`: For database interaction.
    *   `intl`: For date formatting (e.g., Start Date).
    *   `uuid`: For generating unique IDs if needed.
    *   State management package.
*   **Firebase Services:**
    *   Cloud Firestore: CRUD operations for `health_issues` collection.
*   **Other:** UI for Home Screen, Add Issue Popup, Detail View; Search logic.

**Milestone 3: Calendar & Reminders**
*   **Flutter Packages:**
    *   `table_calendar`: For the calendar UI grid.
    *   `cloud_firestore`: For fetching/updating reminders.
    *   `intl`: For date display.
    *   State management package.
*   **Firebase Services:**
    *   Cloud Firestore: CRUD for `reminders`, querying related data.
*   **Other:** Calendar UI design, Reminder data model, Filter logic.

**Milestone 4: Communication & History**
*   **Flutter Packages:**
    *   `cloud_firestore`: For fetching history data.
    *   `intl`: For date grouping/formatting.
    *   State management package.
*   **Firebase Services:**
    *   Cloud Firestore: Querying `issue_timeline`, `reminders`, etc.
*   **Other:** UI for Contact Tab, basic Chat View, History Tab; Logic for grouping history items by date.

**Milestone 5: Linked Accounts**
*   **Flutter Packages:**
    *   `cloud_firestore`: For managing `linked_accounts` and accessing shared data.
    *   State management package.
*   **Firebase Services:**
    *   Cloud Firestore: CRUD for `linked_accounts`.
    *   Firestore Security Rules: Implementing permission logic (View/Edit).
*   **Other:** UI for Linked Accounts Tab, Invite logic (backend potentially via Cloud Functions later if needed).

**Milestone 6: Settings & Subscription Management**
*   **Flutter Packages:**
    *   `cloud_firestore`: For user profile and subscription data.
    *   State management package.
*   **Firebase Services:**
    *   Cloud Firestore: CRUD for `users` profile, reading `subscriptions`.
*   **Other:** UI for Settings Tab, Subscription Management screen; Logic for updating user's plan.

**Milestone 7: Refinement & Advanced Backend Integration**
*   **Flutter Packages:**
    *   `firebase_storage`: For file uploads.
    *   `file_picker` or `image_picker`: To allow users to select files.
    *   `firebase_messaging`: To receive push notifications.
    *   `flutter_local_notifications`: To display notifications when the app is in the foreground.
    *   `cloud_functions` (optional, if needed for triggers): For backend logic.
*   **Firebase Services:**
    *   Cloud Storage: For storing uploaded files.
    *   Firebase Cloud Messaging (FCM): Setup required (APNs for iOS, config for Android).
    *   Cloud Functions (potentially requires Blaze plan): For notification triggers, complex backend tasks.
    *   Firestore & Storage Security Rules: Finalizing and testing.
*   **Other:** UI refinement across all screens, SVG icons.

**Milestone 8: Testing & Finalization**
*   **Flutter Packages:**
    *   `flutter_test` (built-in).
    *   `integration_test` (for end-to-end testing).
*   **Resources:**
    *   Comprehensive Test Plan.
    *   Testing on various Android/iOS devices/emulators.
*   **Other:** Bug tracking system (optional), final code review process.

**Next Step:** Draft the detailed milestone plan in Markdown format, incorporating objectives, deliverables, and estimated resources.
