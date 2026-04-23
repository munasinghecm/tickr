import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItem {
  final String id;
  final String text;
  final bool isCompleted;
  final String? userId;
  final String? circleId;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.userId,
    this.circleId,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    String? userId,
    String? circleId,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      circleId: circleId ?? this.circleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCompleted': isCompleted,
      'userId': userId,
      'circleId': circleId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TodoItem.fromMap(String id, Map<String, dynamic> map) {
    return TodoItem(
      id: id,
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'],
      circleId: map['circleId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
