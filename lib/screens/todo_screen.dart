import 'package:flutter/material.dart';
import '../state/todo_state.dart';
import '../widgets/todo_widgets.dart';
import '../widgets/circle_drawer.dart';

class TodoScreen extends StatefulWidget {
  final TodoState state;

  const TodoScreen({super.key, required this.state});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _passphraseController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _submitPassphrase() async {
    final text = _passphraseController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Passphrase cannot be empty');
      return;
    }
    if (text.length < 6) {
      setState(() => _errorMessage = 'Passphrase must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.state.initializeKeyWithPassphrase(text);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to set key: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPassphraseScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Setup'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.state.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.enhanced_encryption,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              Text(
                'End-to-End Encryption',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'To secure your private tasks, please set or enter your security passphrase. This passphrase is never sent to our servers and is used to encrypt and decrypt tasks locally on your device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passphraseController,
                decoration: InputDecoration(
                  labelText: 'Security Passphrase',
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                obscureText: true,
                onSubmitted: (_) => _submitPassphrase(),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitPassphrase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Unlock Secure Tasks'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        if (widget.state.needsPassphrase) {
          return _buildPassphraseScreen(context);
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            drawer: CircleDrawer(state: widget.state),
            appBar: AppBar(
              title: Text(
                widget.state.activeCircle?.name ?? 'Tickr',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: widget.state.signOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                    text: 'Todo (${widget.state.todoItems.length})',
                    icon: const Icon(Icons.list),
                  ),
                  Tab(
                    text: 'Done (${widget.state.doneItems.length})',
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
                    TodoInputField(onSubmitted: widget.state.addItem),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: widget.state.todoItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.state.todoItems[index];
                          return TodoItemTile(
                            item: item,
                            onDismissed: () => widget.state.completeItem(item.id),
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
                    if (widget.state.doneItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: widget.state.clearDone,
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
                        itemCount: widget.state.doneItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.state.doneItems[index];
                          return TodoItemTile(
                            item: item,
                            onDismissed: () => widget.state.deleteItem(item.id),
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
