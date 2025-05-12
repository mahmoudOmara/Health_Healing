# Milestone 3: Calendar & Reminders - Todo List

## 1. Data Model and Firestore Setup

- [x] **1.1. Define/Update Reminder/Event Data Model:** Create or modify a data model (e.g., `CalendarEvent`) with fields: `eventId`, `healthIssueId`, `healthIssueName`, `eventTitle`, `eventDescription`, `eventDate`, `eventTime`, `eventType`, `isDone`, `createdAt`, `userId`.
- [x] **1.2. Firestore Collection Setup:** Establish a new top-level Firestore collection (e.g., `calendarEvents`) and define necessary indexes.

## 2. Service Layer Implementation

- [x] **2.1. Create/Update CalendarEventService:** Implement service methods for `addCalendarEvent`, `updateCalendarEvent`, `deleteCalendarEvent`, `getCalendarEventsForDay`, `getCalendarEventsForMonth`, `getCalendarEventsForIssue`, and `getAllHealthIssues`.

## 3. UI Implementation: Adding/Editing Events

- [x] **3.1. Modify "Add Reminder" in Health Issue Detail Screen:** Update the existing interface to include `eventType` selection and save as a `CalendarEvent` linked to the current `healthIssueId`.
- [x] **3.2. Implement "Add Event" from Calendar Tab:** Create a new interface (bottom sheet/dialog) to add events from the Calendar Tab, including selection of parent `HealthIssue` and `eventType`.

## 4. UI Implementation: Calendar Tab

- [x] **4.1. Basic Calendar Tab Structure:** Create the Calendar Tab screen/widget, integrate `table_calendar`, and implement month navigation.
- [x] **4.2. Displaying Events Below Calendar:** Fetch and display `CalendarEvent`s for the selected day, showing `eventTitle`, `eventType`, linked `healthIssueName`, `eventTime`, and `isDone` toggle.
- [x] **4.3. Implement Status Toggling:** Enable users to mark events as "Done"/"Not Done", persisting changes via the service.
- [x] **4.4. Implement Filtering:** Add UI for filtering the event list by `eventType` ("All", "Medication", "Appointments", "Custom") and update display logic.