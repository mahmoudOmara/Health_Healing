import 'package:flutter/material.dart';
import 'package:health_healing/models/calendar_event.dart';
import 'package:health_healing/models/health_issue.dart'; // For fetching health issues
import 'package:health_healing/services/calendar_event_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarEventService _calendarEventService = CalendarEventService();
  final Uuid _uuid = Uuid();

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedDayEvents = [];
  String _currentFilter = "All"; // All, Medication, Appointment, Custom, Follow-up
  final List<String> _eventTypesForFilter = ["All", "Medication", "Appointment", "Custom", "Follow-up"];


  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadEventsForMonth(_focusedDay);
    _loadEventsForDay(_focusedDay);
  }

  void _loadEventsForMonth(DateTime month) {
    // This stream will update the _events map which table_calendar uses to mark days
    _calendarEventService.getCalendarEventsForMonth(month).listen((monthlyEvents) {
      if (!mounted) return;
      final Map<DateTime, List<CalendarEvent>> newEventsMap = {};
      for (var event in monthlyEvents) {
        final day = DateTime.utc(event.eventDate.toDate().year, event.eventDate.toDate().month, event.eventDate.toDate().day);
        if (newEventsMap[day] == null) {
          newEventsMap[day] = [];
        }
        newEventsMap[day]!.add(event);
      }
      setState(() {
        _events = newEventsMap;
      });
    });
  }

  void _loadEventsForDay(DateTime day) {
    _calendarEventService.getCalendarEventsForDay(day).listen((dailyEvents) {
      if (!mounted) return;
      setState(() {
        _selectedDayEvents = dailyEvents;
      });
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadEventsForDay(selectedDay);
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadEventsForMonth(focusedDay); // Load events for the new visible month
  }

  void _showAddEventBottomSheet() async {
    // Fetch health issues first
    List<HealthIssue> healthIssues = [];
    try {
      healthIssues = await _calendarEventService.getAllHealthIssues();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching health issues: $e")));
      return; // Don't show bottom sheet if issues can't be fetched
    }

    if (healthIssues.isEmpty && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a health issue first before adding an event.")),
      );
      return;
    }
    
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 20.0,
          ),
          child: _AddEventBottomSheetContent(
            calendarEventService: _calendarEventService,
            uuid: _uuid,
            healthIssues: healthIssues, // Pass the fetched health issues
            selectedDate: _selectedDay ?? DateTime.now(),
            onEventAdded: () {
              Navigator.of(bottomSheetContext).pop();
              _loadEventsForMonth(_focusedDay); // Refresh month markers
              if (_selectedDay != null) _loadEventsForDay(_selectedDay!); // Refresh day list
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event added successfully!")));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _currentFilter == "All"
        ? _selectedDayEvents
        : _selectedDayEvents.where((event) => event.eventType == _currentFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar & Reminders"),
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              // Customize styles if needed
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // Show month/week toggle if needed
              titleCentered: true,
            ),
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
          ),
          const SizedBox(height: 8.0),
          _buildFilterChips(),
          const SizedBox(height: 8.0),
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(child: Text("No events for ${DateFormat.yMMMd().format(_selectedDay!)} with filter '$_currentFilter'."))
                : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: ListTile(
                          leading: Icon(_getIconForEventType(event.eventType), color: Theme.of(context).colorScheme.primary),
                          title: Text(event.eventTitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Issue: ${event.healthIssueName}"),
                              if (event.eventDescription != null && event.eventDescription!.isNotEmpty)
                                Text("Notes: ${event.eventDescription!}"),
                              Text("Time: ${event.eventTime ?? 'All day'}"),
                            ],
                          ),
                          trailing: Checkbox(
                            value: event.isDone,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                final updatedEvent = event.copyWith(isDone: newValue);
                                _calendarEventService.updateCalendarEvent(updatedEvent).then((_){
                                   _loadEventsForDay(_selectedDay!); // Refresh list
                                   // Optionally refresh month markers if isDone affects them
                                   _loadEventsForMonth(_focusedDay);
                                }).catchError((e){
                                   if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating event: $e")));
                                });
                              }
                            },
                          ),
                          onTap: () {
                            // Optional: Show event details or edit event
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventBottomSheet,
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _eventTypesForFilter.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final type = _eventTypesForFilter[index];
            return ChoiceChip(
              label: Text(type),
              selected: _currentFilter == type,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _currentFilter = type;
                  });
                }
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForEventType(String eventType) {
    switch (eventType) {
      case "Medication":
        return Icons.medical_services_outlined;
      case "Appointment":
        return Icons.event_available_outlined;
      case "Follow-up":
        return Icons.next_plan_outlined;
      case "Custom":
      default:
        return Icons.notifications_active_outlined;
    }
  }
}

// Bottom Sheet for Adding New Event from Calendar Tab
class _AddEventBottomSheetContent extends StatefulWidget {
  final CalendarEventService calendarEventService;
  final Uuid uuid;
  final List<HealthIssue> healthIssues;
  final DateTime selectedDate;
  final VoidCallback onEventAdded;

  const _AddEventBottomSheetContent({
    required this.calendarEventService,
    required this.uuid,
    required this.healthIssues,
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  State<_AddEventBottomSheetContent> createState() => _AddEventBottomSheetContentState();
}

class _AddEventBottomSheetContentState extends State<_AddEventBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  HealthIssue? _selectedHealthIssue;
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  String? _selectedEventType = "Custom"; // Default
  bool _isLoading = false;

  final List<String> _eventTypes = ["Medication", "Appointment", "Custom", "Follow-up"];

  @override
  void initState() {
    super.initState();
    _pickedDate = widget.selectedDate;
    if (widget.healthIssues.isNotEmpty) {
      _selectedHealthIssue = widget.healthIssues.first; // Pre-select if possible
    }
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date != null && date != _pickedDate) {
      setState(() {
        _pickedDate = date;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
    );
    if (time != null && time != _pickedTime) {
      setState(() {
        _pickedTime = time;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHealthIssue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a health issue to link this event to.")),
        );
        return;
      }
      if (_pickedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an event date.")),
        );
        return;
      }
       if (_selectedEventType == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an event type.")),
        );
        return;
      }

      setState(() { _isLoading = true; });
      try {
        final title = _eventTitleController.text.trim();
        final description = _eventDescriptionController.text.trim();
        final String eventId = widget.uuid.v4();
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception("User not logged in.");
        }

        DateTime finalDateTime = DateTime(
          _pickedDate!.year,
          _pickedDate!.month,
          _pickedDate!.day,
          _pickedTime?.hour ?? 0,
          _pickedTime?.minute ?? 0,
        );

        final newEvent = CalendarEvent(
          eventId: eventId,
          healthIssueId: _selectedHealthIssue!.id!,
          healthIssueName: _selectedHealthIssue!.issueName,
          eventTitle: title,
          eventDescription: description.isNotEmpty ? description : null,
          eventDate: Timestamp.fromDate(finalDateTime),
          eventTime: _pickedTime != null ? _pickedTime!.format(context) : null,
          eventType: _selectedEventType!,
          createdAt: Timestamp.now(),
          userId: currentUser.uid,
        );

        await widget.calendarEventService.addCalendarEvent(newEvent);
        widget.onEventAdded();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add event: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Add New Calendar Event",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            DropdownButtonFormField<HealthIssue>(
              decoration: const InputDecoration(
                labelText: "Link to Health Issue*",
                border: OutlineInputBorder(),
              ),
              value: _selectedHealthIssue,
              items: widget.healthIssues.map((HealthIssue issue) {
                return DropdownMenuItem<HealthIssue>(
                  value: issue,
                  child: Text(issue.issueName, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (HealthIssue? newValue) {
                setState(() {
                  _selectedHealthIssue = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select a health issue' : null,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _eventTitleController,
              decoration: const InputDecoration(
                labelText: "Event Title*",
                hintText: "e.g., Morning Pills, Check Blood Sugar",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter an event title.";
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _eventDescriptionController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                hintText: "Additional details for the event...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Event Type*",
                border: OutlineInputBorder(),
              ),
              value: _selectedEventType,
              items: _eventTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedEventType = newValue;
                });
              },
              validator: (value) => value == null ? 'Please select an event type' : null,
            ),
            const SizedBox(height: 16.0),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_pickedDate == null
                  ? "Select Event Date*"
                  : DateFormat.yMMMd().format(_pickedDate!)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickDate(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_outlined),
              title: Text(_pickedTime == null
                  ? "Select Event Time (Optional)"
                  : _pickedTime!.format(context)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _pickTime(context),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text("Save Event"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              onPressed: _isLoading ? null : _saveEvent,
            ),
            if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}


