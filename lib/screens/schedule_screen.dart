// lib/screens/schedule_screen.dart (WITH CHRONOLOGICAL SORTING)

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/screens/edit_event_screen.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/screens/add_event_screen.dart';
import 'package:time_os_final/helpers/sorting_helper.dart'; // NEW

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<FixedEvent>> _eventList;
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
          // Day selector
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

          // Events list
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

                  // Filter for selected day
                  final dayToFilter = DayOfWeek.values[_selectedDayIndex];
                  final filteredEvents = snapshot.data!
                      .where((event) => event.daysOfWeek.contains(dayToFilter))
                      .toList();

                  // BUG FIX: Chronological sorting by start time
                  final sortedEvents = SortingHelper.sortEventsChronologically(
                    filteredEvents,
                  );

                  if (sortedEvents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: AppColors.secondaryText.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events on ${_getDayName(_selectedDayIndex)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event count
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sortedEvents.length} event${sortedEvents.length != 1 ? 's' : ''} (sorted by time)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Event list
                      Expanded(
                        child: ListView.builder(
                          itemCount: sortedEvents.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () =>
                                    _navigateToEditEvent(sortedEvents[index]),
                                child: _EventCard(event: sortedEvents[index]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int index) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[index];
  }
}

// Event card widget with type indicator
class _EventCard extends StatelessWidget {
  final FixedEvent event;

  const _EventCard({required this.event});

  String _formatDays() {
    if (event.daysOfWeek.length == 7) return 'Every Day';
    List<DayOfWeek> sortedDays = List.from(event.daysOfWeek)
      ..sort((a, b) => a.index.compareTo(b.index));
    return sortedDays
        .map((day) => day.name.substring(0, 1).toUpperCase())
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.getTypeColor().withAlpha(77), width: 2),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: event.getTypeColor().withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              event.getTypeIcon(),
              color: event.getTypeColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Event details
          Expanded(
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
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.startTime.format(context)} - ${event.endTime.format(context)}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.getTypeColor().withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDays(),
                        style: TextStyle(
                          color: event.getTypeColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
