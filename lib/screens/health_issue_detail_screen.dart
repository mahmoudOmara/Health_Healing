import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Added for Option 2
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:health_healing/screens/add_edit_health_issue_screen.dart'; // For editing
// import 'package:health_healing/screens/add_health_issue_update_screen.dart'); // To be created

enum ActionHubStyle {
  compactRow,
  speedDial,
  appBarMenu,
  bottomSheetButton,
  segmentedBar
}

class HealthIssueDetailScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const HealthIssueDetailScreen({super.key, required this.healthIssue});

  @override
  State<HealthIssueDetailScreen> createState() => _HealthIssueDetailScreenState();
}

class _HealthIssueDetailScreenState extends State<HealthIssueDetailScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  late HealthIssue _currentIssue;
  ActionHubStyle _selectedActionHubStyle = ActionHubStyle.compactRow; // Default style

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

  // --- Action Hub Option 1: Compact Icon Buttons in a Row (Refined) ---
  Widget _buildActionHubCompactRow(BuildContext context) {
    return Row(
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

  // --- Action Hub Option 2: Floating Action Button (FAB) with Speed Dial ---
  Widget _buildActionHubSpeedDial(BuildContext context) {
    return const Center(child: Text("Speed Dial FAB is active (see bottom right)"));
  }

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.tune,
      activeIcon: Icons.close,
      buttonSize: const Size(56.0, 56.0),
      visible: true,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'Actions',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.update),
          backgroundColor: Colors.red,
          label: 'Add Update',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Update screen (To be implemented).'))),
        ),
        SpeedDialChild(
          child: const Icon(Icons.upload_file_outlined),
          backgroundColor: Colors.blue,
          label: 'Upload File',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload file for issue screen (To be implemented).'))),
        ),
        SpeedDialChild(
          child: const Icon(Icons.calendar_today),
          backgroundColor: Colors.green,
          label: 'Book Follow-Up',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Follow-Up screen (To be implemented).'))),
        ),
         SpeedDialChild(
          child: const Icon(Icons.alarm_add),
          backgroundColor: Colors.yellow,
          label: 'Add Reminder',
          labelStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Reminder screen (To be implemented).'))),
        ),
      ],
    );
  }

  // --- Action Hub Option 3B: Single "Actions" Button revealing a Bottom Sheet ---
  Widget _buildActionHubBottomSheetButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.menu_open),
        label: const Text("More Actions"),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext bc) {
              return SafeArea(
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                        leading: const Icon(Icons.update),
                        title: const Text('Add Update'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Update screen (To be implemented).')));
                        }),
                    ListTile(
                      leading: const Icon(Icons.upload_file_outlined),
                      title: const Text('Upload File'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload file for issue screen (To be implemented).')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Book Follow-Up'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Follow-Up screen (To be implemented).')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm_add),
                      title: const Text('Add Reminder'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Reminder screen (To be implemented).')));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Action Hub Option 4: Segmented Control / Horizontal Button Bar ---
  Widget _buildActionHubSegmentedBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.update, size: 18),
            label: const Text("Add Update", style: TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Update screen (To be implemented).'))),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical:10), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))),
          ),
        ),
        const SizedBox(width:1),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text("Upload File", style: TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload file for issue screen (To be implemented).'))),
             style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical:10), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),

          ),
        ),
        const SizedBox(width:1),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text("Book Follow-Up", style: TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Follow-Up screen (To be implemented).'))),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical:10), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
        ),
        const SizedBox(width:1),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.alarm_add, size: 18),
            label: const Text("Add Reminder", style: TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Reminder screen (To be implemented).'))),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical:10), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)))),
          ),
        ),
      ],
    );
  }

  Widget _buildUIStyleSwitcher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: ActionHubStyle.values.map((style) {
          if (style == ActionHubStyle.appBarMenu) return const SizedBox.shrink();
          return ChoiceChip(
            label: Text(style.toString().split('.').last),
            selected: _selectedActionHubStyle == style,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedActionHubStyle = style;
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _getAppBarActions(BuildContext context) {
    List<Widget> actions = [
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

    if (_selectedActionHubStyle == ActionHubStyle.appBarMenu) {
      actions.add(
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'update') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Update screen (To be implemented).')));
            if (value == 'upload') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload file for issue screen (To be implemented).')));
            if (value == 'book') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Follow-Up screen (To be implemented).')));
            if (value == 'remind') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Reminder screen (To be implemented).')));
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'update', child: ListTile(leading: Icon(Icons.update), title: Text('Add Update'))),
            const PopupMenuItem<String>(value: 'upload', child: ListTile(leading: Icon(Icons.upload_file_outlined), title: Text('Upload File'))),
            const PopupMenuItem<String>(value: 'book', child: ListTile(leading: Icon(Icons.calendar_today), title: Text('Book Follow-Up'))),
            const PopupMenuItem<String>(value: 'remind', child: ListTile(leading: Icon(Icons.alarm_add), title: Text('Add Reminder'))),
          ],
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    Widget actionHubWidget;
    switch (_selectedActionHubStyle) {
      case ActionHubStyle.compactRow:
        actionHubWidget = _buildActionHubCompactRow(context);
        break;
      case ActionHubStyle.speedDial:
        actionHubWidget = _buildActionHubSpeedDial(context);
        break;
      case ActionHubStyle.appBarMenu:
        actionHubWidget = const Center(child: Text("Actions are in AppBar Menu (top right)"));
        break;
      case ActionHubStyle.bottomSheetButton:
        actionHubWidget = _buildActionHubBottomSheetButton(context);
        break;
      case ActionHubStyle.segmentedBar:
        actionHubWidget = _buildActionHubSegmentedBar(context);
        break;
      default:
        actionHubWidget = _buildActionHubCompactRow(context);
    }

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
            _buildSectionTitle('UI Style Switcher (Temporary)'),
            _buildUIStyleSwitcher(context),
            const Divider(height: 20, thickness: 1),
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
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 20),
            _buildSectionTitle('Action Hub'),
            actionHubWidget, 
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
      floatingActionButton: _selectedActionHubStyle == ActionHubStyle.speedDial ? _buildSpeedDial() : null,
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

