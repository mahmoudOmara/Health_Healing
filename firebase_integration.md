## Health Healing App: Firebase Integration Points

Based on the feature analysis, here is a proposed outline for integrating Firebase services:

**1. Firebase Authentication:**
   - **Service:** Firebase Authentication
   - **Method:** Phone Number + OTP verification for user login and registration.
   - **Data:** Stores user authentication credentials (UID, phone number).

**2. Data Storage (Cloud Firestore):**
   - **Service:** Cloud Firestore (NoSQL Database)
   - **Collections:**
     - `users`: Stores user profile information (Name, DOB, Gender, Emergency Contact, Preferred Doctor/Clinic, Language, Subscription Plan reference, etc.). Document ID = User UID.
     - `health_issues`: Stores details for each health issue (Name, Start Date, Severity, Symptoms, Medications, Doctor/Clinic, File references [paths in Cloud Storage], Recurring status, Follow-Up Reminder Date, User UID, Status Badge). Sub-collection or separate collection linked by User UID.
     - `issue_timeline`: Sub-collection under each `health_issue` document, storing historical updates, logs, file uploads, reminders added, follow-ups booked related to that specific issue (Timestamp, Type, Details, File reference).
     - `reminders`: Stores medication, appointment, and custom reminders (User UID, Type [Medication/Appointment/Custom], Title, Date/Time, Frequency [if recurring], Status [Pending/Done/Not Done], Associated Health Issue ID [optional]).
     - `linked_accounts`: Manages relationships and permissions between users (Owner User UID, Linked User UID, Permission Level [View/Edit], Invitation Status [Pending/Accepted]).
     - `chats`: Stores chat messages between users and care agents (Participants [User UID, Agent ID], Timestamp, Sender ID, Message Text).
     - `call_requests`: Logs user requests for calls (User UID, Timestamp, Status [Requested/Completed]).
     - `subscriptions`: Stores details about available subscription plans (Plan ID [Monthly/Yearly], Price, Benefits).
   - **Real-time Updates:** Utilize Firestore listeners (`snapshots`) to update UI elements in real-time (e.g., health issue list, chat messages, calendar events, subscription status).

**3. File Storage (Cloud Storage for Firebase):**
   - **Service:** Cloud Storage for Firebase
   - **Usage:** Store user-uploaded files (e.g., medical reports, prescriptions) associated with health issues.
   - **Structure:** Organize files in folders, potentially structured like `user_files/{user_uid}/{health_issue_id}/{file_name}`.
   - **Access Control:** Use Firebase Security Rules to control access based on user authentication and potentially linked account permissions.

**4. Notifications (Firebase Cloud Messaging - FCM):**
   - **Service:** Firebase Cloud Messaging (FCM)
   - **Usage:** Send push notifications to users for:
     - Medication reminders.
     - Appointment reminders.
     - Linked-account updates (new issues, logs, files shared).
     - File upload confirmations/follow-ups.
   - **Triggering:** Likely requires Cloud Functions to listen for Firestore events (e.g., new reminder added, reminder time approaching) or run scheduled tasks.

**5. Backend Logic (Cloud Functions for Firebase):**
   - **Service:** Cloud Functions for Firebase
   - **Usage:**
     - Trigger FCM notifications based on Firestore data changes or time-based schedules (e.g., check for upcoming reminders).
     - Handle backend logic for sending linked account invitations (e.g., creating invitation records, potentially sending an SMS/email if needed, though not explicitly requested yet).
     - Process subscription changes (e.g., update user profile, potentially interact with a payment gateway if real payments were implemented).
     - Manage complex data validation or aggregation if needed.

**6. Security (Firebase Security Rules):**
   - **Services:** Firestore Security Rules, Cloud Storage Security Rules
   - **Usage:** Define granular rules to:
     - Ensure users can only read/write their own data (profiles, health issues, reminders, etc.).
     - Allow users to read/write data shared with them via Linked Accounts based on defined permissions (View/Edit).
     - Protect sensitive data and prevent unauthorized access.

**Next Step:** Break down the app features into logical development milestones based on this integration plan.
