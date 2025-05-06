import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting

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
    } else {
      // Default values for new issue if any
      _startDate = DateTime.now(); // Default to today
    }
  }

  @override
  void dispose() {
    _issueNameController.dispose();
    _symptomsController.dispose();
    _medicationsController.dispose();
    _doctorClinicController.dispose();
    super.dispose();
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Ensure mandatory fields are set
      if (_startDate == null || _severityLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all mandatory fields (Start Date, Severity).')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final now = Timestamp.now();
      HealthIssue issueToSave = HealthIssue(
        id: widget.healthIssue?.id, // Keep id if editing
        userId: '', // This will be set by the service based on current user
        issueName: _issueNameController.text,
        startDate: Timestamp.fromDate(_startDate!),
        severityLevel: _severityLevel!,
        symptoms: _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
        medications: _medicationsController.text.isNotEmpty ? _medicationsController.text : null,
        doctorClinic: _doctorClinicController.text.isNotEmpty ? _doctorClinicController.text : null,
        isRecurring: _isRecurring,
        nextFollowUpDate: _nextFollowUpDate != null ? Timestamp.fromDate(_nextFollowUpDate!) : null,
        status: widget.healthIssue?.status ?? 'Active', // Preserve status or default
        createdAt: widget.healthIssue?.createdAt ?? now, // Preserve or set new
        updatedAt: now, // Always update this
        fileUploads: widget.healthIssue?.fileUploads ?? [], // Preserve existing files
      );

      try {
        if (widget.healthIssue == null) {
          // Add new issue
          await _healthIssueService.addHealthIssue(issueToSave);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health issue added successfully!')),
          );
        } else {
          // Update existing issue
          await _healthIssueService.updateHealthIssue(issueToSave);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Health issue updated successfully!')),
          );
        }
        Navigator.of(context).pop(); // Go back after saving
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save health issue: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
                decoration: const InputDecoration(labelText: 'Issue Name *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the issue name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: Text('Start Date: ${_startDate != null ? DateFormat.yMd().format(_startDate!) : 'Not set'} *'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isStartDate: true),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _severityLevel,
                decoration: const InputDecoration(labelText: 'Severity Level *'),
                items: _severityOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _severityLevel = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a severity level' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(labelText: 'Symptoms'),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(labelText: 'Medications'),
                maxLines: 2,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _doctorClinicController,
                decoration: const InputDecoration(labelText: 'Doctor/Clinic'),
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Recurring Issue'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: Text('Next Follow-Up Reminder: ${_nextFollowUpDate != null ? DateFormat.yMd().format(_nextFollowUpDate!) : 'Not set'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isStartDate: false),
              ),
              // Placeholder for File Upload functionality
              const SizedBox(height: 20),
              Text('File Uploads (Coming Soon)', style: Theme.of(context).textTheme.titleMedium),
              // Display existing files if any (for edit mode)
              if (widget.healthIssue?.fileUploads != null && widget.healthIssue!.fileUploads!.isNotEmpty)
                ...widget.healthIssue!.fileUploads!.map((file) => ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(file['fileName']!),
                  // Add a way to remove files if needed in edit mode later
                )),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement file picking logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File upload functionality will be implemented here.')),
                  );
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Upload File(s)'),
              ),
              const SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}

