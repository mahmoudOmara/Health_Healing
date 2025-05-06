import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:path/path.dart' as p; // For getting file extension

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  late HealthIssue _currentIssue;
  bool _isDeletingFile = false;

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
            healthIssueService: _healthIssueService,
            onFollowUpBooked: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Follow-up details noted.')),
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
            healthIssueService: _healthIssueService,
            onReminderAdded: () {
              Navigator.of(bottomSheetContext).pop(); // Close bottom sheet
              _refreshIssueDetails();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder details noted.')),
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
        final String? description = fileData["description"];
        final String? downloadURL = fileData["downloadURL"];

        Widget leadingWidget;
        if (_isImageFileForThumbnail(fileName) && downloadURL != null) {
          leadingWidget = SizedBox(
            width: 50.0, // Standardized width
            height: 50.0, // Standardized height
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                downloadURL,
                fit: BoxFit.cover, // Ensure image covers the square area
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 50, height: 50, child: Center(child: Icon(Icons.broken_image, size: 30.0))),
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)));
                },
              ),
            ),
          );
        } else {
          leadingWidget = SizedBox(
            width: 50.0, // Standardized width
            height: 50.0, // Standardized height
            child: Center(child: Icon(_getIconForFileType(fileName), size: 30.0)), // Centered icon
          );
        }

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: leadingWidget,
            title: Text(fileName ?? "Unknown File", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(description ?? "No description", maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20.0),
                  tooltip: "Edit Description",
                  onPressed: () => _showEditDescriptionDialog(context, fileData),
                ),
                if (_isDeletingFile && _currentIssue.fileUploads![index]['fileId'] == fileData['fileId']) 
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                else
                    IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20.0),
                        tooltip: "Delete File",
                        onPressed: () => _deleteFile(fileData),
                    ),
              ],
            ),
            onTap: () => _showFilePreviewModal(context, fileData),
          ),
        );
      },
    );
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final extension = p.extension(fileName.toLowerCase());
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension);
  }

  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    final extension = p.extension(fileName.toLowerCase());
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined; // Word document
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_outlined; // Excel sheet
      case '.ppt':
      case '.pptx':
        return Icons.slideshow_outlined; // PowerPoint
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

  Widget _buildHistoryTimeline() {
    if (_currentIssue.id == null) {
      return const Center(child: Text("No history available."));
    }
    return StreamBuilder<List<HealthIssueUpdate>>(
      stream: _healthIssueService.getIssueUpdatesStream(_currentIssue.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No updates or actions logged yet."));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading history: ${snapshot.error}"));
        }

        final updates = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            final update = updates[index];
            final bool isFirst = index == 0;
            final bool isLast = index == updates.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 40.0, // Width for the timeline line and node
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            width: 2.0,
                            color: isFirst ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2.0,
                            color: isLast ? Colors.transparent : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Card(
                        elevation: 1.0,
                        margin: const EdgeInsets.symmetric(vertical: 4.0), // Keep some vertical margin for the card itself
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Important for Column inside IntrinsicHeight
                            children: <Widget>[
                              Text(update.updateText, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 4.0),
                              Text(
                                DateFormat.yMMMd().add_jm().format(update.updateDate.toDate()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _updateTextController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _updateTextController.removeListener(_validateForm);
    _updateTextController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _updateTextController.text.trim().isNotEmpty;
    });
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      setState(() => _isLoading = true);
      try {
        final update = HealthIssueUpdate(
          updateText: _updateTextController.text.trim(),
          updateDate: Timestamp.now(),
        );
        await widget.healthIssueService.addHealthIssueUpdate(widget.healthIssue.id!, update);
        widget.onUpdateAdded();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add update: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
            Text("Add New Update", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _updateTextController,
              decoration: const InputDecoration(
                labelText: "Update Details",
                hintText: "Enter details about the update...",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter update details.";
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text("Save Update"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16.0),
              ),
              onPressed: _isLoading || !_isFormValid ? null : _submitUpdate,
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.only(top:8.0), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 16.0), // Added padding at the bottom
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
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileName;
  bool _isLoading = false;
  bool _isFileSelected = false;

  @override
  void initState() {
    super.initState();
    // No listener needed for _descriptionController as it's optional
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        _isFileSelected = true;
      });
    } else {
      // User canceled the picker or no path available
      // setState(() { _isFileSelected = false; }); // Not strictly needed if button relies on _selectedFile != null
    }
  }

  Future<void> _uploadAndSaveFile() async {
    if (_selectedFile == null) { // This check is redundant if button is disabled, but good for safety
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.healthIssueService.uploadFileWithDescription(
        _selectedFile!,
        widget.healthIssue.id!,
        _descriptionController.text.trim(),
        _selectedFileName ?? "unknown_file",
      );
      widget.onFileUploaded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading file: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget filePreviewWidget;
    if (_selectedFile != null) {
      final isImage = _isImageFileForThumbnail(_selectedFileName);
      if (isImage) {
        filePreviewWidget = SizedBox(
          width: 50.0, // Standardized width
          height: 50.0, // Standardized height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(_selectedFile!, fit: BoxFit.cover), // Ensure image covers the square area
          ),
        );
      } else {
        filePreviewWidget = SizedBox(
          width: 50.0, // Standardized width
          height: 50.0, // Standardized height
          child: Center(child: Icon(_getIconForFileType(_selectedFileName), size: 30.0)), // Centered icon
        );
      }
    } else {
      filePreviewWidget = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text("Upload File", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          ElevatedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: Text(_selectedFileName ?? "Select File"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              textStyle: const TextStyle(fontSize: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: _isLoading ? null : _pickFile,
          ),
          const SizedBox(height: 12.0),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: filePreviewWidget),
            ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: "File Description (Optional)",
              hintText: "Enter a brief description for the file...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text("Upload and Save File"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              textStyle: const TextStyle(fontSize: 16.0),
            ),
            onPressed: (_isLoading || _selectedFile == null) ? null : _uploadAndSaveFile,
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.only(top:8.0), child: Center(child: CircularProgressIndicator())),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  // Helper methods also used in the main screen, duplicated for encapsulation here
  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final extension = p.extension(fileName.toLowerCase());
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension);
  }

  IconData _getIconForFileType(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    final extension = p.extension(fileName.toLowerCase());
    switch (extension) {
      case '.pdf': return Icons.picture_as_pdf_outlined;
      case '.doc': case '.docx': return Icons.description_outlined;
      case '.xls': case '.xlsx': return Icons.table_chart_outlined;
      case '.ppt': case '.pptx': return Icons.slideshow_outlined;
      case '.txt': return Icons.article_outlined;
      case '.zip': case '.rar': return Icons.archive_outlined;
      case '.mp3': case '.wav': case '.aac': return Icons.audiotrack_outlined;
      case '.mp4': case '.mov': case '.avi': return Icons.videocam_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }
}

class _BookFollowUpBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService;
  final VoidCallback onFollowUpBooked;

  const _BookFollowUpBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.onFollowUpBooked,
  });

  @override
  State<_BookFollowUpBottomSheetContent> createState() => _BookFollowUpBottomSheetContentState();
}

class _BookFollowUpBottomSheetContentState extends State<_BookFollowUpBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isFormValid = false;

  // Store initial values for edit comparison
  DateTime? _initialDate;
  TimeOfDay? _initialTime;

  @override
  void initState() {
    super.initState();
    if (widget.healthIssue.nextFollowUpDate != null) {
      _initialDate = widget.healthIssue.nextFollowUpDate!.toDate();
      _initialTime = TimeOfDay.fromDateTime(_initialDate!);
      _selectedDate = _initialDate;
      _selectedTime = _initialTime;
    }
    _validateForm(); // Initial validation
  }

  void _validateForm() {
    bool isEditing = widget.healthIssue.nextFollowUpDate != null;
    bool hasChanged = false;
    if (isEditing) {
      if (_selectedDate != _initialDate || _selectedTime != _initialTime) {
        hasChanged = true;
      }
    }

    setState(() {
      if (isEditing) {
        _isFormValid = hasChanged && _selectedDate != null; // Must have a date and must have changed
      } else {
        _isFormValid = _selectedDate != null; // For new, only date is mandatory
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) { // No need to check if pickedDate != _selectedDate here, _validateForm handles it
      setState(() {
        _selectedDate = pickedDate;
        _validateForm();
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) { // No need to check if pickedTime != _selectedTime here, _validateForm handles it
      setState(() {
        _selectedTime = pickedTime;
        _validateForm();
      });
    }
  }

  Future<void> _saveFollowUp() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      // _selectedDate null check is already part of _isFormValid logic
      setState(() => _isLoading = true);
      try {
        DateTime finalDateTime = _selectedDate!;
        if (_selectedTime != null) {
          finalDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
        }
        
        HealthIssue updatedIssue = widget.healthIssue.copyWith(
          nextFollowUpDate: Timestamp.fromDate(finalDateTime),
          updatedAt: Timestamp.now(),
        );
        await widget.healthIssueService.updateHealthIssue(updatedIssue);
        widget.onFollowUpBooked();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save follow-up: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
            Text("Book/Update Follow-Up", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20.0),
            Text("Selected Date: ${_selectedDate == null ? 'Not set' : DateFormat.yMMMd().format(_selectedDate!)}"),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text("Select Date"),
              onPressed: () => _pickDate(context),
            ),
            const SizedBox(height: 12.0),
            Text("Selected Time: ${_selectedTime == null ? 'Not set (optional)' : _selectedTime!.format(context)}"),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time_outlined),
              label: const Text("Select Time"),
              onPressed: () => _pickTime(context),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text("Save Follow-Up"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16.0),
              ),
              onPressed: _isLoading || !_isFormValid ? null : _saveFollowUp,
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.only(top:8.0), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class _AddReminderBottomSheetContent extends StatefulWidget {
  final HealthIssue healthIssue;
  final HealthIssueService healthIssueService;
  final VoidCallback onReminderAdded;

  const _AddReminderBottomSheetContent({
    required this.healthIssue,
    required this.healthIssueService,
    required this.onReminderAdded,
  });

  @override
  State<_AddReminderBottomSheetContent> createState() => _AddReminderBottomSheetContentState();
}

class _AddReminderBottomSheetContentState extends State<_AddReminderBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _reminderTextController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _reminderTextController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _reminderTextController.removeListener(_validateForm);
    _reminderTextController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _reminderTextController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        // No need to call _validateForm() here as date/time are optional for reminder button enablement
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
        // No need to call _validateForm() here as date/time are optional for reminder button enablement
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      // _reminderTextController empty check is already part of _isFormValid logic
      setState(() => _isLoading = true);
      try {
        String reminderDetails = _reminderTextController.text.trim();
        String dateTimeString = "";
        if (_selectedDate != null) {
          dateTimeString += DateFormat.yMMMd().format(_selectedDate!);
          if (_selectedTime != null) {
            dateTimeString += " at ${_selectedTime!.format(context)}";
          }
        }
        // The actual reminder text for Firestore is now just the controller's text.
        // The date/time are for user display and potential future notification features, not part of the saved string for logging.

        await widget.healthIssueService.addOrUpdateReminder(
          widget.healthIssue.id!,
          _reminderTextController.text.trim(), // Log only the core reminder text
        );
        widget.onReminderAdded();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save reminder: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
            Text("Add Reminder", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _reminderTextController,
              decoration: const InputDecoration(
                labelText: "Reminder Details",
                hintText: "e.g., Take medication, Doctor's appointment",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter reminder details.";
                }
                return null;
              },
            ),
            const SizedBox(height: 12.0),
            Text("Reminder Date: ${_selectedDate == null ? 'Not set (optional)' : DateFormat.yMMMd().format(_selectedDate!)}"),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text("Select Date"),
              onPressed: () => _pickDate(context),
            ),
            const SizedBox(height: 12.0),
            Text("Reminder Time: ${_selectedTime == null ? 'Not set (optional)' : _selectedTime!.format(context)}"),
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time_outlined),
              label: const Text("Select Time"),
              onPressed: () => _pickTime(context),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text("Save Reminder"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16.0),
              ),
              onPressed: _isLoading || !_isFormValid ? null : _saveReminder,
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.only(top:8.0), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

