import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart' hide Column;

import '../powersync.dart';

/// Displays PowerSync connection status
class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: _StatusSection(),
    );
  }
}

class _StatusSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<SyncStatus>(
          stream: db.statusStream,
          initialData: db.currentStatus,
          builder: (context, snapshot) {
            final status = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'PowerSync Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (status != null) ...[
                  _kv('connected', status.connected.toString()),
                  _kv('connecting', status.connecting.toString()),
                  _kv('uploading', status.uploading.toString()),
                  _kv('downloading', status.downloading.toString()),
                  _kv(
                    'downloadProgress',
                    status.downloadProgress?.downloadedFraction != null
                        ? '${(status.downloadProgress!.downloadedFraction * 100).toStringAsFixed(2)}%'
                        : '0%',
                  ),
                  _kv('hasSynced', (status.hasSynced ?? false).toString()),
                  _kv(
                    'lastSyncedAt',
                    status.lastSyncedAt?.toIso8601String() ?? 'N/A',
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String keyLabel, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.black,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$keyLabel: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
