import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health_healing/models/calendar_event.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/calendar_event_service.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:path/path.dart' as p; // For getting file extension
import 'package:uuid/uuid.dart'; // For generating unique IDs

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  final CalendarEventService _calendarEventService = CalendarEventService(); // Instantiate CalendarEventService
  late HealthIssue _currentIssue;
  bool _isDeletingFile = false;
  final Uuid _uuid = Uuid(); // UUID generator

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.healthIssue;
  }

  Future<void> _refreshIssueDetails() async {
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
          SnackBar(content: Text('Error refreshing issue details: ${e.toString()}')),
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
            healthIssue: _currentIssue,
            healthIssueService: _healthIssueService,
            onUpdateAdded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
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
            healthIssue: _currentIssue,
            healthIssueService: _healthIssueService,
            onFileUploaded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
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
            healthIssue: _currentIssue,
            // healthIssueService: _healthIssueService, // Not directly used, but could be for logging
            calendarEventService: _calendarEventService, // Pass CalendarEventService
            uuid: _uuid, // Pass Uuid
            onFollowUpBooked: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Follow-up details noted and logged.')),
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
            healthIssue: _currentIssue,
            calendarEventService: _calendarEventService, // Pass CalendarEventService
            uuid: _uuid, // Pass Uuid
            onReminderAdded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder added successfully.')),
                );
              }
            }
          ),
        );
      },
    );
  }

  void _showEditDescriptionDialog(BuildContext parentContext, Map<String, String> fileData) {
    final TextEditingController descriptionController = TextEditingController(text: fileData['description']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit File Description'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter file description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newDescription = descriptionController.text.trim();
                  List<Map<String, String>> updatedFileUploads = List.from(_currentIssue.fileUploads ?? []);
                  int fileIndex = updatedFileUploads.indexWhere((f) => f['fileId'] == fileData['fileId']);

                  if (fileIndex != -1) {
                    updatedFileUploads[fileIndex]['description'] = newDescription;
                    HealthIssue issueToUpdate = _currentIssue.copyWith(fileUploads: updatedFileUploads, updatedAt: Timestamp.now());
                    try {
                      await _healthIssueService.updateHealthIssue(issueToUpdate);
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Description updated successfully!')),
                        );
                        _refreshIssueDetails();
                        Navigator.of(dialogContext).pop(); // Close dialog after saving
                      }
                    } catch (e) {
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text('Failed to update description: ${e.toString()}')),
                        );
                      }
                    }
                  } else {
                     if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Error: Could not find file to update.')),
                        );
                      }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilePreviewModal(BuildContext context, Map<String, String> fileData) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final String? fileName = fileData["fileName"];
        final String? downloadURL = fileData["downloadURL"];
        final String? description = fileData["description"];
        final bool isImage = _isImageFileForThumbnail(fileName);

        return AlertDialog(
          title: Text(fileName ?? "File Preview"),
          contentPadding: const EdgeInsets.all(16.0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImage && downloadURL != null)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
                      ),
                      child: Image.network(
                        downloadURL,
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Column(
                            children: [
                              Icon(_getIconForFileType(fileName!), size: 60.0, color: Theme.of(context).colorScheme.error),
                              const SizedBox(height: 8),
                              const Text("Error loading preview", textAlign: TextAlign.center),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                else if (fileName != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIconForFileType(fileName), size: 80.0, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16.0),
                        Text(
                          "Cannot preview this file type directly.",
                          textAlign: TextAlign.center,
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description:", style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(description),
                      ],
                    )
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFile(Map<String, String> fileData) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the file "${fileData['fileName'] ?? 'this file'}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        _isDeletingFile = true;
      });
      try {
        await _healthIssueService.deleteFileFromIssue(_currentIssue.id!, fileData);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully.')),
            );
        }
        _refreshIssueDetails();
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete file: ${e.toString()}')),
            );
        }
      } finally {
        if (mounted) {
            setState(() {
            _isDeletingFile = false;
            });
        }
      }
    }
  }

  Widget _buildActionHub(BuildContext context) {
    String formatButtonLabel(String label) {
      if (!label.contains('\n') && label.length < 15) {
        int middle = (label.length / 2).round();
        if (label.contains(" ")){
            middle = label.indexOf(" ");
             return "${label.substring(0, middle)}\n${label.substring(middle + 1)}";
        } else {
            return "$label\n ";
        }
      }
      return label;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStyledCompactActionButton(context, icon: Icons.update, label: formatButtonLabel("Add Update"), onPressed: _showAddUpdateBottomSheet),
          const SizedBox(width: 5.0),
          _buildStyledCompactActionButton(context, icon: Icons.upload_file_outlined, label: formatButtonLabel("Upload File"), onPressed: _showUploadFileBottomSheet),
          const SizedBox(width: 5.0),
          _buildStyledCompactActionButton(context, icon: Icons.calendar_today, label: formatButtonLabel("Book Follow-Up"), onPressed: _showBookFollowUpBottomSheet),
          const SizedBox(width: 5.0),
          _buildStyledCompactActionButton(context, icon: Icons.alarm_add, label: formatButtonLabel("Add Reminder"), onPressed: _showAddReminderBottomSheet),
        ],
      ),
    );
  }

  Widget _buildStyledCompactActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Expanded(
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 28.0, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 6.0),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIssue.issueName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditHealthIssueScreen(healthIssue: _currentIssue),
                ),
              );
              if (result == true) {
                _refreshIssueDetails();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshIssueDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildDetailRow("Status:", _currentIssue.status),
                      _buildDetailRow("Start Date:", DateFormat.yMMMd().format(_currentIssue.startDate.toDate())),
                      _buildDetailRow("Severity:", _currentIssue.severityLevel),
                      if (_currentIssue.symptoms != null && _currentIssue.symptoms!.isNotEmpty)
                        _buildDetailRow("Symptoms:", _currentIssue.symptoms!),
                      if (_currentIssue.medications != null && _currentIssue.medications!.isNotEmpty)
                        _buildDetailRow("Medications:", _currentIssue.medications!),
                      if (_currentIssue.doctorClinic != null && _currentIssue.doctorClinic!.isNotEmpty)
                        _buildDetailRow("Doctor/Clinic:", _currentIssue.doctorClinic!),
                      _buildDetailRow("Recurring:", _currentIssue.isRecurring ? "Yes" : "No"),
                      if (_currentIssue.nextFollowUpDate != null)
                        _buildDetailRow("Next Follow-Up:", DateFormat.yMMMd().add_jm().format(_currentIssue.nextFollowUpDate!.toDate())),
                    ],
                  ),
                ),
              ),
              _buildActionHub(context),
              const SizedBox(height: 16.0),
              Text("Uploaded Files", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              _buildUploadedFilesList(),
              const SizedBox(height: 16.0),
              Text("History Timeline", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              _buildHistoryTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildUploadedFilesList() {
    if (_currentIssue.fileUploads == null || _currentIssue.fileUploads!.isEmpty) {
      return const Center(child: Text("No files uploaded yet."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _currentIssue.fileUploads!.length,
      itemBuilder: (context, index) {
        final fileData = _currentIssue.fileUploads![index];
        final String? fileName = fileData["fileName"];
        final String? downloadURL = fileData["downloadURL"];
        final String? description = fileData["description"];

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            leading: SizedBox(
              width: 50,
              height: 50,
              child: _isImageFileForThumbnail(fileName) && downloadURL != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        downloadURL,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(_getIconForFileType(fileName!), size: 30),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                        },
                      ),
                    )
                  : Icon(_getIconForFileType(fileName), size: 30.0, color: Theme.of(context).colorScheme.secondary),
            ),
            title: Text(fileName ?? "Unnamed File", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: description != null && description.isNotEmpty
                ? Text(description, maxLines: 2, overflow: TextOverflow.ellipsis)
                : const Text("No description", style: TextStyle(fontStyle: FontStyle.italic)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: "Edit Description",
                  onPressed: () => _showEditDescriptionDialog(context, fileData),
                ),
                if (!_isDeletingFile) // Show delete button only if not currently deleting
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                    tooltip: "Delete File",
                    onPressed: () => _deleteFile(fileData),
                  ),
                if (_isDeletingFile) // Show progress indicator if deleting
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            onTap: () => _showFilePreviewModal(context, fileData),
          ),
        );
      },
    );
  }

  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    final extension = p.extension(fileName.toLowerCase());
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Icons.image_outlined;
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined; // More generic document icon
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_outlined;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow_outlined;
      case '.txt':
        return Icons.article_outlined;
      case '.zip':
      case '.rar':
        return Icons.archive_outlined;
      case '.mp3':
      case '.wav':
      case '.aac':
        return Icons.audiotrack_outlined;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Icons.videocam_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final extension = p.extension(fileName.toLowerCase());
    return [
      
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'
    ].contains(extension);
  }

  Widget _buildHistoryTimeline() {
    if (_currentIssue.id == null) {
      return const Center(child: Text("Issue ID is missing, cannot load timeline."));
    }
    return StreamBuilder<List<HealthIssueUpdate>>(
      stream: _healthIssueService.getHealthIssueUpdatesStream(_currentIssue.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading timeline: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No updates or activities logged yet."));
        }

        final updates = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            final update = updates[index];
            IconData timelineIcon = Icons.info_outline; // Default icon
            Color? iconColor = Theme.of(context).colorScheme.secondary;
            String title = "Update";

            if (update.updateType == "file_upload") {
              timelineIcon = Icons.upload_file_outlined;
              title = "File Uploaded";
            } else if (update.updateType == "follow_up") {
              timelineIcon = Icons.calendar_today_outlined;
              title = "Follow-up Logged";
            } else if (update.updateType == "reminder_added") {
              timelineIcon = Icons.alarm_add_outlined;
              title = "Reminder Logged";
            } else if (update.updateType == "general_update") {
               timelineIcon = Icons.article_outlined;
               title = "General Update";
            }

            return Card(
              elevation: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(timelineIcon, size: 28.0, color: iconColor),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            update.updateText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            DateFormat.yMMMd().add_jm().format(update.timestamp.toDate()),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Bottom Sheet Content Widgets ---

class _AddUpdateBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService;
  final VoidCallback onUpdateAdded;

  const _AddUpdateBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.onUpdateAdded,
  });

  @override
  State<_AddUpdateBottomSheetContent> createState() => _AddUpdateBottomSheetContentState();
}

class _AddUpdateBottomSheetContentState extends State<_AddUpdateBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _updateTextController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _updateTextController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final updateText = _updateTextController.text.trim();
        await widget.healthIssueService.addHealthIssueUpdate(
          widget.healthIssue.id!,
          updateText,
          updateType: "general_update", // Explicitly general update
        );
        widget.onUpdateAdded();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add update: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Add New Update",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _updateTextController,
              decoration: const InputDecoration(
                labelText: "Update Details",
                hintText: "Enter details about the update...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter update details.";
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text("Save Update"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: _isLoading ? null : _saveUpdate,
            ),
            if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20.0), // Added padding at the bottom
          ],
        ),
      ),
    );
  }
}

class _UploadFileBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService;
  final VoidCallback onFileUploaded;

  const _UploadFileBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.onFileUploaded,
  });

  @override
  State<_UploadFileBottomSheetContent> createState() => _UploadFileBottomSheetContentState();
}

class _UploadFileBottomSheetContentState extends State<_UploadFileBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> _uploadAndSaveFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first.")),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final description = _descriptionController.text.trim();
        await widget.healthIssueService.uploadFileWithDescription(
          widget.healthIssue.id!,
          _selectedFile!,
          _selectedFileName ?? "unknown_file",
          description,
        );
        widget.onFileUploaded();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload file: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Upload File",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file_outlined),
              label: const Text("Select File"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
              ),
              onPressed: _isLoading ? null : _pickFile,
            ),
            const SizedBox(height: 12.0),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(_getIconForFileType(_selectedFileName), color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_selectedFileName ?? "No file selected", overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No file selected.", textAlign: TextAlign.center),
              ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "File Description (Optional)",
                hintText: "Enter a brief description for the file...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text("Upload and Save File"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: (_isLoading || _selectedFile == null) ? null : _uploadAndSaveFile,
            ),
            if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20.0), // Added padding at the bottom
          ],
        ),
      ),
    );
  }

  // Helper to get icon for file type (can be moved to a utility class)
  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    final extension = p.extension(fileName.toLowerCase());
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Icons.image_outlined;
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_outlined;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

class _BookFollowUpBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final CalendarEventService calendarEventService;
  final Uuid uuid;
  final VoidCallback onFollowUpBooked;

  const _BookFollowUpBottomSheetContent({
    required this.healthIssue,
    required this.calendarEventService,
    required this.uuid,
    required this.onFollowUpBooked,
  });

  @override
  State<_BookFollowUpBottomSheetContent> createState() => _BookFollowUpBottomSheetContentState();
}

class _BookFollowUpBottomSheetContentState extends State<_BookFollowUpBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _followUpNotesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _followUpNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveFollowUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a follow-up date.")),
        );
        return;
      }

      setState(() { _isLoading = true; });
      try {
        final notes = _followUpNotesController.text.trim();
        final String eventId = widget.uuid.v4();
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception("User not logged in.");
        }

        DateTime finalDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime?.hour ?? 0, 
          _selectedTime?.minute ?? 0,
        );

        final followUpEvent = CalendarEvent(
          eventId: eventId,
          healthIssueId: widget.healthIssue.id!,
          healthIssueName: widget.healthIssue.issueName,
          eventTitle: "Follow-up: ${widget.healthIssue.issueName}",
          eventDescription: notes,
          eventDate: Timestamp.fromDate(finalDateTime),
          eventTime: _selectedTime != null ? _selectedTime!.format(context) : null,
          eventType: "Follow-up", // Specific type
          createdAt: Timestamp.now(),
          userId: currentUser.uid,
        );

        await widget.calendarEventService.addCalendarEvent(followUpEvent);
        
        // Also, log this action to the general issue timeline if desired (using HealthIssueService)
        // This part is optional and depends on whether you want duplicate logging or specific formatting
        // For now, we assume the CalendarEvent itself is the primary log for this action.
        // Example: 
        // await HealthIssueService().addHealthIssueUpdate(
        //   widget.healthIssue.id!,
        //   "Follow-up scheduled for ${DateFormat.yMMMd().add_jm().format(finalDateTime)}. Notes: $notes",
        //   updateType: "follow_up_scheduled", 
        // );

        widget.onFollowUpBooked();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to book follow-up: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Book Follow-Up",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _followUpNotesController,
              decoration: const InputDecoration(
                labelText: "Follow-Up Notes (Optional)",
                hintText: "Enter any notes for the follow-up...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_selectedDate == null
                  ? "Select Follow-Up Date*"
                  : DateFormat.yMMMd().format(_selectedDate!)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickDate(context),
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: Text(_selectedTime == null
                  ? "Select Follow-Up Time (Optional)"
                  : _selectedTime!.format(context)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickTime(context),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Save Follow-Up"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: _isLoading ? null : _saveFollowUp,
            ),
            if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

class _AddReminderBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final CalendarEventService calendarEventService;
  final Uuid uuid;
  final VoidCallback onReminderAdded;

  const _AddReminderBottomSheetContent({
    required this.healthIssue,
    required this.calendarEventService,
    required this.uuid,
    required this.onReminderAdded,
  });

  @override
  State<_AddReminderBottomSheetContent> createState() => _AddReminderBottomSheetContentState();
}

class _AddReminderBottomSheetContentState extends State<_AddReminderBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _reminderTitleController = TextEditingController();
  final _reminderDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedEventType = "Custom"; // Default to Custom
  bool _isLoading = false;

  final List<String> _eventTypes = ["Medication", "Appointment", "Custom", "Follow-up"];

  @override
  void dispose() {
    _reminderTitleController.dispose();
    _reminderDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a reminder date.")),
        );
        return;
      }
      if (_selectedEventType == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a reminder type.")),
        );
        return;
      }

      setState(() { _isLoading = true; });
      try {
        final title = _reminderTitleController.text.trim();
        final description = _reminderDescriptionController.text.trim();
        final String eventId = widget.uuid.v4();
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception("User not logged in.");
        }

        DateTime finalDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime?.hour ?? 0,
          _selectedTime?.minute ?? 0,
        );

        final reminderEvent = CalendarEvent(
          eventId: eventId,
          healthIssueId: widget.healthIssue.id!,
          healthIssueName: widget.healthIssue.issueName,
          eventTitle: title,
          eventDescription: description.isNotEmpty ? description : null,
          eventDate: Timestamp.fromDate(finalDateTime),
          eventTime: _selectedTime != null ? _selectedTime!.format(context) : null,
          eventType: _selectedEventType!,
          createdAt: Timestamp.now(),
          userId: currentUser.uid,
        );

        await widget.calendarEventService.addCalendarEvent(reminderEvent);
        widget.onReminderAdded();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add reminder: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Add Reminder",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _reminderTitleController,
              decoration: const InputDecoration(
                labelText: "Reminder Title*",
                hintText: "e.g., Take Vitamin D, Doctor's Appointment",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a reminder title.";
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _reminderDescriptionController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                hintText: "Additional details for the reminder...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Reminder Type*",
                border: OutlineInputBorder(),
              ),
              value: _selectedEventType,
              items: _eventTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedEventType = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a type' : null,
            ),
            const SizedBox(height: 16.0),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_selectedDate == null
                  ? "Select Reminder Date*"
                  : DateFormat.yMMMd().format(_selectedDate!)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickDate(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_outlined),
              title: Text(_selectedTime == null
                  ? "Select Reminder Time (Optional)"
                  : _selectedTime!.format(context)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickTime(context),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.alarm_add_outlined),
              label: const Text("Save Reminder"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: _isLoading ? null : _saveReminder,
            ),
            if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

