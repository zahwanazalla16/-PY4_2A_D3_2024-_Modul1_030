import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late bool _isPublic;
  late String _selectedCategory;
  int _selectedTab = 0;

  final List<String> _categories = ['mechanical', 'electronic', 'software'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPublic = widget.log?.isPublic ?? false;
    _selectedCategory = widget.log?.category ?? 'mechanical';

    // Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }

    final logModel = LogModel(
      id: widget.log?.id,
      title: _titleController.text,
      description: _descController.text,
      date: widget.log?.date ?? DateTime.now(),
      category: _selectedCategory,
      username: widget.currentUser is String 
          ? widget.currentUser 
          : widget.controller.username,
      authorId: widget.log?.authorId ?? widget.controller.userId,
      teamId: widget.log?.teamId ?? widget.controller.teamId,
      isPublic: _isPublic,
      isSynced: false, // Set false initially, controller will update if sync succeeds
    );

    if (widget.log == null) {
      // Tambah Baru
      widget.controller.addLogDirect(logModel);
    } else {
      // Update
      widget.controller.updateLogDirect(widget.index!, logModel);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.log == null ? "Catatan Baru" : "Edit Catatan";

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        elevation: 0,
        actions: [
          // Save Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Editor',
                          style: TextStyle(
                            fontWeight: _selectedTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pratinjau',
                          style: TextStyle(
                            fontWeight: _selectedTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: _selectedTab == 0
                ? _buildEditorTab()
                : _buildPreviewTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Judul',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.category),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category[0].toUpperCase() + category.substring(1)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCategory = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Privacy Dropdown
          DropdownButtonFormField<bool>(
            initialValue: _isPublic,
            decoration: InputDecoration(
              labelText: 'Privasi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(_isPublic ? Icons.public : Icons.lock),
            ),
            items: const [
              DropdownMenuItem(value: false, child: Text('Private')),
              DropdownMenuItem(value: true, child: Text('Public')),
            ],
            onChanged: (bool? newValue) {
              if (newValue != null) {
                setState(() {
                  _isPublic = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Markdown Guide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📝 Panduan Markdown:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildMarkdownGuide('# Heading 1', 'Untuk judul besar'),
                _buildMarkdownGuide('## Heading 2', 'Untuk subjudul'),
                _buildMarkdownGuide('**teks** atau __teks__', 'Untuk teks tebal'),
                _buildMarkdownGuide('*teks* atau _teks_', 'Untuk teks miring'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Input
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Isi Catatan (Markdown)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Tulis catatan Anda di sini...',
              alignLabelWithHint: true,
            ),
            minLines: 12,
            maxLines: 20,
            textAlignVertical: TextAlignVertical.top,
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownGuide(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              syntax,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Preview
          Text(
            _titleController.text.isEmpty
                ? '(Judul akan muncul di sini)'
                : _titleController.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Description Preview (Markdown)
          if (_descController.text.isEmpty)
            const Text(
              '(Preview Markdown akan muncul di sini)',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          else
            MarkdownBody(
              data: _descController.text,
              selectable: true,
            ),
        ],
      ),
    );
  }
}
