import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadFileScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const UploadFileScreen({super.key, required this.healthIssue});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final HealthIssueService _healthIssueService = HealthIssueService();
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      } else {
        // User canceled the picker
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
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
        // Use a unique path for each issue's files
        String filePath = 'health_issues/${widget.healthIssue.id}/uploads';
        Map<String, String>? uploadResult = await _healthIssueService.uploadFileWithDescription(
            _selectedFile!,
            filePath,
            _descriptionController.text.trim(),
            _fileName ?? _selectedFile!.path.split('/').last // Use picked file name or derive from path
        );

        if (uploadResult != null) {
          // Update the health issue document with the new file information
          List<Map<String, String>> updatedFileUploads = List.from(widget.healthIssue.fileUploads ?? []);
          updatedFileUploads.add({
            'fileName': uploadResult['fileName']!,
            'downloadURL': uploadResult['downloadURL']!,
            'description': _descriptionController.text.trim(),
            // Add a unique ID for the file entry for easier deletion later
            'fileId': DateTime.now().millisecondsSinceEpoch.toString() 
          });

          HealthIssue issueToUpdate = widget.healthIssue.copyWith(fileUploads: updatedFileUploads);
          await _healthIssueService.updateHealthIssue(issueToUpdate);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully!')),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          throw Exception('File upload failed, result was null.');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File for ${widget.healthIssue.issueName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Pick File'),
                onPressed: _pickFile,
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Selected: ${_fileName ?? _selectedFile!.path.split('/').last}', textAlign: TextAlign.center),
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
                // No validator, as it's optional
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload and Save File'),
                      onPressed: _submitUpload,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

