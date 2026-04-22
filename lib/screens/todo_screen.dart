import 'package:flutter/material.dart';
import '../state/todo_state.dart';
import '../widgets/todo_widgets.dart';

class TodoScreen extends StatelessWidget {
  final TodoState state;

  const TodoScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Tickr',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: state.signOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                    text: 'Todo (${state.todoItems.length})',
                    icon: const Icon(Icons.list),
                  ),
                  Tab(
                    text: 'Done (${state.doneItems.length})',
                    icon: const Icon(Icons.done_all),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Todo Tab
                Column(
                  children: [
                    TodoInputField(onSubmitted: state.addItem),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: state.todoItems.length,
                        itemBuilder: (context, index) {
                          final item = state.todoItems[index];
                          return TodoItemTile(
                            item: item,
                            onDismissed: () => state.completeItem(item.id),
                            dismissColor: Colors.green,
                            dismissIcon: Icons.check,
                            dismissLabel: 'Complete',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Done Tab
                Column(
                  children: [
                    if (state.doneItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: state.clearDone,
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Clear All Done',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: state.doneItems.length,
                        itemBuilder: (context, index) {
                          final item = state.doneItems[index];
                          return TodoItemTile(
                            item: item,
                            onDismissed: () => state.deleteItem(item.id),
                            dismissColor: Colors.red,
                            dismissIcon: Icons.delete,
                            dismissLabel: 'Delete',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
