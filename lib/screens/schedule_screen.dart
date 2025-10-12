// lib/screens/schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/screens/edit_event_screen.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/screens/add_event_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<FixedEvent>> _eventList;
  // We use DateTime.now().weekday % 7 to handle Sunday correctly (DateTime.sunday is 7)
  int _selectedDayIndex = DateTime.now().weekday % 7;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventList = DatabaseHelper.instance.getAllFixedEvents();
    });
  }

  void _navigateToAddEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEventScreen()),
    );
    _loadEvents();
  }

  void _navigateToEditEvent(FixedEvent event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditEventScreen(event: event)),
    );
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeekShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryText, size: 28),
            onPressed: _navigateToAddEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- DAY SELECTOR WIDGET ---
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = index == _selectedDayIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        daysOfWeekShort[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // --- FILTERED LIST OF EVENTS ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<FixedEvent>>(
                future: _eventList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No fixed events scheduled. Add one!'),
                    );
                  }

                  // Filter the events for the selected day
                  final dayToFilter = DayOfWeek.values[_selectedDayIndex];
                  final filteredEvents = snapshot.data!
                      .where((event) => event.daysOfWeek.contains(dayToFilter))
                      .toList();

                  if (filteredEvents.isEmpty) {
                    return Center(
                      child: Text(
                        'No events scheduled for this day.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () =>
                              _navigateToEditEvent(filteredEvents[index]),
                          child: _EventCard(event: filteredEvents[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for displaying a single fixed event
class _EventCard extends StatelessWidget {
  final FixedEvent event;

  const _EventCard({required this.event});

  String _formatDays() {
    if (event.daysOfWeek.length == 7) return 'Every Day';
    List<DayOfWeek> sortedDays = List.from(event.daysOfWeek)
      ..sort((a, b) => a.index.compareTo(b.index));
    return sortedDays
        .map((day) {
          return day.name.substring(0, 1).toUpperCase();
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${event.startTime.format(context)} - ${event.endTime.format(context)}',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
              Text(
                _formatDays(),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
