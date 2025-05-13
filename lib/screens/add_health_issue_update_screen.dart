import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
// HealthIssueUpdate model is no longer directly instantiated here with all its fields
// import 'package:health_healing/models/health_issue_update.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; // Retained for Timestamp, though service handles it now
import 'package:firebase_auth/firebase_auth.dart';

class AddHealthIssueUpdateScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const AddHealthIssueUpdateScreen({super.key, required this.healthIssue});

  @override
  State<AddHealthIssueUpdateScreen> createState() => _AddHealthIssueUpdateScreenState();
}

class _AddHealthIssueUpdateScreenState extends State<AddHealthIssueUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _updateTextController = TextEditingController();
  final HealthIssueService _healthIssueService = HealthIssueService();
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

      String updateText = _updateTextController.text.trim();
      // The HealthIssueService.addHealthIssueUpdate method now takes issueId, updateText, and an optional updateType.
      // It internally creates the HealthIssueUpdate object with the correct timestamp.

      try {
        // Call the updated service method. 
        // The service will handle creating the HealthIssueUpdate object with timestamp and default type.
        await _healthIssueService.addHealthIssueUpdate(widget.healthIssue.id!, updateText);
        // Example if you wanted to specify a type explicitly:
        // await _healthIssueService.addHealthIssueUpdate(widget.healthIssue.id!, updateText, updateType: "your_specific_type");

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update added successfully!')),
            );
            Navigator.pop(context, true); // Return true to indicate success
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Update'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Add an update for: ${widget.healthIssue.issueName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _updateTextController,
                decoration: const InputDecoration(
                  labelText: 'Update Details',
                  hintText: 'Enter your update, notes, or observations...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some details for the update.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitUpdate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0)
                      ),
                      child: const Text('Save Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

