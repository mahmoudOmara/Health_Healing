import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
// import 'package:health_healing/screens/add_edit_health_issue_screen.dart'; // For editing
// import 'package:health_healing/screens/add_health_issue_update_screen.dart'; // To be created

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.healthIssue.issueName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Issue',
            onPressed: () {
              // Navigate to AddEditHealthIssueScreen with the current issue
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => AddEditHealthIssueScreen(healthIssue: widget.healthIssue),
              //   ),
              // ).then((_) {
              //   // Potentially refresh state if needed after edit, though StreamBuilder should handle it
              //   // setState(() {}); 
              // });
              print("Edit button tapped for ${widget.healthIssue.issueName}"); // Placeholder
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('General Information'),
            _buildInfoCard([
              _buildInfoRow('Issue Name:', widget.healthIssue.issueName),
              _buildInfoRow('Start Date:', DateFormat.yMd().format(widget.healthIssue.startDate.toDate())),
              _buildInfoRow('Severity Level:', widget.healthIssue.severityLevel),
              _buildInfoRow('Status:', widget.healthIssue.status),
              if (widget.healthIssue.symptoms != null && widget.healthIssue.symptoms!.isNotEmpty)
                _buildInfoRow('Symptoms:', widget.healthIssue.symptoms!),
              if (widget.healthIssue.medications != null && widget.healthIssue.medications!.isNotEmpty)
                _buildInfoRow('Medications:', widget.healthIssue.medications!),
              if (widget.healthIssue.doctorClinic != null && widget.healthIssue.doctorClinic!.isNotEmpty)
                _buildInfoRow('Doctor/Clinic:', widget.healthIssue.doctorClinic!),
              _buildInfoRow('Recurring Issue:', widget.healthIssue.isRecurring ? 'Yes' : 'No'),
              if (widget.healthIssue.nextFollowUpDate != null)
                _buildInfoRow('Next Follow-Up:', DateFormat.yMd().format(widget.healthIssue.nextFollowUpDate!.toDate())),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('Uploaded Files'),
            widget.healthIssue.fileUploads == null || widget.healthIssue.fileUploads!.isEmpty
                ? const Text('No files uploaded for this issue yet.')
                : Column(
                    children: widget.healthIssue.fileUploads!
                        .map((file) => ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: Text(file['fileName']!),
                              // onTap: () { /* TODO: Open file */ },
                            ))
                        .toList(),
                  ),
            ElevatedButton.icon(
                onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload file for issue screen (To be implemented).')),
                    );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload File to Issue'),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Action Hub'),
            Wrap(
              spacing: 8.0, // gap between adjacent chips
              runSpacing: 4.0, // gap between lines
              children: <Widget>[
                ElevatedButton.icon(
                    onPressed: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => AddHealthIssueUpdateScreen(issueId: widget.healthIssue.id!)));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add Update screen (To be implemented).')),
                        );
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('Add Update'),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book Follow-Up screen (To be implemented).')),
                        );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book Follow-Up'),
                ),
                 ElevatedButton.icon(
                    onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add Reminder screen (To be implemented).')),
                        );
                    },
                    icon: const Icon(Icons.alarm_add),
                    label: const Text('Add Reminder'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('History Timeline'),
            StreamBuilder<List<HealthIssueUpdate>>(
              stream: _healthIssueService.getHealthIssueUpdates(widget.healthIssue.id!),
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
                  physics: const NeverScrollableScrollPhysics(), // To use within SingleChildScrollView
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
                                          // onTap: () { /* TODO: Open file */ },
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

