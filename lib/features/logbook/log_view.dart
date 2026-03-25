import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/helpers/date_formatter.dart';
import 'package:logbook_app_001/helpers/connection_checker.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/pages/log_detail_page.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'dart:async';
import 'log_controller.dart';
class LogView extends StatefulWidget {
  final String username;
  final String role;

  const LogView({
    super.key,
    required this.username,
    required this.role,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  bool _isOnline = true;
  late StreamSubscription<bool> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    _controller = LogController(
      username: widget.username,
      userId: widget.username,
      userRole: widget.role,
      teamId: 'default_team',
    );
    
    // Monitor connection status
    _connectionSubscription = ConnectionChecker().connectionStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          // Sync all unsynced logs when back online
          _controller.syncAllUnsyncedLogs();
        }
      }
    });
    
    // Pastikan controller selesai init, baru jalankan database init
    _controller.ensureInitialized().then((_) {
      if (mounted) {
        _initDatabase();
      }
    });
  }

  Future<void> _initDatabase() async {
    try {
      // 1. LOAD LOCAL DATA FIRST (Mencegah Layar Putih)
      await LogHelper.writeLog("UI: Loading data lokal dari Hive...", source: "log_view.dart");
      await _controller.init(); // Ini akan memanggil loadFromDisk() internal
      
      if (mounted) setState(() {}); // Refresh UI dengan data Hive yang ada

      // 2. BACKGROUND CONNECT & SYNC
      _attemptCloudConnection();

    } catch (e) {
      await LogHelper.writeLog("UI: Error Init - $e", source: "log_view.dart", level: 1);
    }
  }

  Future<void> _attemptCloudConnection() async {
    try {
      await LogHelper.writeLog("UI: Mencoba koneksi background ke Cloud...", source: "log_view.dart");
      
      // Kurangi timeout ke 5-7 detik saja agar tidak menggantung lama
      await MongoService().connect().timeout(
        const Duration(seconds: 7),
        onTimeout: () => throw Exception("Cloud Connection Timeout"),
      );

      await LogHelper.writeLog("UI: Koneksi Cloud Berhasil, melakukan sinkronisasi...", source: "log_view.dart");
      
      // Fetch data terbaru jika online
      await _controller.loadFromDisk(); 
      
      if (mounted) setState(() {});
    } catch (e) {
      await LogHelper.writeLog("UI: Offline/Timeout - Menggunakan mode lokal. ($e)", source: "log_view.dart", level: 3);
      // Tidak perlu throw agar UI tetap jalan dengan data lokal
    }
  }

  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _contentController =
      TextEditingController();
  
  // Categories
  final List<String> categories = ['mechanical', 'electronic', 'software'];
  String selectedCategory = 'mechanical';

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginView(),
                ),
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Filter logs based on privacy & search keyword
  List<LogModel> _getFilteredLogs(List<LogModel> allLogs) {
    final searchKeyword = _controller.searchNotifier.value.toLowerCase();
    final currentUserId = _controller.userId;
    
    // 1. Privacy filter: Tampilkan jika owner ATAU public
    final privacyFiltered = allLogs.where((log) {
      return log.authorId == currentUserId || log.isPublic == true;
    }).toList();
    
    // 2. Search filter
    if (searchKeyword.isEmpty) {
      return privacyFiltered;
    }
    
    return privacyFiltered
        .where((log) =>
            log.title.toLowerCase().contains(searchKeyword) ||
            log.description.toLowerCase().contains(searchKeyword) ||
            log.category.toLowerCase().contains(searchKeyword))
        .toList();
  }

  // Get warna pastel berdasarkan kategori
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'mechanical':
        return const Color(0xFFFFE5B4); // Kuning pastel
      case 'software':
        return const Color(0xFFFFB3D9); // Pink pastel
      case 'electronic':
        return const Color(0xFFB3D9FF); // Biru pastel
      default:
        return const Color(0xFFFFE5B4);
    }
  }

  // ================= ADD =================
  void _showAddLogDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: null,
          index: null,
          controller: _controller,
          currentUser: widget.username,
        ),
      ),
    );
  }

  // ================= EDIT =================
  void _showEditLogDialog(int index, LogModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.username,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _connectionSubscription.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook App: ${widget.username} (${widget.role})"),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
              _controller.refreshData();
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Online/Offline Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: _isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => _controller.searchLog(value),
              decoration: const InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // VALUE-LISTENABLE-BASED LIST
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, logs, child) {

                // 2. No Data State
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("Belum ada catatan di Logbook."),
                        const SizedBox(height: 13),
                        const Text("Coba buat catatan pertama Anda."),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showAddLogDialog,
                          child: const Text(" + Buat Catatan"),
                        ),
                      ],
                    ),
                  );
                }

                // 3. Success State - Display List
                final displayLogs = _getFilteredLogs(logs); // Filter based on search & privacy

                if (displayLogs.isEmpty && _controller.searchNotifier.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada hasil untuk '${_controller.searchNotifier.value}'",
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _controller.refreshData,
                  color: const Color(0xFFA8D5BA),
                  child: ListView.builder(
                    itemCount: displayLogs.length,
                    itemBuilder: (context, index) {
                      final log = displayLogs[index];
                      final isOwner = log.authorId == _controller.userId;
                      
                      // Find actual index in controller's list for editing
                      final actualIndex = _controller.logsNotifier.value.indexOf(log);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LogDetailPage(
                                  log: log,
                                  currentRole: widget.role,
                                  currentUserId: _controller.userId,
                                ),
                              ),
                            );
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(log.category),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                log.isPublic ? Icons.public : Icons.lock,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(log.title)),
                              const SizedBox(width: 8),
                              // Sync Status Icon
                              Icon(
                                log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                size: 16,
                                color: log.isSynced ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Category Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.category.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormatter.formatRelative(log.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isOwner  // Hanya owner bisa edit/delete
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showEditLogDialog(actualIndex, log),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await _controller
                                            .removeLogByObject(log);
                                        // Trigger refresh
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}