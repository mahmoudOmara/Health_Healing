## Health Healing App: Feature Analysis

Based on the provided details, here is a breakdown of the core features and requirements:

**1. Core Concept:**
   - Subscription-based personalized health support.
   - Centralized platform for personal/family health management.
   - Human-first support (AI later).
   - Focus on medication adherence, appointments, logs.
   - B2C and B2B2C models.

**2. Authentication:**
   - Phone number + OTP verification.

**3. Health Issues Management:**
   - **Home Screen:** List issues (name + status badge), Add button, Search bar.
   - **Add Issue Popup:** Fields for Name, Start Date, Severity, Symptoms, Medications, Doctor/Clinic, File Upload, Recurring Toggle, Follow-Up Reminder.
   - **Detail View:** Add Update, Upload File, Book Follow-Up, Add Reminder buttons (popups). General info display. History timeline.
   - Real-time update of the home screen list upon saving a new issue.

**4. Communication:**
   - **Contact Tab:** Buttons for "Start Chat" (opens chat view) and "Request Call" (confirmation popup).
   - Sample chat interface/log.

**5. Calendar & Scheduling:**
   - **Calendar Tab:** Monthly grid view, day numbers only, next/back navigation, colored days with data.
   - Day selection shows logs/reminders below.
   - Event rows with clickable Done (✓) / Not Done (✗) icons (toggle status).
   - Filters: All, Medication, Appointments, Custom.

**6. History Tracking:**
   - **History Tab:** Daily grouped log of medications, file uploads, chats/calls, doctor visits, reminders.

**7. User Profile & Settings:**
   - **Settings Tab:** User Info (Name, DOB, Gender), Emergency Contact, Preferred Doctor/Clinic, Language Preference.

**8. Subscription Management:**
   - Display current bundle summary.
   - "Manage" button opens dedicated screen.
   - Subscription Management Screen: Show bundle benefits, toggle between Monthly/Yearly options, instant UI update on selection.

**9. Linked Accounts (Family/Dependents):**
   - **Linked Accounts Tab:** List linked accounts (e.g., Mom, Dad).
   - Actions: Add manually (full access), Send invite (View/Edit permission).
   - Clicking an account shows their Health Issues, Logs, Reminders.
   - Notifications for shared updates.
   - Linked account health issues are clickable for updates.

**10. Notifications:**
    - Medication reminders.
    - Appointment reminders.
    - Linked-account updates.
    - File uploads and follow-ups.
    - (Excluded: Motivational messages).

**11. UI/UX Requirements:**
    - Professional, clean, minimal, reliable medical app look.
    - Full screen per view.
    - Back button on secondary views.
    - Neat modals/popups.
    - Generous white space (padding p-4/p-6, margins space-y-4/space-y-6).
    - Strict typography hierarchy (Inter font, defined styles for titles, body, labels).
    - Minimalist components (subtle borders, light shadows, clean inputs).
    - Consistent color palette (primary accent, neutral grays, secondary status colors).
    - Standardized interactive elements (button styles, hover/active states, corner rounding).
    - Clean, outlined SVG icons.

**12. Interaction Requirements:**
    - Clickable list items opening detail views.
    - Action buttons opening popups.
    - Real-time list updates on save.
    - Clickable calendar days showing details.
    - Clickable event status toggles (✓/✗).
    - Clickable linked accounts showing details.
    - Chat button opens chat view.
    - Subscription selection updates UI instantly.

**13. Backend Requirements:**
    - Options: Firebase (preferred), Supabase, or custom API.
    - Needs to support all data storage, authentication, file uploads, and potentially real-time features (chat, notifications).

**Next Step:** Outline Firebase integration points based on these features.
