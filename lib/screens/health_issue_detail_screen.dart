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
                          const SnackBar(content: Text(\'Error: Could not find file to update.\')),
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
          title: const Text(\'Confirm Deletion\'),
          content: Text(\'Are you sure you want to delete the file "${fileData[\'fileName\'] ?? \'this file\'}"?\'),
          actions: <Widget>[
            TextButton(
              child: const Text(\'Cancel\'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
              child: const Text(\'Delete\'),
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
            const SnackBar(content: Text(\'File deleted successfully.\')),
            );
        }
        // _refreshIssueDetails(); // Stream should handle refresh
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(\'Failed to delete file: ${e.toString()}\')),
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
      if (!label.contains(\'\n\') && label.length < 15) {
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
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
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

  Widget _buildFileThumbnail(BuildContext context, Map<String, String> fileData) {
    final String? fileName = fileData["fileName"];
    final String? downloadURL = fileData["downloadURL"];
    final String? description = fileData["description"];
    final bool isImage = _isImageFileForThumbnail(fileName);

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: isImage && downloadURL != null
            ? SizedBox(
                width: 50,
                height: 50,
                child: Image.network(
                  downloadURL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(_getIconForFileType(fileName!), size: 30),
                ),
              )
            : Icon(_getIconForFileType(fileName), size: 30),
        title: Text(description ?? fileName ?? "Uploaded File", style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        // subtitle: Text(fileName ?? "", style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: "Edit Description",
              onPressed: () => _showEditDescriptionDialog(context, fileData),
            ),
            if (_isDeletingFile && _currentIssue.fileUploads?.firstWhere((f) => f[\'fileId\'] == fileData[\'fileId\'], orElse: () => {}) == fileData)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                tooltip: "Delete File",
                onPressed: () => _deleteFile(fileData),
              ),
          ],
        ),
        onTap: () => _showFilePreviewModal(context, fileData),
      ),
    );
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final ext = p.extension(fileName.toLowerCase());
    return ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" || ext == ".webp";
  }

  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final ext = p.extension(fileName.toLowerCase());
    switch (ext) {
      case ".pdf":
        return Icons.picture_as_pdf;
      case ".doc":
      case ".docx":
        return Icons.description; // Or a more specific Word icon if available
      case ".xls":
      case ".xlsx":
        return Icons.assessment; // Or a more specific Excel icon
      case ".ppt":
      case ".pptx":
        return Icons.slideshow;
      case ".txt":
        return Icons.article;
      case ".zip":
      case ".rar":
        return Icons.archive;
      default:
        if (_isImageFileForThumbnail(fileName)) return Icons.image;
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIssue.issueName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Issue",
            onPressed: () async {
              final result = await Navigator.push(
                context,
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentIssue.issueName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _currentIssue.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Icon(Icons.healing_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8.0),
                          Text(
                            "Status: ${_currentIssue.status}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8.0),
                          Text(
                            "Started: ${DateFormat.yMMMd().format(_currentIssue.startDate.toDate())}",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      if (_currentIssue.nextFollowUpDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.event_repeat_outlined, size: 18, color: Theme.of(context).colorScheme.tertiary),
                              const SizedBox(width: 8.0),
                              Text(
                                "Next Follow-up: ${DateFormat.yMMMd().format(_currentIssue.nextFollowUpDate!.toDate())}",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildActionHub(context),
              const SizedBox(height: 16.0),
              Text("Uploaded Files", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              _currentIssue.fileUploads == null || _currentIssue.fileUploads!.isEmpty
                  ? const Text("No files uploaded yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentIssue.fileUploads!.length,
                      itemBuilder: (context, index) {
                        final fileData = _currentIssue.fileUploads![index];
                        return _buildFileThumbnail(context, fileData);
                      },
                    ),
              const SizedBox(height: 24.0),
              Text("History Timeline", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8.0),
              StreamBuilder<List<HealthIssueUpdate>>(
                stream: _healthIssueService.getHealthIssueUpdatesStream(_currentIssue.id!, userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Error loading updates: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No updates recorded yet.");
                  }
                  final updates = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: updates.length,
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      return Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(_getIconForUpdateType(update.updateType), color: Theme.of(context).colorScheme.secondary),
                          title: Text(update.updateText, style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text(
                            "${DateFormat.yMMMd().add_jm().format(update.timestamp.toDate())} - ${update.updateType ?? \'General Update\'}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForUpdateType(String? updateType) {
    switch (updateType) {
      case "File Upload":
        return Icons.attach_file;
      case "Follow-up Booked":
      case "Follow-up Updated":
        return Icons.calendar_today;
      case "Reminder Added":
      case "Reminder Updated":
        return Icons.alarm;
      case "Description Edit":
        return Icons.edit_note;
      default:
        return Icons.history_edu_outlined;
    }
  }
}

// --- Bottom Sheet for Adding an Update ---
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

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.healthIssueService.addHealthIssueUpdate(
          widget.healthIssue.id!,
          _updateTextController.text.trim(),
          // updateType: "General Update", // Or let the service handle default if null
        );
        widget.onUpdateAdded();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(\'Failed to add update: ${e.toString()}\')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Add New Update",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _updateTextController,
              decoration: const InputDecoration(
                labelText: "Update Details",
                hintText: "Enter your update here...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter an update.";
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text("Save Update"),
                    onPressed: _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
            const SizedBox(height: 16.0), // Added padding below button
          ],
        ),
      ),
    );
  }
}

// --- Bottom Sheet for Uploading a File ---
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
  String? _fileName;
  bool _isLoading = false;
  String? _filePreviewError;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _filePreviewError = null; // Reset error on new pick
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(\'Error picking file: ${e.toString()}\')),
        );
      }
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(\'Please select a file to upload.\')),
        );
      }
      return;
    }
    // No form validation needed if description is optional
    // if (_formKey.currentState!.validate()) { 
      setState(() {
        _isLoading = true;
      });

      try {
        String originalFileName = _fileName ?? _selectedFile!.path.split(\'/\').last;
        
        // The service now handles adding the HealthIssueUpdate for timeline
        await widget.healthIssueService.uploadFileWithDescription(
            widget.healthIssue.id!,
            _selectedFile!,
            originalFileName,
            _descriptionController.text.trim()
        );

        widget.onFileUploaded();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(\'Failed to upload file: ${e.toString()}\')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    // }
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) {
      return const SizedBox.shrink();
    }
    final isImage = _isImageFileForThumbnail(_fileName);
    if (isImage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.2,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Image.file(
              _selectedFile!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // This might happen for very large images or unsupported formats even if extension is image-like
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _filePreviewError = "Could not preview this image.";
                    });
                  }
                });
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 8),
                    Text("Cannot preview image", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                );
              },
            ),
          ),
        ),
      );
    } else if (_fileName != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForFileType(_fileName), size: 50, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(_fileName!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final ext = p.extension(fileName.toLowerCase());
    return ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" || ext == ".webp";
  }

  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final ext = p.extension(fileName.toLowerCase());
    switch (ext) {
      case ".pdf":
        return Icons.picture_as_pdf;
      case ".doc":
      case ".docx":
        return Icons.description;
      case ".xls":
      case ".xlsx":
        return Icons.assessment;
      case ".ppt":
      case ".pptx":
        return Icons.slideshow;
      case ".txt":
        return Icons.article;
      case ".zip":
      case ".rar":
        return Icons.archive;
      default:
        if (_isImageFileForThumbnail(fileName)) return Icons.image;
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Upload New File",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text("Pick File"),
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
            if (_filePreviewError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_filePreviewError!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
              )
            else
              _buildFilePreview(),
            // if (_selectedFile != null) // Redundant if preview shows name
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 8.0),
            //     child: Text("Selected: ${_fileName ?? _selectedFile!.path.split(\'/\').last}", textAlign: TextAlign.center),
            //   ),
            const SizedBox(height: 16.0),
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload and Save File"),
                    onPressed: _submitUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
            const SizedBox(height: 16.0), // Added padding below button
          ],
        ),
      ),
    );
  }
}

// --- Bottom Sheet for Booking a Follow-up ---
class _BookFollowUpBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService;
  final CalendarEventService calendarEventService;
  final Uuid uuid;
  final VoidCallback onFollowUpBooked;

  const _BookFollowUpBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.calendarEventService,
    required this.uuid,
    required this.onFollowUpBooked,
  });

  @override
  State<_BookFollowUpBottomSheetContent> createState() => _BookFollowUpBottomSheetContentState();
}

class _BookFollowUpBottomSheetContentState extends State<_BookFollowUpBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String _selectedEventType = "Appointment"; // Default type
  final List<String> _eventTypes = ["Appointment", "Medication", "Custom"]; // Available types

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow past for logging
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitFollowUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a follow-up date.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(\'Error: You must be logged in.\')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      DateTime finalDateTime = _selectedDate!;
      if (_selectedTime != null) {
        finalDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      String eventTitle = "Follow-up: ${widget.healthIssue.issueName}";
      if (_notesController.text.trim().isNotEmpty) {
        eventTitle = _notesController.text.trim();
      }

      final newEvent = CalendarEvent(
        eventId: widget.uuid.v4(),
        healthIssueId: widget.healthIssue.id!,
        healthIssueName: widget.healthIssue.issueName,
        eventTitle: eventTitle,
        eventDescription: "Follow-up for ${widget.healthIssue.issueName}${_notesController.text.trim().isNotEmpty ? \': \' + _notesController.text.trim() : \'\'}",
        eventDate: Timestamp.fromDate(finalDateTime),
        eventTime: _selectedTime != null ? "${_selectedTime!.hour.toString().padLeft(2, \'0\')}:${_selectedTime!.minute.toString().padLeft(2, \'0\')}" : null,
        eventType: _selectedEventType, // Use selected type, default "Appointment"
        isDone: false,
        createdAt: Timestamp.now(),
        userId: user.uid,
      );

      try {
        // 1. Add to CalendarEvents collection
        await widget.calendarEventService.addCalendarEvent(newEvent);

        // 2. Update HealthIssue with nextFollowUpDate
        //    The service method updateHealthIssue should also handle logging this to HealthIssueUpdates
        await widget.healthIssueService.updateHealthIssue(
          widget.healthIssue.copyWith(
            nextFollowUpDate: Timestamp.fromDate(finalDateTime),
            updatedAt: Timestamp.now(),
          )
        );
        
        widget.onFollowUpBooked();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(\'Failed to book follow-up: ${e.toString()}\')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Book Follow-Up",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? "No date selected"
                        : "Date: ${DateFormat.yMMMd().format(_selectedDate!)}",
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text("Pick Date"),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? "No time selected (optional)"
                        : "Time: ${_selectedTime!.format(context)}",
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.access_time_outlined),
                  label: const Text("Pick Time"),
                  onPressed: () => _pickTime(context),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            DropdownButtonFormField<String>(
              value: _selectedEventType,
              decoration: const InputDecoration(
                labelText: "Follow-up Type",
                border: OutlineInputBorder(),
              ),
              items: _eventTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedEventType = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Notes / Title (Optional)",
                hintText: "e.g., Check blood pressure, Discuss results",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text("Save Follow-Up"),
                    onPressed: _submitFollowUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
            const SizedBox(height: 16.0), // Added padding below button
          ],
        ),
      ),
    );
  }
}

// --- Bottom Sheet for Adding a Reminder ---
class _AddReminderBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService; // Added for logging
  final CalendarEventService calendarEventService;
  final Uuid uuid;
  final VoidCallback onReminderAdded;

  const _AddReminderBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.calendarEventService,
    required this.uuid,
    required this.onReminderAdded,
  });

  @override
  State<_AddReminderBottomSheetContent> createState() => _AddReminderBottomSheetContentState();
}

class _AddReminderBottomSheetContentState extends State<_AddReminderBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String _selectedEventType = "Medication"; // Default type
  final List<String> _eventTypes = ["Medication", "Appointment", "Custom"]; // Available types

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a reminder date.")),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a reminder time.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(\'Error: You must be logged in.\')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final newEvent = CalendarEvent(
        eventId: widget.uuid.v4(),
        healthIssueId: widget.healthIssue.id!,
        healthIssueName: widget.healthIssue.issueName,
        eventTitle: _titleController.text.trim(),
        eventDescription: _descriptionController.text.trim(),
        eventDate: Timestamp.fromDate(finalDateTime),
        eventTime: "${_selectedTime!.hour.toString().padLeft(2, \'0\')}:${_selectedTime!.minute.toString().padLeft(2, \'0\')}",
        eventType: _selectedEventType,
        isDone: false,
        createdAt: Timestamp.now(),
        userId: user.uid,
      );

      try {
        // 1. Add to CalendarEvents collection
        await widget.calendarEventService.addCalendarEvent(newEvent);

        // 2. Add a HealthIssueUpdate for timeline logging
        String updateText = "Reminder set: ${_titleController.text.trim()} on ${DateFormat.yMMMd().format(finalDateTime)} at ${_selectedTime!.format(context)} - Type: $_selectedEventType";
        if (_descriptionController.text.trim().isNotEmpty) {
          updateText += " (Notes: ${_descriptionController.text.trim()})";
        }
        await widget.healthIssueService.addHealthIssueUpdate(
          widget.healthIssue.id!,
          updateText,
          updateType: "Reminder Added",
        );

        widget.onReminderAdded();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(\'Failed to add reminder: ${e.toString()}\')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Add New Reminder",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Reminder Title",
                hintText: "e.g., Take Medication, Doctor Appointment",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter a title for the reminder.";
                }
                return null;
              },
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? "No date selected"
                        : "Date: ${DateFormat.yMMMd().format(_selectedDate!)}",
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text("Pick Date"),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? "No time selected"
                        : "Time: ${_selectedTime!.format(context)}",
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.access_time_outlined),
                  label: const Text("Pick Time"),
                  onPressed: () => _pickTime(context),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            DropdownButtonFormField<String>(
              value: _selectedEventType,
              decoration: const InputDecoration(
                labelText: "Reminder Type",
                border: OutlineInputBorder(),
              ),
              items: _eventTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedEventType = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description / Notes (Optional)",
                hintText: "e.g., Take with food, Prepare questions",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.alarm_add_outlined),
                    label: const Text("Save Reminder"),
                    onPressed: _submitReminder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
            const SizedBox(height: 16.0), // Added padding below button
          ],
        ),
      ),
    );
  }
}

