import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart' hide Column;

class SyncProgressBar extends StatefulWidget {
  final PowerSyncDatabase db;

  /// When set, show progress towards the [BucketPriority] instead of towards
  /// the full sync.
  final BucketPriority? priority;

  const SyncProgressBar({super.key, required this.db, this.priority});

  @override
  State<SyncProgressBar> createState() => _SyncProgressBarState();
}

class _SyncProgressBarState extends State<SyncProgressBar> {
  late Stopwatch _stopwatch;
  bool _isSyncing = false;
  Duration _lastSyncDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;

    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    } else if (seconds > 0) {
      return '$seconds.${milliseconds.toString().padLeft(3, '0')}s';
    } else {
      return '${milliseconds}ms';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: widget.db.statusStream,
      initialData: widget.db.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.requireData;
        final progress = switch (widget.priority) {
          null => status.downloadProgress,
          var priority? => status.downloadProgress?.untilPriority(priority),
        };

        // Start or stop the stopwatch based on sync status
        if (progress != null && !_isSyncing) {
          _stopwatch
            ..reset()
            ..start();
          _isSyncing = true;

          debugPrint("Sync started");
        } else if (progress == null && _isSyncing && status.hasSynced == true) {
          _stopwatch.stop();
          _isSyncing = false;
          _lastSyncDuration = _stopwatch.elapsed;
          debugPrint('Sync completed in ${_lastSyncDuration.inMilliseconds}ms');
        }

        if (progress != null) {
          return Center(
            child: Column(
              children: [
                const Text(
                  'Busy with sync...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress.downloadedFraction),
                const SizedBox(height: 8),
                Text(
                  '${progress.downloadedOperations} out of ${progress.totalOperations}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Elapsed time: ${_formatDuration(_stopwatch.elapsed)}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              children: [
                const Text(
                  'No sync in progress',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (_lastSyncDuration != Duration.zero) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last sync took: ${_formatDuration(_lastSyncDuration)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }
}
