import 'package:intl/intl.dart';

class Memory {
  final int? id;
  final String imagePath;
  final String note;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  Memory({
    this.id,
    required this.imagePath,
    required this.note,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as int,
      imagePath: map['imagePath'] as String,
      note: map['note'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMMM d, y').format(timestamp);
    }
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }
} 