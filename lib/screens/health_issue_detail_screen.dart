import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart'; // For editing
// import 'package:health_healing/screens/add_health_issue_update_screen.dart'; // To be created

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  late HealthIssue _currentIssue; // To hold the potentially updated issue

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.healthIssue;
  }

  void _refreshIssueDetails() async {
    // This method is called after returning from the edit screen.
    // The HomeScreen's StreamBuilder should handle updating the list.
    // When navigating back to this detail screen for the same item,
    // it should be rebuilt with the new widget.healthIssue from the updated list.
    // However, if this specific instance of HealthIssueDetailScreen is still in the widget tree
    // (e.g., if AddEditHealthIssueScreen did not replace it fully or if using complex navigation),
    // _currentIssue might be stale. A robust solution involves a proper state management approach
    // (Provider, Riverpod, BLoC) to share and update state across screens.
    // For now, if AddEditHealthIssueScreen returns a value indicating an update, we can use it.
    // Or, we can re-fetch the specific issue if its ID is available.
    // Given the current structure, the simplest is to rely on the parent StreamBuilder in HomeScreen
    // to provide the updated HealthIssue object when this screen is potentially rebuilt upon re-navigation.
    // If the edit screen pops and this screen is directly revealed without re-navigation from home,
    // we need a way to get the updated data.
    // A simple (but not always ideal) way is to refetch if an ID is present.
    if (widget.healthIssue.id != null) {
        final updatedIssueStream = _healthIssueService.getHealthIssues().map((issues) => issues.firstWhere((issue) => issue.id == widget.healthIssue.id, orElse: () => _currentIssue));
        final updatedIssue = await updatedIssueStream.first;
        if (mounted) {
            setState(() {
                _currentIssue = updatedIssue;
            });
        }
    }
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important for Wrap or GridView
            children: [
              Icon(icon, size: 30.0, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8.0),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            ],
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
            tooltip: 'Edit Issue',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditHealthIssueScreen(healthIssue: _currentIssue),
                ),
              );
              // If the edit screen indicates a change (e.g. by returning true or the updated object)
              // or simply by popping, we might want to refresh.
              if (result == true || result == null) { // Assuming pop without specific result means potential change
                _refreshIssueDetails();
              }
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
            // This section remains as is for now, as per user request focusing on Action Hub
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
             ElevatedButton.icon(
                onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload file for issue screen (To be implemented).')),
                    );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload File to Issue'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Action Hub'),
            GridView.count(
              crossAxisCount: 2, // Display two cards per row
              shrinkWrap: true, // Essential for GridView inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 1.2, // Adjust for desired card proportions (width/height)
              children: <Widget>[
                _buildActionCard(
                  context,
                  icon: Icons.update,
                  label: 'Add Update',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Update screen (To be implemented).')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.upload_file_outlined, // Changed from ElevatedButton
                  label: 'Upload File',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload file for issue screen (To be implemented).')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Book Follow-Up',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Book Follow-Up screen (To be implemented).')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.alarm_add,
                  label: 'Add Reminder',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Reminder screen (To be implemented).')),
                    );
                  },
                ),
              ],
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

