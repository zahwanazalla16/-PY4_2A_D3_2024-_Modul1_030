import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
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
  bool _isOnline = false;
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

    _initializeConnectionStatus();
    
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

  Future<void> _initializeConnectionStatus() async {
    final hasConnection = await ConnectionChecker().hasConnection();
    if (mounted) {
      setState(() => _isOnline = hasConnection);
    }
  }

  Future<void> _initDatabase() async {
    try {
      //Load Local Data First (Mencegah Layar Putih)
      await LogHelper.writeLog("UI: Loading data lokal dari Hive...", source: "log_view.dart");
      await _controller.init(); // memanggil loadFromDisk() internal
      
      if (mounted) setState(() {}); // Refresh UI dengan data Hive yang ada

      // Backgrount connect & sync 
      _attemptCloudConnection();

    } catch (e) {
      await LogHelper.writeLog("UI: Error Init - $e", source: "log_view.dart", level: 1);
    }
  }

  Future<void> _attemptCloudConnection() async {
    try {
      await LogHelper.writeLog("UI: Mencoba koneksi background ke Cloud...", source: "log_view.dart");
      
      // Kurangi timeout ke 5-7 detik saja
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

  // Filter logs based on privacy & search keyword
  List<LogModel> _getFilteredLogs(List<LogModel> allLogs) {
    final searchKeyword = _controller.searchNotifier.value.toLowerCase();
    final currentUserId = _controller.userId;
    
    // Privacy filter: Tampilkan hanya log yang dibuat oleh user atau yang bersifat public
    final privacyFiltered = allLogs.where((log) {
      return log.authorId == currentUserId || log.isPublic == true;
    }).toList();
    
    // Search filter
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

  // ADD
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

  // EDIT
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

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Logbook App",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "${widget.username} (${widget.role})",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
              _controller.refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, logs, child) {
                final displayLogs = _getFilteredLogs(logs);

                if (logs.isEmpty || (displayLogs.isEmpty && _controller.searchNotifier.value.isEmpty)) {
                  return SizedBox.expand(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _EmptyStateIllustration(),
                          const SizedBox(height: 8),
                          const Text(
                            "Belum ada catatan di Logbook.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Coba buat catatan pertama Anda.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _showAddLogDialog,
                            child: const Text(" + Buat Catatan"),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (displayLogs.isEmpty && _controller.searchNotifier.value.isNotEmpty) {
                  return SizedBox.expand(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _EmptyStateIllustration(),
                          const SizedBox(height: 8),
                          Text(
                            "Tidak ada hasil untuk '${_controller.searchNotifier.value}'",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _controller.refreshData,
                  color: const Color(0xFFA8D5BA),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: displayLogs.length,
                    itemBuilder: (context, index) {
                      final log = displayLogs[index];
                      final isOwner = log.authorId == _controller.userId;
                      final actualIndex = _controller.logsNotifier.value.indexOf(log);

                      return Dismissible(
                        key: ValueKey(log.id ?? log.hashCode),
                        direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
                        confirmDismiss: (direction) async {
                          if (!isOwner) return false;
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi Hapus'),
                                  content: const Text('Yakin ingin menghapus catatan ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                        },
                        onDismissed: (direction) async {
                          await _controller.removeLogByObject(log);
                          setState(() {});
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minLeadingWidth: 0,
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
                                  title: Text(
                                    log.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getCategoryColor(log.category),
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              log.category.toUpperCase(),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              DateFormatter.formatRelative(log.date),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: isOwner
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                              iconSize: 18,
                                              onPressed: () => _showEditLogDialog(actualIndex, log),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                              iconSize: 18,
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Konfirmasi Hapus'),
                                                    content: const Text('Yakin ingin menghapus catatan ini?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text('Batal'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await _controller.removeLogByObject(log);
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Icon(
                                  log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: log.isSynced ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
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

class _EmptyStateIllustration extends StatefulWidget {
  const _EmptyStateIllustration();

  @override
  State<_EmptyStateIllustration> createState() => _EmptyStateIllustrationState();
}

class _EmptyStateIllustrationState extends State<_EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final bob = math.sin(t * math.pi * 2);

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.92 + (t * 0.08),
                child: Container(
                  width: 186,
                  height: 186,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA8D5BA).withValues(alpha: 0.30),
                        const Color(0xFFA8D5BA).withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, bob * 8),
                child: SvgPicture.asset(
                  'assets/images/empty_state.svg',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 36,
                right: 34,
                child: Transform.translate(
                  offset: Offset(0, bob * -4),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA8D5BA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 48,
                left: 34,
                child: Transform.translate(
                  offset: Offset(0, bob * 5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBD7FF).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
