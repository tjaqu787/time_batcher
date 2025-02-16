// time_entry.dart
class TimeEntry {
  final int? id;
  final DateTime timestamp;
  final String description;
  final int rating;
  final DateTime createdAt;

  TimeEntry({
    this.id,
    required this.timestamp,
    required this.description,
    required this.rating,
    required this.createdAt,
  });

  // Convert TimeEntry to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create TimeEntry from Map (database row)
  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'],
      rating: map['rating'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
