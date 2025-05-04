# Health Healing App: Development Milestone Plan

This document outlines the proposed development plan, broken down into milestones, for the Health Healing Flutter application with Firebase integration. Each milestone includes objectives, deliverables, key features covered, and estimated resources.

---

**Milestone 1: Foundation & Authentication**

*   **Objectives:** Establish the basic project structure, implement core navigation, set up Firebase, and enable user login via phone OTP.
*   **Deliverables:**
    *   Flutter project with basic folder structure and theme setup.
    *   Functional bottom navigation bar.
    *   Firebase project configured and linked to the Flutter app.
    *   Clickable Login/Registration screens.
    *   Functional Phone Number + OTP authentication flow.
    *   Basic `users` collection in Firestore created upon registration.
*   **Key Features Covered:** Basic App Structure, UI Theme, Bottom Navigation, Firebase Setup, Phone + OTP Authentication.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `firebase_core`, `firebase_auth`, `provider` / `flutter_riverpod`, `google_fonts`.
    *   Firebase Services: Firebase Authentication (Phone), Cloud Firestore.
    *   Other: UI components, `Inter` font file.

---

**Milestone 2: Core Feature - Health Issues Management**

*   **Objectives:** Implement the primary feature of adding, viewing, searching, and managing health issues for the logged-in user.
*   **Deliverables:**
    *   Functional Home Screen displaying a list of health issues from Firestore (real-time).
    *   Functional search bar filtering the health issue list.
    *   Functional "Add New Issue" button opening a popup.
    *   Functional Add Health Issue popup saving data to Firestore.
    *   Clickable list items opening a Health Issue Detail View.
    *   Health Issue Detail View displaying issue information from Firestore.
*   **Key Features Covered:** Health Issue Listing (Home Screen), Add Health Issue, View Health Issue Details, Search/Filter Issues, Real-time Updates.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `cloud_firestore`, `intl`, `uuid` (optional), state management.
    *   Firebase Services: Cloud Firestore (CRUD for `health_issues`).
    *   Other: UI for screens/popups, Search logic.

---

**Milestone 3: Calendar & Reminders**

*   **Objectives:** Implement the calendar view for visualizing events and reminders, allow users to track completion, and add new reminders.
*   **Deliverables:**
    *   Functional Calendar Tab with a monthly grid view and navigation.
    *   Display of reminders/logs below the calendar when a day is selected.
    *   Integration with Firestore to fetch and display `reminders`.
    *   Functional Done/Not Done toggles updating reminder status in Firestore.
    *   Functional filters (All, Medication, Appointments, Custom).
    *   Functional "Add Reminder" popup saving data to Firestore.
*   **Key Features Covered:** Calendar View, Event/Reminder Display, Status Toggling, Filtering, Add Reminder.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `table_calendar`, `cloud_firestore`, `intl`, state management.
    *   Firebase Services: Cloud Firestore (CRUD for `reminders`).
    *   Other: Calendar UI, Reminder data model, Filter logic.

---

**Milestone 4: Communication & History**

*   **Objectives:** Implement the basic UI for user communication (chat/call requests) and provide a consolidated view of historical user activity.
*   **Deliverables:**
    *   Functional Contact Tab with "Start Chat" and "Request Call" buttons.
    *   Basic Chat View UI (non-functional chat, placeholder messages).
    *   Functional History Tab displaying a grouped daily log fetched from Firestore (`issue_timeline`, `reminders`, etc.).
*   **Key Features Covered:** Contact Options (UI), Basic Chat UI, History Log Display.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `cloud_firestore`, `intl`, state management.
    *   Firebase Services: Cloud Firestore (Querying history data).
    *   Other: UI for tabs, History grouping logic.

---

**Milestone 5: Linked Accounts**

*   **Objectives:** Enable users to link other accounts (e.g., family members) and manage shared health information based on permissions.
*   **Deliverables:**
    *   Functional Linked Accounts Tab displaying linked profiles.
    *   Functional "Add Manually" and "Send Invite" actions (storing data in `linked_accounts` collection).
    *   Ability to click a linked account and view their Health Issues, Logs, and Reminders (respecting View/Edit permissions).
    *   Basic Firestore Security Rules implemented for linked account data access.
*   **Key Features Covered:** Linked Account Listing, Add/Invite Linked Accounts, Viewing Shared Data, Basic Permissions.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `cloud_firestore`, state management.
    *   Firebase Services: Cloud Firestore (CRUD for `linked_accounts`), Firestore Security Rules.
    *   Other: UI for Linked Accounts, Invite logic placeholder.

---

**Milestone 6: Settings & Subscription Management**

*   **Objectives:** Allow users to manage their profile information and view/change their subscription plan.
*   **Deliverables:**
    *   Functional Settings Tab displaying user info from Firestore.
    *   Ability to edit and save user profile information.
    *   Functional Subscription section displaying the current plan.
    *   Functional "Manage" button opening the Subscription Management screen.
    *   Functional Subscription Management screen displaying plan benefits and allowing selection between Monthly/Yearly options.
    *   User's selected subscription plan updated in Firestore and reflected instantly in the UI.
*   **Key Features Covered:** User Profile Management, View Subscription, Manage Subscription Plan Selection.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `cloud_firestore`, state management.
    *   Firebase Services: Cloud Firestore (CRUD for `users`, reading `subscriptions`).
    *   Other: UI for Settings/Subscription screens, Plan update logic.

---

**Milestone 7: Refinement & Advanced Backend Integration**

*   **Objectives:** Enhance the application with file uploads, detailed issue updates, follow-up booking placeholders, push notifications, and ensure adherence to UI/UX guidelines.
*   **Deliverables:**
    *   UI polished across all screens according to specified guidelines (whitespace, typography, colors, components).
    *   Functional file upload (using Cloud Storage) integrated into Add Issue and Detail View.
    *   Functional "Add Update" popup saving logs to `issue_timeline`.
    *   Functional "Book Follow-Up" popup (saving placeholder data).
    *   Firebase Cloud Messaging (FCM) setup completed.
    *   Basic push notifications implemented for reminders (triggered by Cloud Functions if necessary).
    *   Comprehensive Firestore Security Rules tested and finalized.
*   **Key Features Covered:** UI/UX Refinement, File Uploads, Issue Updates/Timeline, Follow-Up Placeholder, Push Notifications Setup, Security Rules Finalization.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `firebase_storage`, `file_picker`/`image_picker`, `firebase_messaging`, `flutter_local_notifications`, `cloud_functions` (optional).
    *   Firebase Services: Cloud Storage, FCM, Cloud Functions (optional, potentially Blaze plan), Firestore & Storage Security Rules.
    *   Other: UI refinement, SVG icons.

---

**Milestone 8: Testing & Finalization**

*   **Objectives:** Ensure the application is stable, bug-free, performant, and meets all specified requirements before handoff.
*   **Deliverables:**
    *   Comprehensive test report covering all features and user flows.
    *   Resolved bugs and performance optimizations.
    *   Final code cleanup and documentation.
    *   Fully clickable prototype meeting all functional and UI requirements.
*   **Key Features Covered:** Quality Assurance, Bug Fixing, Performance Optimization, Documentation.
*   **Estimated Resources/Dependencies:**
    *   Flutter Packages: `flutter_test`, `integration_test`.
    *   Resources: Test Plan, Testing on various devices/emulators.
    *   Other: Bug tracking (optional), Code review.

---

**Next Steps:** Review this plan. Once approved, we can begin development starting with Milestone 1.
