class TodoItem {
  final String id;
  final String text;
  final bool isCompleted;
  final String? userId; // Owner of the task
  final String? circleId; // Group this task belongs to

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.userId,
    this.circleId,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    String? userId,
    String? circleId,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      circleId: circleId ?? this.circleId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCompleted': isCompleted,
      'userId': userId,
      'circleId': circleId,
      'createdAt': id, // Using timestamp ID as a simple createdAt for now
    };
  }

  factory TodoItem.fromMap(String id, Map<String, dynamic> map) {
    return TodoItem(
      id: id,
      text: map['text'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'],
      circleId: map['circleId'],
    );
  }
}
