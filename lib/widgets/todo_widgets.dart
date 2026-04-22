import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class TodoInputField extends StatefulWidget {
  final Function(String) onSubmitted;

  const TodoInputField({super.key, required this.onSubmitted});

  @override
  State<TodoInputField> createState() => _TodoInputFieldState();
}

class _TodoInputFieldState extends State<TodoInputField> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    if (_controller.text.isNotEmpty) {
      widget.onSubmitted(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'What needs to be done?',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_circle),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _submit,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TodoItemTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onDismissed;
  final Color dismissColor;
  final IconData dismissIcon;
  final String dismissLabel;

  const TodoItemTile({
    super.key,
    required this.item,
    required this.onDismissed,
    required this.dismissColor,
    required this.dismissIcon,
    required this.dismissLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: dismissColor,
        child: Row(
          children: [
            Icon(dismissIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              dismissLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ListTile(
          title: Text(
            item.text,
            style: TextStyle(
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? Theme.of(context).colorScheme.outline
                  : null,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: item.isCompleted
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              item.isCompleted ? Icons.check : Icons.radio_button_unchecked,
              color: item.isCompleted
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
