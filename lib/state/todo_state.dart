import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class TodoState extends ChangeNotifier {
  final List<TodoItem> _items = [];

  List<TodoItem> get todoItems => _items.where((item) => !item.isCompleted).toList();
  List<TodoItem> get doneItems => _items.where((item) => item.isCompleted).toList();

  void addItem(String text) {
    if (text.trim().isEmpty) return;
    _items.add(TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    ));
    notifyListeners();
  }

  void completeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: true);
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearDone() {
    _items.removeWhere((item) => item.isCompleted);
    notifyListeners();
  }
}
