import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:intl/intl.dart'; // For date and time formatting

class BookFollowUpScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const BookFollowUpScreen({super.key, required this.healthIssue});

  @override
  State<BookFollowUpScreen> createState() => _BookFollowUpScreenState();
}

class _BookFollowUpScreenState extends State<BookFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitFollowUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time for the follow-up.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Combine date and time
      final DateTime followUpDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // For now, we'll just print the data or show a success message.
      // In Milestone 4, this data will be used to create a calendar event.
      print('Follow-Up Booked:');
      print('Health Issue ID: ${widget.healthIssue.id}');
      print('Date & Time: ${DateFormat.yMd().add_jm().format(followUpDateTime)}');
      print('Reason: ${_reasonController.text.trim()}');

      // Simulate saving
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow-up for ${DateFormat.yMd().add_jm().format(followUpDateTime)} noted. Calendar integration in Milestone 4.')),
        );
        Navigator.pop(context, true); // Return true to indicate success (for now)
      }
      
      // TODO: In a real scenario, save this followUpDateTime and reason to Firestore,
      // perhaps in a subcollection of the health issue or by updating the health issue itself.
      // For example, update _currentIssue.nextFollowUpDate if it's a single follow-up, 
      // or add to a list of follow-ups if multiple are allowed.

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Follow-Up for ${widget.healthIssue.issueName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Select Date and Time for Follow-Up:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No date chosen'
                          : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context),
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedTime == null
                          ? 'No time chosen'
                          : 'Time: ${_selectedTime!.format(context)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickTime(context),
                    child: const Text('Choose Time'),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Follow-Up (Optional)',
                  hintText: 'e.g., Check-up, Discuss results',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Save Follow-Up Details'),
                      onPressed: _submitFollowUp,
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

