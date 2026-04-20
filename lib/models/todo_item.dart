class TodoItem {
  final String id;
  final String text;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
