import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart' hide Column;

import '../powersync.dart';

/// Displays PowerSync connection status, SDK info and helpful links.
class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StatusSection()),
                  const SizedBox(width: 16),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_StatusSection(), const SizedBox(height: 16)],
              );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: content,
        );
      },
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PowerSync Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  _kv('lastSyncedAt', status.lastSyncedAt?.toString() ?? 'N/A'),
                  _kv('userId', getUserId() ?? 'Not authenticated'),
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
