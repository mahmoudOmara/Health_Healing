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
                           // Corrected: Removed mainAxisSize from Column as Text widget does not have it. It is on Column itself.
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
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 28.0, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8.0),
                Container(
                  height: 30,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.0),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final extension = p.extension(fileName).toLowerCase();
    return [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"].contains(extension);
  }

  IconData _getIconForFileType(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    if ([".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"].contains(extension)) {
      return Icons.image_outlined;
    } else if (extension == ".pdf") {
      return Icons.picture_as_pdf_outlined;
    } else if ([".doc", ".docx", ".odt"].contains(extension)) {
      return Icons.description_outlined;
    } else if ([".xls", ".xlsx", ".ods"].contains(extension)) {
      return Icons.table_chart_outlined;
    } else if ([".ppt", ".pptx", ".odp"].contains(extension)) {
      return Icons.slideshow_outlined;
    } else if ([".zip", ".rar", ".tar", ".gz"].contains(extension)) {
      return Icons.archive_outlined;
    } else if ([".mp3", ".wav", ".aac"].contains(extension)) {
      return Icons.audiotrack_outlined;
    } else if ([".mp4", ".mov", ".avi"].contains(extension)) {
      return Icons.video_file_outlined;
    }
    return Icons.attach_file_outlined;
  }

  List<Widget> _getAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.edit),
        tooltip: 'Edit Issue',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditHealthIssueScreen(healthIssue: _currentIssue),
            ),
          );
          if (result == true || result == null) {
             if(mounted) _refreshIssueDetails();
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIssue.issueName),
        actions: _getAppBarActions(context),
      ),
      // Corrected: SingleChildScrollView uses named parameters
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Corrected: Bracket for children list and overall structure
          children: <Widget>[
            _buildActionHub(context),
            const SizedBox(height: 10),
            _buildSectionTitle('General Information'),
            _buildInfoCard([
              _buildInfoRow('Issue Name:', _currentIssue.issueName),
              _buildInfoRow('Start Date:', DateFormat.yMd().format(_currentIssue.startDate.toDate())),
              _buildInfoRow('Severity Level:', _currentIssue.severityLevel),
              _buildInfoRow('Status:', _currentIssue.status),
              if (_currentIssue.symptoms != null && _currentIssue.symptoms!.isNotEmpty)
                _buildInfoRow('Symptoms:', _currentIssue.symptoms!),
              if (_currentIssue.medications != null && _currentIssue.medications!.isNotEmpty)
                _buildInfoRow('Medications:', _currentIssue.medications!),
              if (_currentIssue.doctorClinic != null && _currentIssue.doctorClinic!.isNotEmpty)
                _buildInfoRow('Doctor/Clinic:', _currentIssue.doctorClinic!),
              _buildInfoRow('Recurring Issue:', _currentIssue.isRecurring ? 'Yes' : 'No'),
              if (_currentIssue.nextFollowUpDate != null)
                _buildInfoRow('Next Follow-Up:', DateFormat.yMd().format(_currentIssue.nextFollowUpDate!.toDate())),
            ]), // End of _buildInfoCard children list
            const SizedBox(height: 20),
            // Corrected: Syntax for _buildSectionTitle call
            _buildSectionTitle('Uploaded Files'),
            Builder(
              builder: (context) {
                if (_currentIssue.fileUploads == null || _currentIssue.fileUploads!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('No files uploaded for this issue yet.')),
                  );
                }
                List<Widget> fileWidgets = [];
                for (int i = 0; i < _currentIssue.fileUploads!.length; i++) {
                  final file = _currentIssue.fileUploads![i];
                  fileWidgets.add(
                    Card(
                      elevation: 1.0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: ListTile(
                        leading: Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: _isImageFileForThumbnail(file['fileName']!) && file['downloadURL'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Image.network(
                                    file['downloadURL']!,
                                    width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Icon(_getIconForFileType(file['fileName']!), size: 24),
                                    loadingBuilder: (ctx, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)));
                                    },
                                  ),
                                )
                              : Icon(_getIconForFileType(file['fileName']!), size: 24, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(file['fileName'] ?? 'Unnamed File', style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                        subtitle: Text(file['description'] ?? 'No description', style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit Description',
                              onPressed: () => _showEditDescriptionDialog(context, file),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Delete File',
                              color: Theme.of(context).colorScheme.error,
                              onPressed: _isDeletingFile ? null : () => _deleteFile(file),
                            ),
                          ],
                        ),
                        onTap: () => _showFilePreviewModal(context, file),
                      ),
                    ),
                  );
                }
                return Column(children: fileWidgets);
              },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('History Timeline'),
            StreamBuilder<List<HealthIssueUpdate>>(
              stream: _healthIssueService.getIssueUpdatesStream(_currentIssue.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No updates or history for this issue yet.'));
                }
                final updates = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    final update = updates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1.0,
                      child: ListTile(
                        title: Text(update.updateText, style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text('On: ${DateFormat.yMd().add_jm().format(update.updateDate.toDate())}', style: Theme.of(context).textTheme.bodySmall),
                        // You can add more details or actions for each update if needed
                      ),
                    );
                  },
                );
              },
            ),
          ], // End of main Column children
        ), // End of Column
      ), // End of SingleChildScrollView
    ); // End of Scaffold
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 2, child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

// Bottom Sheet for Adding Updates
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
      setState(() { _isLoading = true; });
      try {
        final update = HealthIssueUpdate(
          id: FirebaseFirestore.instance.collection('healthIssues').doc().collection('updates').doc().id, // Firestore generates ID
          updateText: _updateTextController.text.trim(),
          updateDate: Timestamp.now(),
        );
        await widget.healthIssueService.addHealthIssueUpdate(widget.healthIssue.id!, update);
        widget.onUpdateAdded();
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update added successfully!')),
            );
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add update: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add New Update/Log', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _updateTextController,
            decoration: const InputDecoration(
              labelText: 'Update Details',
              hintText: 'Enter details about the update or log...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter update details.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                  ),
                  onPressed: _submitUpdate,
                  label: const Text('Save Update'),
                ),
          const SizedBox(height: 24.0), // Bottom padding
        ],
      ),
    );
  }
}

// Bottom Sheet for Uploading Files
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
    }
  }

  Future<void> _submitFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        await widget.healthIssueService.uploadFileWithDescription(
          _selectedFile!,
          widget.healthIssue.id!,
          _descriptionController.text.trim(),
          _selectedFileName ?? "unknown_file",
        );
        widget.onFileUploaded();
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully!')),
            );
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload file: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Upload New File', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'File Description (Optional)',
              hintText: 'Enter a brief description for the file...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16.0),
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: Text(_selectedFileName ?? 'Select File'),
            onPressed: _pickFile,
          ),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _isImageFileForThumbnail(_selectedFileName) 
                ? Image.file(_selectedFile!, height: 100, fit: BoxFit.contain)
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_getIconForFileType(_selectedFileName!)), const SizedBox(width: 8), Text(_selectedFileName!)]),
            ),
          const SizedBox(height: 20.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                  ),
                  onPressed: _submitFile,
                  label: const Text('Upload and Save File'),
                ),
          const SizedBox(height: 24.0), // Bottom padding
        ],
      ),
    );
  }

  bool _isImageFileForThumbnail(String? fileName) {
    if (fileName == null) return false;
    final extension = p.extension(fileName).toLowerCase();
    return [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"].contains(extension);
  }

  IconData _getIconForFileType(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    if ([".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"].contains(extension)) {
      return Icons.image_outlined;
    } else if (extension == ".pdf") {
      return Icons.picture_as_pdf_outlined;
    } else if ([".doc", ".docx", ".odt"].contains(extension)) {
      return Icons.description_outlined;
    } else if ([".xls", ".xlsx", ".ods"].contains(extension)) {
      return Icons.table_chart_outlined;
    } else if ([".ppt", ".pptx", ".odp"].contains(extension)) {
      return Icons.slideshow_outlined;
    } else if ([".zip", ".rar", ".tar", ".gz"].contains(extension)) {
      return Icons.archive_outlined;
    } else if ([".mp3", ".wav", ".aac"].contains(extension)) {
      return Icons.audiotrack_outlined;
    } else if ([".mp4", ".mov", ".avi"].contains(extension)) {
      return Icons.video_file_outlined;
    }
    return Icons.attach_file_outlined;
  }
}

// Bottom Sheet for Booking Follow-up
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
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.healthIssue.nextFollowUpDate?.toDate();
    // In a real app, you might fetch existing notes if they were stored separately for follow-ups
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitFollowUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a follow-up date.')),
        );
        return;
      }
      setState(() { _isLoading = true; });
      try {
        HealthIssue updatedIssue = widget.healthIssue.copyWith(
          nextFollowUpDate: Timestamp.fromDate(_selectedDate!),
          // Potentially save _notesController.text to a new field in HealthIssue or a separate follow-up model
          updatedAt: Timestamp.now(),
        );
        await widget.healthIssueService.updateHealthIssue(updatedIssue);
        widget.onFollowUpBooked();
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book follow-up: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Book Next Follow-Up', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          ListTile(
            title: Text(_selectedDate == null ? 'Select Follow-Up Date*' : DateFormat.yMMMEd().format(_selectedDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(context),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any notes for the follow-up...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.event_available_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                  ),
                  onPressed: _submitFollowUp,
                  label: const Text('Save Follow-Up'),
                ),
          const SizedBox(height: 24.0), // Bottom padding
        ],
      ),
    );
  }
}

// Bottom Sheet for Adding Reminder
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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _reminderNotesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // In a real app, you might fetch existing reminder data if available
  }

 @override
  void dispose() {
    _reminderNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickReminderTime(BuildContext context) async {
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
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time for the reminder.')),
        );
        return;
      }
      setState(() { _isLoading = true; });
      
      final reminderDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Placeholder: In a real app, this would integrate with a notification service
      // For now, we can store it in Firestore if a field exists or just show a message.
      // Example: Update health issue with reminder details
      HealthIssue updatedIssue = widget.healthIssue.copyWith(
        // Assuming you add a field like 'nextReminderAt: Timestamp.fromDate(reminderDateTime)'
        // and 'reminderNotes: _reminderNotesController.text.trim()'
        updatedAt: Timestamp.now(),
      );
      try {
        // await widget.healthIssueService.updateHealthIssue(updatedIssue); // If storing in issue
        // print('Reminder set for: $reminderDateTime with notes: ${_reminderNotesController.text.trim()}');
        widget.onReminderAdded();
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set reminder: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add New Reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          ListTile(
            title: Text(_selectedDate == null ? 'Select Reminder Date*' : DateFormat.yMMMEd().format(_selectedDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickReminderDate(context),
          ),
          ListTile(
            title: Text(_selectedTime == null ? 'Select Reminder Time*' : _selectedTime!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickReminderTime(context),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _reminderNotesController,
            decoration: const InputDecoration(
              labelText: 'Reminder Notes (Optional)',
              hintText: 'Enter notes for the reminder...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(Icons.alarm_on_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                  ),
                  onPressed: _submitReminder,
                  label: const Text('Set Reminder'),
                ),
          const SizedBox(height: 24.0), // Bottom padding
        ],
      ),
    );
  }
}

