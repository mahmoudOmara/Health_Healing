import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/services/health_issue_service.dart';
import 'package:health_healing/screens/add_edit_health_issue_screen.dart'; 
import 'package:health_healing/screens/health_issue_detail_screen.dart'; // Import the detail screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthIssueService _healthIssueService = HealthIssueService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    print("HomeScreen: Building...");
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Issues'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search issues by name or symptoms...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<HealthIssue>>(
              stream: _healthIssueService.getHealthIssues(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("HomeScreen StreamBuilder Error: ${snapshot.error}");
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No health issues added yet. Tap the + button to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  );
                }

                final issues = snapshot.data!;
                final filteredIssues = issues.where((issue) {
                  final issueNameLower = issue.issueName.toLowerCase();
                  final symptomsLower = issue.symptoms?.toLowerCase() ?? '';
                  return issueNameLower.contains(_searchQuery) || 
                         symptomsLower.contains(_searchQuery);
                }).toList();

                if (filteredIssues.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                        child: Text(
                        'No issues found matching your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                        ),
                    );
                }
                 if (filteredIssues.isEmpty && _searchQuery.isEmpty && issues.isNotEmpty) {
                     return const Center(
                        child: Text(
                        'No health issues to display.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                        ),
                    );
                }


                return ListView.builder(
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(issue.issueName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Severity: ${issue.severityLevel}'),
                            Text('Status: ${issue.status}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HealthIssueDetailScreen(healthIssue: issue),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditHealthIssueScreen()),
          );
        },
        tooltip: 'Add New Health Issue',
        child: const Icon(Icons.add),
      ),
    );
  }
}

