import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import './models/schema.dart';
import './models/counter.dart';
import './powersync.dart';
import './widgets/status_app_bar.dart';

void main() async {
  // Set up logging for debugging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('[${record.loggerName}] ${record.level.name}: ${record.message}');
      if (record.error != null) print(record.error);
      if (record.stackTrace != null) print(record.stackTrace);
    }
  });

  // Initialize Flutter and open database connection
  WidgetsFlutterBinding.ensureInitialized();
  await openDatabase();

  final loggedIn = isLoggedIn();

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerSync Counter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CountersPage(),
    );
  }
}

/// Main page that displays the list of counters
class CountersPage extends StatelessWidget {
  const CountersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StatusAppBar(title: Text('Counter Demo')),
      body: const CountersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Counter.create();
        },
        tooltip: 'Add new counter',
        child: const Icon(Icons.add),
      ),
      // Simple drawer menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                Navigator.pop(context);
                await logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays a live-updating list of counters
class CountersList extends StatelessWidget {
  const CountersList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Counter>>(
      stream: Counter.watchCounters(),
      builder: (context, snapshot) {
        // Show loading indicator while data loads
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final counters = snapshot.data!;

        // Show helpful message when no counters exist
        if (counters.isEmpty) {
          return const Center(
            child: Text(
              'No counters yet!\nTap the + button to add one.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Build the list of counter cards
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: counters.length,
          itemBuilder: (context, index) {
            final counter = counters[index];

            return Dismissible(
              key: ValueKey(counter.id),
              direction: DismissDirection.endToStart,
              // Red background when swiping to delete
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              // Confirm before deleting
              confirmDismiss: (direction) async {
                return await _showDeleteConfirmation(context);
              },
              onDismissed: (direction) async {
                await counter.delete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Counter deleted')));
              },
              child: _buildCounterCard(counter),
            );
          },
        );
      },
    );
  }

  /// Builds an individual counter card
  Widget _buildCounterCard(Counter counter) {
    // Truncate the ID to first 8 characters for display
    final displayId = counter.id.length > 8
        ? '${counter.id.substring(0, 8)}...'
        : counter.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Counter info on the left
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: $displayId',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Count: ${counter.count}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  // Show creation date if available
                  if (counter.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDate(counter.createdAt!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            // Counter controls on the right
            Row(
              children: [
                // Decrement button
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: () async {
                    if (counter.count > 0) {
                      await db.execute(
                        'UPDATE $countersTable SET count = ? WHERE id = ?',
                        [counter.count - 1, counter.id],
                      );
                    }
                  },
                ),
                // Current count display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${counter.count}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Increment button
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () async {
                    await counter.increment();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows confirmation dialog before deleting a counter
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Counter?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Formats date string for display
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
