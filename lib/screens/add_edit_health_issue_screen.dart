import 'dart:io'; // Added for File type
import 'package:file_picker/file_picker.dart'; // Added for file picking
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:path/path.dart' as p; // For file extension in icons

class AddEditHealthIssueScreen extends StatefulWidget {
  final HealthIssue? healthIssue; // Nullable for adding new, non-null for editing

  const AddEditHealthIssueScreen({super.key, this.healthIssue});

  @override
  State<AddEditHealthIssueScreen> createState() => _AddEditHealthIssueScreenState();
}

class _AddEditHealthIssueScreenState extends State<AddEditHealthIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final HealthIssueService _healthIssueService = HealthIssueService();

  // Form field controllers
  late TextEditingController _issueNameController;
  late TextEditingController _symptomsController;
  late TextEditingController _medicationsController;
  late TextEditingController _doctorClinicController;

  // Form field values
  DateTime? _startDate;
  String? _severityLevel;
  bool _isRecurring = false;
  DateTime? _nextFollowUpDate;

  final List<String> _severityOptions = ['Mild', 'Moderate', 'Severe'];
  bool _isLoading = false;

  // State for file uploads
  List<PlatformFile> _pickedFiles = [];
  List<TextEditingController> _fileDescriptionControllers = [];
  List<Map<String, String>> _existingFiles = [];

  @override
  void initState() {
    super.initState();
    _issueNameController = TextEditingController(text: widget.healthIssue?.issueName);
    _symptomsController = TextEditingController(text: widget.healthIssue?.symptoms);
    _medicationsController = TextEditingController(text: widget.healthIssue?.medications);
    _doctorClinicController = TextEditingController(text: widget.healthIssue?.doctorClinic);

    if (widget.healthIssue != null) {
      _startDate = widget.healthIssue!.startDate.toDate();
      _severityLevel = widget.healthIssue!.severityLevel;
      _isRecurring = widget.healthIssue!.isRecurring;
      _nextFollowUpDate = widget.healthIssue!.nextFollowUpDate?.toDate();
      _existingFiles = List<Map<String, String>>.from(widget.healthIssue!.fileUploads ?? []);
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _issueNameController.dispose();
    _symptomsController.dispose();
    _medicationsController.dispose();
    _doctorClinicController.dispose();
    for (var controller in _fileDescriptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
    if (result != null) {
      setState(() {
        _pickedFiles.addAll(result.files);
        _fileDescriptionControllers.addAll(
          result.files.map((_) => TextEditingController()).toList()
        );
      });
    }
  }

  void _removePickedFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
      _fileDescriptionControllers[index].dispose();
      _fileDescriptionControllers.removeAt(index);
    });
  }

  Future<void> _pickDate(BuildContext context, {bool isStartDate = true}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _nextFollowUpDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _nextFollowUpDate = picked;
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Start Date.')));
      return;
    }
    if (_severityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Severity Level.')));
      return;
    }

    setState(() => _isLoading = true);
    final now = Timestamp.now();
    String? issueId = widget.healthIssue?.id;
    bool isNewIssue = issueId == null;

    HealthIssue issueToSave = HealthIssue(
      id: issueId,
      userId: '', // Will be set by service
      issueName: _issueNameController.text,
      startDate: Timestamp.fromDate(_startDate!),
      severityLevel: _severityLevel!,
      symptoms: _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
      medications: _medicationsController.text.isNotEmpty ? _medicationsController.text : null,
      doctorClinic: _doctorClinicController.text.isNotEmpty ? _doctorClinicController.text : null,
      isRecurring: _isRecurring,
      nextFollowUpDate: _nextFollowUpDate != null ? Timestamp.fromDate(_nextFollowUpDate!) : null,
      status: widget.healthIssue?.status ?? 'Active',
      createdAt: widget.healthIssue?.createdAt ?? now,
      updatedAt: now,
      fileUploads: isNewIssue ? [] : widget.healthIssue?.fileUploads ?? [], // Start with empty/existing
    );

    String? operationError;
    try {
      if (isNewIssue) {
        issueId = await _healthIssueService.addHealthIssue(issueToSave);
        if (issueId == null) {
          operationError = 'Failed to add health issue. Please try again.';
        }
      } else {
        await _healthIssueService.updateHealthIssue(issueToSave);
      }

      if (issueId != null && _pickedFiles.isNotEmpty) {
        for (int i = 0; i < _pickedFiles.length; i++) {
          PlatformFile platformFile = _pickedFiles[i];
          if (platformFile.path == null) continue; 
          File file = File(platformFile.path!);
          String description = _fileDescriptionControllers[i].text.trim();
          String originalFileName = platformFile.name;
          try {
            await _healthIssueService.uploadFileWithDescription(file, issueId, description, originalFileName);
          } catch (e) {
            print("Error uploading file ${originalFileName}: $e");
            operationError = (operationError ?? "") + " Error uploading ${originalFileName}.";
          }
        }
      }

      if (operationError == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health issue ${isNewIssue ? 'added' : 'updated'} successfully!')),
        );
        Navigator.of(context).pop(true); 
      }
    } catch (e) {
      print("SaveForm Error: $e");
      operationError = (operationError ?? "") + ' Failed to save health issue: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (operationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(operationError)));
        }
      }
    }
  }
  
  bool _isImagePlatformFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension == null) return false;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  bool _isImageFileName(String? fileName) {
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
      case '.jpg': case '.jpeg': case '.png': case '.gif': case '.webp': case '.bmp': return Icons.image_outlined;
      case '.mp3': case '.wav': case '.aac': return Icons.audiotrack_outlined;
      case '.mp4': case '.mov': case '.avi': return Icons.videocam_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.healthIssue == null ? 'Add New Health Issue' : 'Edit Health Issue'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
              tooltip: 'Save Issue',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _issueNameController,
                decoration: const InputDecoration(labelText: 'Issue Name *', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the issue name';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start Date: ${_startDate != null ? DateFormat.yMd().format(_startDate!) : 'Not set'} *'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isStartDate: true),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _severityLevel,
                decoration: const InputDecoration(labelText: 'Severity Level *', border: OutlineInputBorder()),
                items: _severityOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => _severityLevel = newValue),
                validator: (value) => value == null ? 'Please select a severity level' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(labelText: 'Symptoms', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(labelText: 'Medications', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _doctorClinicController,
                decoration: const InputDecoration(labelText: 'Doctor/Clinic', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring Issue'),
                value: _isRecurring,
                onChanged: (bool value) => setState(() => _isRecurring = value),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Next Follow-Up Reminder: ${_nextFollowUpDate != null ? DateFormat.yMd().format(_nextFollowUpDate!) : 'Not set'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isStartDate: false),
              ),
              const SizedBox(height: 20),
              Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_existingFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current files:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _existingFiles.length,
                      itemBuilder: (context, index) {
                        final fileData = _existingFiles[index];
                        final String? fileName = fileData['fileName'];
                        final String? downloadURL = fileData['downloadURL'];
                        final String? description = fileData['description'];
                        final bool isImage = _isImageFileName(fileName) && downloadURL != null;

                        Widget previewWidget;
                        if (isImage) {
                          previewWidget = SizedBox(
                            width: 60, height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                downloadURL!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(_getIconForFileType(fileName), size: 40),
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                                },
                              )
                            )
                          );
                        } else {
                          previewWidget = Icon(_getIconForFileType(fileName), size: 40);
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                previewWidget,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(fileName ?? "Unknown File", style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(description ?? "No description", style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              if (_pickedFiles.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("New files to upload:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pickedFiles.length,
                      itemBuilder: (context, index) {
                        final platformFile = _pickedFiles[index];
                        Widget previewWidget;
                        if (_isImagePlatformFile(platformFile) && platformFile.path != null) {
                          previewWidget = SizedBox(
                            width: 60, height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(File(platformFile.path!), fit: BoxFit.cover)
                            )
                          );
                        } else {
                          previewWidget = Icon(_getIconForFileType(platformFile.name), size: 40);
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    previewWidget,
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(platformFile.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                          Text("Size: ${(platformFile.size / 1024).toStringAsFixed(2)} KB"),
                                        ],
                                      )
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => _removePickedFile(index),
                                      tooltip: "Remove file from upload list",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _fileDescriptionControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'File Description (Optional)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add File(s)'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
              ),
              const SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}

