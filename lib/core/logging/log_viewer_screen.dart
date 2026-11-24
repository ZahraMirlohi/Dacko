// lib/core/logging/log_viewer_screen.dart
// نمایشگر لاگ برای عیب‌یابی: فیلتر سطح/جستجو، جلسه‌های قبلی (از فایل)، کپی، اشتراک‌گذاری، پاک‌کردن.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '/l10n/app_strings.dart';
import 'app_logger.dart';
import '/core/dk.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  LogLevel _min = LogLevel.info;
  String _q = '';
  bool _disk = false;
  List<LogRecord> _diskRecs = const [];

  static Color _color(LogLevel l) {
    switch (l) {
      case LogLevel.fatal:
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warn:
        return Colors.orange;
      case LogLevel.info:
        return Colors.blue;
      default:
        return Dk.s(Colors.grey);
    }
  }

  List<LogRecord> _filtered(List<LogRecord> src) {
    final q = _q.trim().toLowerCase();
    return src
        .where((r) =>
            r.level.index >= _min.index &&
            (q.isEmpty || r.tag.toLowerCase().contains(q) || r.message.toLowerCase().contains(q)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> _toggleDisk() async {
    if (!_disk) _diskRecs = await Log.readHistory();
    if (mounted) setState(() => _disk = !_disk);
  }

  Future<void> _share() async {
    final f = await Log.exportFile();
    if (f == null) return;
    await Share.shareXFiles([XFile(f.path)], text: 'Dacko logs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('log.title')),
        actions: [
          IconButton(
            tooltip: context.tr('log.history'),
            icon: Icon(_disk ? Icons.history_toggle_off : Icons.history),
            onPressed: _toggleDisk,
          ),
          IconButton(
            tooltip: context.tr('log.copy'),
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              final src = _disk ? _diskRecs : Log.recent;
              final text = _filtered(src).reversed.map((r) => r.toLine()).join('\n');
              await Clipboard.setData(ClipboardData(text: text));
            },
          ),
          IconButton(tooltip: context.tr('log.share'), icon: const Icon(Icons.ios_share_rounded), onPressed: _share),
          IconButton(
            tooltip: context.tr('log.clear'),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await Log.clear();
              if (mounted) setState(() => _diskRecs = const []);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: context.tr('log.search'),
                    ),
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<LogLevel>(
                  value: _min,
                  items: [
                    for (final l in LogLevel.values) DropdownMenuItem(value: l, child: Text(l.name)),
                  ],
                  onChanged: (l) => setState(() => _min = l ?? _min),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: Log.version,
              builder: (context, _, __) {
                final list = _filtered(_disk ? _diskRecs : Log.recent);
                if (list.isEmpty) return Center(child: Text(context.tr('log.empty')));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final hasMore = r.error != null || r.stack != null || (r.fields?.isNotEmpty ?? false);
                    final head = Text(
                      '${r.time.toLocal().toIso8601String().substring(11, 23)}  ${r.tag}  ${r.message}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    );
                    final dot = Icon(Icons.circle, size: 10, color: _color(r.level));
                    if (!hasMore) return ListTile(dense: true, leading: dot, title: head);
                    return ExpansionTile(
                      dense: true,
                      leading: dot,
                      title: head,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: SelectableText(
                            r.toLine(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
