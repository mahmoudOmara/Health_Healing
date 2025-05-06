import 'package:flutter/material.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:intl/intl.dart'; // For date and time formatting

// Enum for Reminder Type
enum ReminderType { medicine, appointment, symptomsCheck, measurement }

// Enum for Repetition Type
enum RepetitionType { none, daily, weekly, monthly, custom }

class AddReminderScreen extends StatefulWidget {
  final HealthIssue healthIssue;

  const AddReminderScreen({super.key, required this.healthIssue});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRepeated = false;
  RepetitionType _repetitionType = RepetitionType.none;
  TimeOfDay? _selectedTime;
  DateTime? _startDate;
  DateTime? _endDate; // Only if repeated and not indefinitely
  ReminderType _reminderType = ReminderType.medicine;
  final _customRepetitionController = TextEditingController(); // For custom repetition details
  bool _isLoading = false;

  @override
  void dispose() {
    _customRepetitionController.dispose();
    super.dispose();
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

  Future<void> _pickDate(BuildContext context, {bool isStartDate = true}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // If end date is before start date, reset end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submitReminder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTime == null || _startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start date and time for the reminder.')),
        );
        return;
      }
      if (_isRepeated && _repetitionType == RepetitionType.custom && _customRepetitionController.text.trim().isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify custom repetition details.')),
        );
        return;
      }
      if (_isRepeated && _repetitionType != RepetitionType.none && _endDate != null && _endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date for repeated reminders.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // For now, we'll just print the data or show a success message.
      // In Milestone 5, this data will be used to schedule actual notifications.
      print('Reminder Details:');
      print('Health Issue ID: ${widget.healthIssue.id}');
      print('Type: ${_reminderType.toString().split(".").last}');
      print('Time: ${_selectedTime!.format(context)}');
      print('Start Date: ${DateFormat.yMd().format(_startDate!)}');
      print('Is Repeated: $_isRepeated');
      if (_isRepeated) {
        print('Repetition: ${_repetitionType.toString().split(".").last}');
        if (_repetitionType == RepetitionType.custom) {
          print('Custom Repetition: ${_customRepetitionController.text.trim()}');
        }
        if (_endDate != null) {
          print('End Date: ${DateFormat.yMd().format(_endDate!)}');
        }
      }

      // Simulate saving
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder details noted. Actual notifications in Milestone 5.')),
        );
        Navigator.pop(context, true); // Return true to indicate success (for now)
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Reminder for ${widget.healthIssue.issueName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Reminder Type Dropdown
              DropdownButtonFormField<ReminderType>(
                decoration: const InputDecoration(labelText: 'Reminder Type', border: OutlineInputBorder()),
                value: _reminderType,
                items: ReminderType.values.map((ReminderType type) {
                  return DropdownMenuItem<ReminderType>(
                    value: type,
                    child: Text(type.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim()),                  );
                }).toList(),
                onChanged: (ReminderType? newValue) {
                  setState(() {
                    _reminderType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              // Time Picker
              ListTile(
                title: Text(_selectedTime == null ? 'Select Reminder Time' : 'Time: ${_selectedTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              const SizedBox(height: 16.0),
              // Start Date Picker
              ListTile(
                title: Text(_startDate == null ? 'Select Start Date' : 'Start Date: ${DateFormat.yMd().format(_startDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context, isStartDate: true),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              const SizedBox(height: 16.0),
              // Repeated Toggle
              SwitchListTile(
                title: const Text('Repeat Reminder?'),
                value: _isRepeated,
                onChanged: (bool value) {
                  setState(() {
                    _isRepeated = value;
                    if (!_isRepeated) {
                      _repetitionType = RepetitionType.none;
                      _endDate = null; // Clear end date if not repeated
                    }
                  });
                },
              ),
              if (_isRepeated)
                Column(
                  children: [
                    const SizedBox(height: 8.0),
                    // Repetition Type Dropdown
                    DropdownButtonFormField<RepetitionType>(
                      decoration: const InputDecoration(labelText: 'How Often?', border: OutlineInputBorder()),
                      value: _repetitionType,
                      items: RepetitionType.values.map((RepetitionType type) {
                        return DropdownMenuItem<RepetitionType>(
                          value: type,
                          child: Text(type.toString().split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim()),
                        );
                      }).toList(),
                      onChanged: (RepetitionType? newValue) {
                        setState(() {
                          _repetitionType = newValue!;
                        });
                      },
                      validator: (value) => value == null || value == RepetitionType.none && _isRepeated ? 'Please select repetition type' : null,
                    ),
                    if (_repetitionType == RepetitionType.custom)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: _customRepetitionController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Repetition Details',
                            hintText: 'e.g., Every Mon, Wed, Fri or Every 3 days',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_repetitionType == RepetitionType.custom && (value == null || value.trim().isEmpty)) {
                              return 'Please specify custom repetition details.';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 16.0),
                    // End Date Picker (Optional for repeated)
                    ListTile(
                      title: Text(_endDate == null ? 'Select End Date (Optional)' : 'End Date: ${DateFormat.yMd().format(_endDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(context, isStartDate: false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                  ],
                ),
              const SizedBox(height: 32.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.alarm_add),
                      label: const Text('Save Reminder Details'),
                      onPressed: _submitReminder,
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

