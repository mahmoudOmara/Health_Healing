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
// import 'package:health_healing/screens/upload_file_screen.dart'; // No longer needed
import 'package:health_healing/screens/book_follow_up_screen.dart'; 
import 'package:health_healing/screens/add_reminder_screen.dart'; 
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

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.healthIssue;
  }

  void _refreshIssueDetails() async {
    if (widget.healthIssue.id != null) {
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
          child: _AddUpdateBottomSheetContent(healthIssue: _currentIssue, healthIssueService: _healthIssueService, onUpdateAdded: () {
            _refreshIssueDetails();
          }),
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
          child: _UploadFileBottomSheetContent(healthIssue: _currentIssue, healthIssueService: _healthIssueService, onFileUploaded: () {
            _refreshIssueDetails();
          }),
        );
      },
    );
  }

  void _navigateToBookFollowUpScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookFollowUpScreen(healthIssue: _currentIssue),
      ),
    );
    if (result == true && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up details noted.')),
      );
    }
  }

  void _navigateToAddReminderScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(healthIssue: _currentIssue),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder details noted.')),
      );
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
          _buildStyledCompactActionButton(context, icon: Icons.calendar_today, label: formatButtonLabel("Book Follow-Up"), onPressed: _navigateToBookFollowUpScreen),
          const SizedBox(width: 5.0),
          _buildStyledCompactActionButton(context, icon: Icons.alarm_add, label: formatButtonLabel("Add Reminder"), onPressed: _navigateToAddReminderScreen),
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
            _refreshIssueDetails();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('Uploaded Files'),
            _currentIssue.fileUploads == null || _currentIssue.fileUploads!.isEmpty
                ? const Text('No files uploaded for this issue yet.')
                : Column(
                    children: _currentIssue.fileUploads!
                        .map((file) => ListTile(
                              leading: const Icon(Icons.attach_file),
                                       subtitle: file[
                                        'description'] != null &&
                                    file['description']!.isNotEmpty
                                ? Text(file['description']!)
                                : const Text('No description'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                    tooltip: 'Edit Description',
                                    onPressed: () {
                                      _showEditDescriptionDialog(context, file);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Delete File',
                                    onPressed: () async {
                                      // TODO: Implement file deletion logic from storage and Firestore array
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Delete for ${file['fileName'] ?? 'file'} (To be implemented).')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 20),
            _buildSectionTitle(
                'History Timeline'),
            StreamBuilder<List<HealthIssueUpdate>>(
              stream: _healthIssueService.getHealthIssueUpdates(_currentIssue.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading updates: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No updates or logs for this issue yet.'));
                }
                final updates = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    final update = updates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.yMMMd().add_jm().format(update.updateDate.toDate()),
                              style: Theme.of(context).textTheme.bodySmall
                            ),
                            const SizedBox(height: 4),
                            Text(update.updateText, style: Theme.of(context).textTheme.bodyLarge),
                            if (update.files != null && update.files!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Attached Files:', style: Theme.of(context).textTheme.titleSmall),
                                    ...update.files!.map((file) => ListTile(
                                          leading: const Icon(Icons.attach_file, size: 18),
                                          title: Text(file['fileName']!, style: const TextStyle(fontSize: 14)),
                                          dense: true,
                                        )),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2.0,
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
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: You must be logged in to add an update.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final newUpdate = HealthIssueUpdate(
        updateText: _updateTextController.text.trim(),
        updateDate: Timestamp.now(),
        files: [], 
      );

      try {
        await widget.healthIssueService.addHealthIssueUpdate(widget.healthIssue.id!, newUpdate, user.uid);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update added successfully!')),
            );
            Navigator.pop(context); 
            widget.onUpdateAdded(); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add update: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: <Widget>[
          TextFormField(
            controller: _updateTextController,
            decoration: const InputDecoration(
              labelText: 'New Update/Log',
              hintText: 'Enter details about the update...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an update.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitUpdate,
                  child: const Text('Save Update'),
                ),
          const SizedBox(height: 24.0), // Increased bottom padding 
        ],
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
  String? _originalFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isImageFile(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(extension);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _originalFileName = result.files.single.name;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload.')),
        );
      }
      return;
    }
    // Description is optional, so no validation needed for _formKey unless other fields are added

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You must be logged in.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      String filePathInStorage = 'health_issues/${widget.healthIssue.id}/uploads';
      
      Map<String, String>? uploadResult = await widget.healthIssueService.uploadFileWithDescription(
          _selectedFile!,
          filePathInStorage,
          _descriptionController.text.trim(),
          _originalFileName ?? _selectedFile!.path.split('/').last
      );

      if (uploadResult == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File upload failed: Service did not return details.')),
          );
        }
      } else if (mounted) {
         if (uploadResult.containsKey('fileName') && uploadResult.containsKey('downloadURL')) {
            List<Map<String, String>> updatedFileUploads = List.from(widget.healthIssue.fileUploads ?? []);
            updatedFileUploads.add({
              'fileId": DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
              'fileName': uploadResult['fileName']!, // Store original file name from service
              'downloadURL': uploadResult['downloadURL']!,
              'description': _descriptionController.text.trim(), // Use controller value
            });

            HealthIssue issueToUpdate = widget.healthIssue.copyWith(fileUploads: updatedFileUploads);
            await widget.healthIssueService.updateHealthIssue(issueToUpdate);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully!')),
            );
            Navigator.pop(context); 
            widget.onFileUploaded(); 
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File upload failed: Result missing required keys.')),
            );
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey, // Still useful if more validators are added
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: const Text('Pick File'),
            onPressed: _pickFile,
          ),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: _isImageFile(_selectedFile!.path)
                  ? Image.file(_selectedFile!, height: 100, fit: BoxFit.cover)
                  // Display a generic icon for non-image files
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      size: 60, 
                      color: Theme.of(context).primaryColorLight,
                    ),
                  )
            ),
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
          const SizedBox(height: 24.0),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload and Save File'),
                  onPressed: _submitUpload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
          const SizedBox(height: 16.0), // Bottom padding
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.healthIssue.nextFollowUpDate != null) {
      _selectedDate = widget.healthIssue.nextFollowUpDate!.toDate();
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
    }
    // TODO: If a reason was previously stored, populate _reasonController.text
  }

  @override
  void dispose() {
    _reasonController.dispose();
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

  Future<void> _submitFollowUp() async {
    if (_selectedDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date for the follow-up.')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time for the follow-up.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final DateTime finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      HealthIssue updatedIssue = widget.healthIssue.copyWith(
        nextFollowUpDate: Timestamp.fromDate(finalDateTime),
        // TODO: Add reason to a new field in HealthIssue model if needed for Milestone 4
        // followUpReason: _reasonController.text.trim(), 
      );

      try {
        await widget.healthIssueService.updateHealthIssue(updatedIssue);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Follow-up booked successfully!')),
          );
          Navigator.pop(context);
          widget.onFollowUpBooked();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book follow-up: ${e.toString()}')),
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Book Follow-Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_selectedDate == null ? 'Select Date' : DateFormat.yMd().format(_selectedDate!)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _pickTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for Follow-Up (Optional)',
              hintText: 'e.g., Check-up, Discuss results',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Follow-Up'),
                    onPressed: _submitFollowUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
          const SizedBox(height: 16.0), // Bottom padding
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _selectedReminderType;
  bool _isRepeated = false;
  String? _selectedRepetitionType; // e.g., Daily, Weekly, Monthly
  TimeOfDay? _selectedTime;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final _reminderNotesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reminderTypes = ['Medicine', 'Appointment', 'Symptoms Check', 'Measurement', 'Other'];
  final List<String> _repetitionTypes = ['Daily', 'Weekly', 'Bi-Weekly', 'Monthly'];

  @override
  void dispose() {
    _reminderNotesController.dispose();
    super.dispose();
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

  Future<void> _pickDate(BuildContext context, {bool isStartDate = true}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate; // Ensure end date is not before start date
          }
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Future<void> _submitReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time for the reminder.')),
        );
        return;
      }
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date for the reminder.')),
        );
        return;
      }
      if (_isRepeated && _selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an end date for the repeated reminder.')),
        );
        return;
      }
      if (_isRepeated && _selectedRepetitionType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a repetition type for the repeated reminder.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Placeholder for saving reminder data. 
      // In Milestone 5, this will involve creating a proper Reminder model and service.
      Map<String, dynamic> reminderData = {
        'type': _selectedReminderType,
        'isRepeated': _isRepeated,
        'repetitionType': _isRepeated ? _selectedRepetitionType : null,
        'time': _selectedTime!.format(context),
        'startDate': _selectedStartDate != null ? Timestamp.fromDate(_selectedStartDate!) : null,
        'endDate': _isRepeated && _selectedEndDate != null ? Timestamp.fromDate(_selectedEndDate!) : null,
        'notes': _reminderNotesController.text.trim(),
        'createdAt': Timestamp.now(),
      };

      // For now, we'll just show a success message and call the callback.
      // In a real scenario, you'd save this to Firestore, likely in a subcollection of the health issue.
      print('Reminder Data: $reminderData'); 

      // Simulate network delay for demo
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder details noted (placeholder). Actual scheduling in M5.')),
        );
        Navigator.pop(context);
        widget.onReminderAdded();
      }

      // try {
      //   // Example: await widget.healthIssueService.addReminderToHealthIssue(widget.healthIssue.id!, reminderData);
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Reminder added successfully!')),
      //     );
      //     Navigator.pop(context);
      //     widget.onReminderAdded();
      //   }
      // } catch (e) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Failed to add reminder: ${e.toString()}')),
      //     );
      //   }
      // } finally {
      //   if (mounted) {
      //     setState(() {
      //       _isLoading = false;
      //     });
      //   }
      // }
       setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Add Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Reminder Type', border: OutlineInputBorder()),
              value: _selectedReminderType,
              hint: const Text('Select Reminder Type'),
              items: _reminderTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedReminderType = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a reminder type' : null,
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context, isStartDate: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                      child: Text(_selectedStartDate == null ? 'Select Date' : DateFormat.yMd().format(_selectedStartDate!)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                      child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SwitchListTile(
              title: const Text('Repeat Reminder?'),
              value: _isRepeated,
              onChanged: (bool value) {
                setState(() {
                  _isRepeated = value;
                  if (!_isRepeated) {
                    _selectedRepetitionType = null;
                    _selectedEndDate = null;
                  }
                });
              },
            ),
            if (_isRepeated)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Repeat Every', border: OutlineInputBorder()),
                      value: _selectedRepetitionType,
                      hint: const Text('Select Repetition'),
                      items: _repetitionTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRepetitionType = newValue;
                        });
                      },
                      validator: (value) => _isRepeated && value == null ? 'Please select repetition type' : null,
                    ),
                    const SizedBox(height: 16.0),
                    InkWell(
                      onTap: () => _pickDate(context, isStartDate: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date (Optional for Daily)', border: OutlineInputBorder()),
                        child: Text(_selectedEndDate == null ? 'Select End Date' : DateFormat.yMd().format(_selectedEndDate!)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _reminderNotesController,
              decoration: const InputDecoration(
                labelText: 'Reminder Notes (Optional)',
                hintText: 'e.g., Take with food, Call before going',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.alarm_add_outlined),
                      label: const Text('Save Reminder'),
                      onPressed: _submitReminder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
            const SizedBox(height: 16.0), // Bottom padding
          ],
        ),
      ),
    );
  }
}

