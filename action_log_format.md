# Standardized Action Log Format for History Timeline

This document outlines the standardized format for `updateText` within the `HealthIssueUpdate` model when logging various system actions to the history timeline.

## General Principle

The `updateText` field will be used to store a human-readable description of the action. To allow for potential future enhancements like specific icons or filtering based on action type, a prefix will be used for system-generated logs.

The `updateDate` field will always reflect the timestamp of when the action occurred.

The `files` field in `HealthIssueUpdate` will only be populated if the action is directly related to one or more files (e.g., the file upload action itself).

## Log Formats by Action Type

1.  **Manual User Update:**
    *   **Prefix:** None (or implicitly "User Update:")
    *   **`updateText`:** The text directly entered by the user.
    *   **Example:** "Feeling much better today, pain has subsided."

2.  **File Uploaded:**
    *   **Prefix:** "File Uploaded: "
    *   **`updateText`:** "File Uploaded: [fileName] - Description: [fileDescription]"
        *   `[fileName]`: The name of the uploaded file.
        *   `[fileDescription]`: The description provided by the user for the file (if any).
    *   **Example:** "File Uploaded: blood_test_results_may_2025.pdf - Description: Latest blood work from Dr. Smith's clinic."
    *   **`files` field:** Could optionally store a reference to the uploaded file if needed directly in the log entry, though the primary file metadata is stored in the `HealthIssue`'s `fileUploads` list.

3.  **Follow-up Scheduled/Updated:**
    *   **Prefix:** "Follow-up Scheduled: " or "Follow-up Updated: "
    *   **`updateText`:** "Follow-up Scheduled: [Date] - Notes: [Notes]"
        *   `[Date]`: The date of the scheduled follow-up (e.g., YYYY-MM-DD).
        *   `[Notes]`: Any notes added by the user for the follow-up (if any).
    *   **Example:** "Follow-up Scheduled: 2025-07-15 - Notes: Discuss MRI results."

4.  **Reminder Added/Updated:**
    *   **Prefix:** "Reminder Set: " or "Reminder Updated: "
    *   **`updateText`:** "Reminder Set: [ReminderTitle] for [DateTime] - Details: [ReminderDetails]"
        *   `[ReminderTitle]`: A concise title or purpose of the reminder.
        *   `[DateTime]`: The date and time for the reminder (e.g., YYYY-MM-DD HH:mm).
        *   `[ReminderDetails]`: Any additional details for the reminder.
    *   **Example:** "Reminder Set: Take Medication X for 2025-05-07 08:00 - Details: Take with food."

## Implementation Notes

*   When these actions are performed, the respective service methods (e.g., in `HealthIssueService`) will be responsible for creating a `HealthIssueUpdate` object with the `updateText` formatted as described above and saving it to the `issue_updates` subcollection.
*   The UI displaying the timeline will show the `updateText` as is. Future enhancements could parse the prefix to display specific icons or apply different styling.

