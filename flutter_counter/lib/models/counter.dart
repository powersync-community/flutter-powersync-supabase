import 'package:flutter_supabase_template/models/schema.dart';
import 'package:powersync/sqlite3_common.dart' as sqlite;
import '../powersync.dart';

/// Counter represents a result row of a query on "counters".
///
/// This class is immutable; methods on this class do not modify the instance
/// directly. Instead, watch or re-query the data to get the updated counter.
class Counter {
  /// Counter id (UUID).
  final String id;

  /// The counter's current value.
  final int count;

  /// The ID of the user who owns this counter.
  final String? ownerId;

  /// The creation timestamp.
  final String? createdAt;

  Counter({
    required this.id,
    required this.count,
    this.ownerId,
    this.createdAt,
  });

  factory Counter.fromRow(sqlite.Row row) {
    return Counter(
      id: row['id'],
      count: row['count'],
      ownerId: row['owner_id'],
      createdAt: row['created_at'],
    );
  }

  /// Watch all counters.
  static Stream<List<Counter>> watchCounters() {
    return db.watch('SELECT * FROM $countersTable ORDER BY created_at, id').map(
      (results) {
        return results.map(Counter.fromRow).toList(growable: false);
      },
    );
  }

  /// Create a new counter.
  static Future<Counter> create() async {
    final results = await db.execute(
      '''
      INSERT INTO
        $countersTable(id, count, owner_id, created_at)
        VALUES(uuid(), ?, ?, datetime())
      RETURNING *
      ''',
      [0, getUserId()],
    );
    return Counter.fromRow(results.first);
  }

  /// Increment the counter's value by one.
  Future<void> increment() async {
    await db.execute('UPDATE $countersTable SET count = ? WHERE id = ?', [
      count + 1,
      id,
    ]);
  }

  /// Delete this counter.
  Future<void> delete() async {
    await db.execute('DELETE FROM $countersTable WHERE id = ?', [id]);
  }
}
