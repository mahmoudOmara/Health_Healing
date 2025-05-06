import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/screens/upload_file_screen.dart'; 
import 'package:health_healing/screens/book_follow_up_screen.dart'; // Import BookFollowUpScreen
import 'package:health_healing/screens/add_reminder_screen.dart'; // Import AddReminderScreen

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
      // Ensure the widget is still mounted before calling setState
      if (!mounted) return;
      final updatedIssue = await _healthIssueService.getHealthIssueStream(widget.healthIssue.id!).first;
      if (mounted) {
        setState(() {
          _currentIssue = updatedIssue;
        });
      }
    }
  }

  void _showAddUpdateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  void _navigateToUploadFileScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFileScreen(healthIssue: _currentIssue),
      ),
    );
    if (result == true && mounted) {
      _refreshIssueDetails();
    }
  }

  void _navigateToBookFollowUpScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookFollowUpScreen(healthIssue: _currentIssue),
      ),
    );
    // For now, we might not need to refresh details, but good for future consistency
    if (result == true && mounted) {
      // _refreshIssueDetails(); // Uncomment if booking a follow-up modifies the HealthIssue directly
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
    // For now, we might not need to refresh details
    if (result == true && mounted) {
      // _refreshIssueDetails(); // Uncomment if adding a reminder modifies the HealthIssue directly
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
            return "$label\n "; // Add a newline and space to force two lines if no space found
        }
      }
      return label;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Ensures tops of cards align
        children: <Widget>[
          _buildStyledCompactActionButton(context, icon: Icons.update, label: formatButtonLabel("Add Update"), onPressed: _showAddUpdateBottomSheet),
          const SizedBox(width: 5.0),
          _buildStyledCompactActionButton(context, icon: Icons.upload_file_outlined, label: formatButtonLabel("Upload File"), onPressed: _navigateToUploadFileScreen),
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
                  height: 30, // Fixed height for the text container to ensure button height consistency
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
                              title: Text(file['fileName']!),
                              subtitle: file['description'] != null && file['description']!.isNotEmpty 
                                ? Text(file['description']!) 
                                : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete File',
                                onPressed: () async {
                                  // TODO: Implement file deletion logic from storage and Firestore array
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete for ${file['fileName']} (To be implemented).')),
                                  );
                                },
                              ),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 20),
            _buildSectionTitle('History Timeline'),
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

// Separate widget for BottomSheet content to manage its own state
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Add Update for: ${widget.healthIssue.issueName}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          TextFormField(
            controller: _updateTextController,
            decoration: const InputDecoration(
              labelText: 'Update Details',
              hintText: 'Enter your update, notes, or observations...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3, 
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter some details for the update.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0)
                  ),
                  child: const Text('Save Update'),
                ),
          const SizedBox(height: 8.0), 
        ],
      ),
    );
  }
}

