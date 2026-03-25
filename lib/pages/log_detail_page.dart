import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../features/models/log_model.dart';
import '../../services/access_policy.dart' show AccessControlService;

class LogDetailPage extends StatelessWidget {

  final LogModel log;
  final String currentRole;
  final String? currentUserId;

  const LogDetailPage({
    super.key,
    required this.log,
    required this.currentRole,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && log.authorId == currentUserId;
    
    final canDelete = AccessControlService.canPerform(
      currentRole, 
      'delete',
      isOwner: isOwner,
    );
    final canEdit = AccessControlService.canPerform(
      currentRole, 
      'update',
      isOwner: isOwner,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(log.title),
        actions: [
          // Status badge (Public/Private)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Chip(
                label: Text(log.isPublic ? 'Public' : 'Private'),
                backgroundColor: log.isPublic 
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              log.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  "Kategori: ${log.category}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  "Oleh: ${log.username}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: log.description,
                  selectable: true,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                if (canEdit)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'edit');
                    },
                    child: const Text("Edit"),
                  ),

                const SizedBox(width: 10),

                if (canDelete)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context, 'delete');
                    },
                    child: const Text("Delete"),
                  ),

              ],
            )

          ],
        ),
      ),
    );
  }
}