import 'package:flutter/material.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // No longer needed
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart'; // For editing
// import 'package:health_healing/screens/add_health_issue_update_screen.dart'); // To be created

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
      final updatedIssueStream = _healthIssueService.getHealthIssues().map((issues) =>
          issues.firstWhere((issue) => issue.id == widget.healthIssue.id,
              orElse: () => _currentIssue));
      final updatedIssue = await updatedIssueStream.first;
      if (mounted) {
        setState(() {
          _currentIssue = updatedIssue;
        });
      }
    }
  }

  // --- Final Action Hub: Compact Icon Buttons in a Row (Refined) ---
  Widget _buildActionHub(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Add some padding around the row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top for multi-line text
        children: <Widget>[
          _buildCompactActionButton(context, icon: Icons.update, label: "Add Update", onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Update screen (To be implemented).')));
          }),
          _buildCompactActionButton(context, icon: Icons.upload_file_outlined, label: "Upload File", onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload file for issue screen (To be implemented).')));
          }),
          _buildCompactActionButton(context, icon: Icons.calendar_today, label: "Book Follow-Up", onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Follow-Up screen (To be implemented).')));
          }),
          _buildCompactActionButton(context, icon: Icons.alarm_add, label: "Add Reminder", onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Reminder screen (To be implemented).')));
          }),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: label, iconSize: 28.0, color: Theme.of(context).primaryColor),
          Text(
            label,
            textAlign: TextAlign.center, // Center text for two lines
            style: const TextStyle(fontSize: 12.0),
            maxLines: 2, // Allow text to wrap to two lines
            overflow: TextOverflow.ellipsis, // Handle overflow if text is still too long
          ),
        ],
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
          if (result == true || result == null) { // Refresh if edited or simply popped back
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
            // Removed UI Style Switcher
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
                              // onTap: () { /* TODO: Open file */ },
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 20),
            _buildSectionTitle('Action Hub'),
            _buildActionHub(context), // Directly use the chosen action hub
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
      // Removed floatingActionButton as SpeedDial is no longer the selected option
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

