## Health Healing App: Milestone Objectives & Deliverables

Building upon the milestone breakdown, here are the specific objectives and deliverables for each:

**Milestone 1: Foundation & Authentication**
   - **Objectives:** Establish the basic project structure, implement core navigation, set up Firebase, and enable user login via phone OTP.
   - **Deliverables:**
     - Flutter project with basic folder structure and theme setup.
     - Functional bottom navigation bar.
     - Firebase project configured and linked to the Flutter app.
     - Clickable Login/Registration screens.
     - Functional Phone Number + OTP authentication flow.
     - Basic `users` collection in Firestore created upon registration.

**Milestone 2: Core Feature - Health Issues Management**
   - **Objectives:** Implement the primary feature of adding, viewing, searching, and managing health issues for the logged-in user.
   - **Deliverables:**
     - Functional Home Screen displaying a list of health issues from Firestore (real-time).
     - Functional search bar filtering the health issue list.
     - Functional "Add New Issue" button opening a popup.
     - Functional Add Health Issue popup saving data to Firestore.
     - Clickable list items opening a Health Issue Detail View.
     - Health Issue Detail View displaying issue information from Firestore.

**Milestone 3: Calendar & Reminders**
   - **Objectives:** Implement the calendar view for visualizing events and reminders, allow users to track completion, and add new reminders.
   - **Deliverables:**
     - Functional Calendar Tab with a monthly grid view and navigation.
     - Display of reminders/logs below the calendar when a day is selected.
     - Integration with Firestore to fetch and display `reminders`.
     - Functional Done/Not Done toggles updating reminder status in Firestore.
     - Functional filters (All, Medication, Appointments, Custom).
     - Functional "Add Reminder" popup saving data to Firestore.

**Milestone 4: Communication & History**
   - **Objectives:** Implement the basic UI for user communication (chat/call requests) and provide a consolidated view of historical user activity.
   - **Deliverables:**
     - Functional Contact Tab with "Start Chat" and "Request Call" buttons.
     - Basic Chat View UI (non-functional chat, placeholder messages).
     - Functional History Tab displaying a grouped daily log fetched from Firestore (`issue_timeline`, `reminders`, etc.).

**Milestone 5: Linked Accounts**
   - **Objectives:** Enable users to link other accounts (e.g., family members) and manage shared health information based on permissions.
   - **Deliverables:**
     - Functional Linked Accounts Tab displaying linked profiles.
     - Functional "Add Manually" and "Send Invite" actions (storing data in `linked_accounts` collection).
     - Ability to click a linked account and view their Health Issues, Logs, and Reminders (respecting View/Edit permissions).
     - Basic Firestore Security Rules implemented for linked account data access.

**Milestone 6: Settings & Subscription Management**
   - **Objectives:** Allow users to manage their profile information and view/change their subscription plan.
   - **Deliverables:**
     - Functional Settings Tab displaying user info from Firestore.
     - Ability to edit and save user profile information.
     - Functional Subscription section displaying the current plan.
     - Functional "Manage" button opening the Subscription Management screen.
     - Functional Subscription Management screen displaying plan benefits and allowing selection between Monthly/Yearly options.
     - User's selected subscription plan updated in Firestore and reflected instantly in the UI.

**Milestone 7: Refinement & Advanced Backend Integration**
   - **Objectives:** Enhance the application with file uploads, detailed issue updates, follow-up booking placeholders, push notifications, and ensure adherence to UI/UX guidelines.
   - **Deliverables:**
     - UI polished across all screens according to specified guidelines.
     - Functional file upload (using Cloud Storage) integrated into Add Issue and Detail View.
     - Functional "Add Update" popup saving logs to `issue_timeline`.
     - Functional "Book Follow-Up" popup (saving placeholder data).
     - Firebase Cloud Messaging (FCM) setup completed.
     - Basic push notifications implemented for reminders (triggered by Cloud Functions if necessary).
     - Comprehensive Firestore Security Rules tested and finalized.

**Milestone 8: Testing & Finalization**
   - **Objectives:** Ensure the application is stable, bug-free, performant, and meets all specified requirements before handoff.
   - **Deliverables:**
     - Comprehensive test report covering all features and user flows.
     - Resolved bugs and performance optimizations.
     - Final code cleanup and documentation.
     - Fully clickable prototype meeting all functional and UI requirements.

**Next Step:** Estimate required resources and dependencies for these milestones.
