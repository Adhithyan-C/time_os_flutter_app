// lib/models/event_model.dart (ENHANCED)

import 'package:flutter/material.dart';

enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

// NEW: Event Type Enum
enum EventType {
  class_, // Using class_ to avoid Dart keyword
  personal,
  exercise,
  meal,
  work,
  other,
}

class FixedEvent {
  final int? id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<DayOfWeek> daysOfWeek;
  final EventType eventType; // NEW FIELD

  FixedEvent({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    this.eventType = EventType.other, // Default value
  });

  Map<String, dynamic> toMap() {
    final int startMinutes = startTime.hour * 60 + startTime.minute;
    final int endMinutes = endTime.hour * 60 + endTime.minute;
    final String daysString = daysOfWeek.map((day) => day.index).join(',');

    return {
      'id': id,
      'name': name,
      'startTime': startMinutes,
      'endTime': endMinutes,
      'daysOfWeek': daysString,
      'eventType': eventType.index, // Store as integer
    };
  }

  factory FixedEvent.fromMap(Map<String, dynamic> map) {
    final TimeOfDay start = TimeOfDay(
      hour: map['startTime'] ~/ 60,
      minute: map['startTime'] % 60,
    );
    final TimeOfDay end = TimeOfDay(
      hour: map['endTime'] ~/ 60,
      minute: map['endTime'] % 60,
    );
    final List<DayOfWeek> days = map['daysOfWeek']
        .split(',')
        .map<DayOfWeek>((dayIndex) => DayOfWeek.values[int.parse(dayIndex)])
        .toList();

    return FixedEvent(
      id: map['id'],
      name: map['name'],
      startTime: start,
      endTime: end,
      daysOfWeek: days,
      eventType: map['eventType'] != null
          ? EventType.values[map['eventType']]
          : EventType.other,
    );
  }

  // Helper: Get color for event type
  Color getTypeColor() {
    switch (eventType) {
      case EventType.class_:
        return const Color(0xFF3B82F6); // Blue
      case EventType.exercise:
        return const Color(0xFF10B981); // Green
      case EventType.meal:
        return const Color(0xFFF59E0B); // Orange
      case EventType.work:
        return const Color(0xFF8B5CF6); // Purple
      case EventType.personal:
        return const Color(0xFFEC4899); // Pink
      case EventType.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Helper: Get icon for event type
  IconData getTypeIcon() {
    switch (eventType) {
      case EventType.class_:
        return Icons.school;
      case EventType.exercise:
        return Icons.fitness_center;
      case EventType.meal:
        return Icons.restaurant;
      case EventType.work:
        return Icons.work;
      case EventType.personal:
        return Icons.person;
      case EventType.other:
        return Icons.event;
    }
  }
}
