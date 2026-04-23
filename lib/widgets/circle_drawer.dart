import 'package:flutter/material.dart';
import '../state/todo_state.dart';

class CircleDrawer extends StatelessWidget {
  final TodoState state;
  const CircleDrawer({super.key, required this.state});

  void _showCreateCircle(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Circle Name (e.g. Family)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              state.createCircle(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinCircle(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Circle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter Invite Code'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await state.joinCircle(controller.text);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(state.user?.email?.split('@')[0] ?? 'User'),
            accountEmail: Text(state.user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.teal),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Private Tasks'),
            selected: state.activeCircle == null,
            onTap: () {
              state.switchCircle(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CIRCLES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showCreateCircle(context),
                  tooltip: 'Create Circle',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: state.circles.length,
              itemBuilder: (context, index) {
                final circle = state.circles[index];
                return ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(circle.name),
                  subtitle: Text('Code: ${circle.inviteCode}', style: const TextStyle(fontSize: 12)),
                  selected: state.activeCircle?.id == circle.id,
                  onTap: () {
                    state.switchCircle(circle);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('Join a Circle'),
            onTap: () => _showJoinCircle(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              state.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
