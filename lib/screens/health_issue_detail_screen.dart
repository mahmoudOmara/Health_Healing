import \'dart:io\';
import \'package:flutter/material.dart\';
import \'package:health_healing/models/calendar_event.dart\';
import \'package:health_healing/models/health_issue.dart\';
import \'package:health_healing/models/health_issue_update.dart\';
import \'package:health_healing/services/calendar_event_service.dart\';
import \'package:health_healing/services/health_issue_service.dart\';
import \'package:intl/intl.dart\'; // For date formatting
import \'package:health_healing/screens/add_edit_health_issue_screen.dart\';
import \'package:cloud_firestore/cloud_firestore.dart\';
import \'package:firebase_auth/firebase_auth.dart\';
import \'package:file_picker/file_picker.dart\'; // For file picking
import \'package:path/path.dart\' as p; // For getting file extension
import \'package:uuid/uuid.dart\'; // For generating unique IDs

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  final CalendarEventService _calendarEventService = CalendarEventService();
  late HealthIssue _currentIssue;
  bool _isDeletingFile = false;
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.healthIssue;
    // Listen to stream for real-time updates to _currentIssue
    _healthIssueService.getHealthIssueStream(widget.healthIssue.id!).listen((updatedIssue) {
      if (mounted) {
        setState(() {
          _currentIssue = updatedIssue;
        });
      }
    }, onError: (error) {
      print("Error listening to issue stream: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(\'Error fetching live issue details: ${error.toString()}\')),
        );
      }
    });
  }

  Future<void> _refreshIssueDetails() async {
    // This method is now less critical if the stream is working,
    // but can be kept for explicit refresh scenarios or as a fallback.
    if (widget.healthIssue.id == null) return;
    if (!mounted) return;
    try {
      final updatedIssue = await _healthIssueService.getHealthIssueStream(widget.healthIssue.id!).first;
      if (mounted) {
        setState(() {
          _currentIssue = updatedIssue;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(\'Error refreshing issue details: ${e.toString()}\')),
        );
      }
    }
  }

  void _showAddUpdateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 20.0,
          ),
          child: _AddUpdateBottomSheetContent(
            healthIssue: _currentIssue, // Use _currentIssue which is updated by stream
            healthIssueService: _healthIssueService,
            onUpdateAdded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              // _refreshIssueDetails(); // Stream should handle refresh
            }
          ),
        );
      },
    );
  }

  void _showUploadFileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 20.0,
          ),
          child: _UploadFileBottomSheetContent(
            healthIssue: _currentIssue, // Use _currentIssue
            healthIssueService: _healthIssueService,
            onFileUploaded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              // _refreshIssueDetails(); // Stream should handle refresh
            }
          ),
        );
      },
    );
  }

  void _showBookFollowUpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 20.0,
          ),
          child: _BookFollowUpBottomSheetContent(
            healthIssue: _currentIssue, // Use _currentIssue
            healthIssueService: _healthIssueService, // Pass HealthIssueService
            calendarEventService: _calendarEventService,
            uuid: _uuid,
            onFollowUpBooked: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              // _refreshIssueDetails(); // Stream should handle refresh
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(\'Follow-up details updated and logged.\')),
                );
              }
            }
          ),
        );
      },
    );
  }

  void _showAddReminderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 20.0,
          ),
          child: _AddReminderBottomSheetContent(
            healthIssue: _currentIssue, // Use _currentIssue
            healthIssueService: _healthIssueService, // Pass HealthIssueService
            calendarEventService: _calendarEventService,
            uuid: _uuid,
            onReminderAdded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              // _refreshIssueDetails(); // Stream should handle refresh
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(\'Reminder added and logged.\')),
                );
              }
            }
          ),
        );
      },
    );
  }

  void _showEditDescriptionDialog(BuildContext parentContext, Map<String, String> fileData) {
    final TextEditingController descriptionController = TextEditingController(text: fileData[\'description\']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(\'Edit File Description\'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: \'Description\',
                hintText: \'Enter file description\',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(\'Cancel\'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text(\'Save\'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newDescription = descriptionController.text.trim();
                  List<Map<String, String>> updatedFileUploads = List.from(_currentIssue.fileUploads ?? []);
                  int fileIndex = updatedFileUploads.indexWhere((f) => f[\'fileId\'] == fileData[\'fileId\']);

                  if (fileIndex != -1) {
                    updatedFileUploads[fileIndex][\'description\'] = newDescription;
                    HealthIssue issueToUpdate = _currentIssue.copyWith(fileUploads: updatedFileUploads, updatedAt: Timestamp.now());
                    try {
                      await _healthIssueService.updateHealthIssue(issueToUpdate);
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text(\'Description updated successfully!\')),
                        );
                        // _refreshIssueDetails(); // Stream should handle refresh
                        Navigator.of(dialogContext).pop(); // Close dialog after saving
                      }
                    } catch (e) {
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text(\'Failed to update description: ${e.toString()}\')),
                        );
                      }
                    }
                  } else {
                     if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text(\'Error: Could not find file to update.\
(truncated to the first 4000 words, please use file_read tool with start_line=400 to read more.)
