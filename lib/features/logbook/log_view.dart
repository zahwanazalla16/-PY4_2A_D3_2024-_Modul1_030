import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/helpers/date_formatter.dart';
import 'package:logbook_app_001/helpers/connection_checker.dart';
import 'package:logbook_app_001/helpers/notification_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'log_controller.dart';

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  late GlobalKey<RefreshIndicatorState> _refreshIndicatorKey;
  bool _isOnline = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
    _controller = LogController(username: widget.username);
    // Memberikan kesempatan UI merender widget awal sebelum proses berat dimulai
    Future.microtask(() => _initDatabase());
    _checkConnectionStatus();
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await LogHelper.writeLog(
        "UI: Menghubungi MongoService.connect()...",
        source: "log_view.dart",
      );

      // Mengaktifkan kembali koneksi dengan timeout 15 detik (lebih longgar untuk sinyal HP)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Fetch data log dari MongoDB untuk username ini
      await LogHelper.writeLog(
        "UI: Fetching logs for '${widget.username}' dari MongoDB...",
        source: "log_view.dart",
      );

      final logsFromCloud = await MongoService().getLogsByUsername(widget.username);
      _controller.logsNotifier.value = logsFromCloud;

      // Simpan ke local storage sebagai backup
      await _controller.saveToDisk();

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat dari MongoDB ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      if (mounted) {
        NotificationHelper.showConnectionErrorNotification(context);
      }
    } finally {
      // 2. INILAH FINALLY: Apapun yang terjadi (Sukses/Gagal/Data Kosong), loading harus mati
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check status koneksi internet
  Future<void> _checkConnectionStatus() async {
    final isOnline = await ConnectionChecker().hasConnection();
    if (mounted) {
      setState(() => _isOnline = isOnline);
    }
    
    // Listen untuk perubahan status koneksi
    if (mounted) {
      ConnectionChecker().connectionStatusStream.listen((isOnline) {
        if (mounted) {
          setState(() => _isOnline = isOnline);
        }
      });
    }
  }

  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _contentController =
      TextEditingController();
  
  // Categories
  final List<String> categories = ['perkuliahan', 'pekerjaan', 'private'];
  String selectedCategory = 'perkuliahan';

  // Format date untuk tampilan
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

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

  // ================= FETCH FROM MONGODB =================
  /// Fetch logs filtered by current username from MongoDB Atlas
  Future<List<LogModel>> _fetchLogs() async {
    try {
      await LogHelper.writeLog(
        "Fetching logs for user '${_controller.username}' from MongoDB...",
        source: "log_view.dart",
        level: 0,
      );
      final logs = await MongoService().getLogsByUsername(_controller.username);
      return logs;
    } catch (e) {
      await LogHelper.writeLog(
        "Error fetching logs: $e",
        source: "log_view.dart",
        level: 2,
      );
      rethrow;
    }
  }

  /// Filter logs based on search keyword
  List<LogModel> _getFilteredLogs(List<LogModel> allLogs) {
    final searchKeyword = _controller.searchNotifier.value.toLowerCase();
    if (searchKeyword.isEmpty) {
      return allLogs;
    }
    return allLogs
        .where((log) =>
            log.title.toLowerCase().contains(searchKeyword) ||
            log.description.toLowerCase().contains(searchKeyword) ||
            log.category.toLowerCase().contains(searchKeyword))
        .toList();
  }

  // Get warna pastel berdasarkan kategori
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'perkuliahan':
        return const Color(0xFFFFE5B4); // Kuning pastel
      case 'pekerjaan':
        return const Color(0xFFFFB3D9); // Pink pastel
      case 'private':
        return const Color(0xFFB3D9FF); // Biru pastel
      default:
        return const Color(0xFFFFE5B4);
    }
  }

  // ================= ADD =================
  void _showAddLogDialog() {
    selectedCategory = 'perkuliahan';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(hintText: "Judul"),
              ),
              TextField(
                controller: _contentController,
                decoration:
                    const InputDecoration(hintText: "Deskripsi"),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.addLog(
                  _titleController.text,
                  _contentController.text,
                  selectedCategory,
                );

                _titleController.clear();
                _contentController.clear();

                Navigator.pop(context);
                
                // 🔄 Trigger UI refresh via refreshTrigger
                Future.delayed(const Duration(milliseconds: 500), () {
                  setState(() {});
                });
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EDIT =================
  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController),
              TextField(controller: _contentController),
              const SizedBox(height: 16),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                // Find the actual index in logsNotifier
                final actualIndex = _controller.logsNotifier.value
                    .indexWhere((item) => item.id == log.id);
                if (actualIndex >= 0) {
                  _controller.updateLog(
                    actualIndex,
                    _titleController.text,
                    _contentController.text,
                    selectedCategory,
                  );
                }

                _titleController.clear();
                _contentController.clear();

                Navigator.pop(context);
                
                // 🔄 Trigger UI refresh via refreshTrigger
                Future.delayed(const Duration(milliseconds: 500), () {
                  setState(() {});
                });
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook App: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 SEARCH BAR
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

          // 📵 OFFLINE NOTIFICATION - Below Search Bar
          if (!_isOnline)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Mode Offline - Data tidak tersedia',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ FUTURE-BASED LIST OR OFFLINE MESSAGE
          Expanded(
            child: _isOnline
                ? ValueListenableBuilder<bool>(
                    valueListenable: _controller.refreshTrigger,
                    builder: (context, refreshValue, child) {
                      return FutureBuilder<List<LogModel>>(
                        future: _fetchLogs(),
                        builder: (context, snapshot) {
                          // 1. Loading State
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFA8D5BA),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Memuat catatan dari MongoDB Atlas...",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }

                          // 2. Error State
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Error: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    child: const Text("Coba Lagi"),
                                  ),
                                ],
                              ),
                            );
                          }

                          // 3. No Data State
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off,
                                      size: 64, color: Colors.grey),
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

                          // 4. Success State - Display List
                          final allLogs = snapshot.data ?? [];
                          final displayLogs =
                              _getFilteredLogs(allLogs); // Filter based on search

                          if (displayLogs.isEmpty && _controller.searchNotifier.value.isNotEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 64, color: Colors.grey),
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
                            onRefresh: _fetchLogs,
                            color: const Color(0xFFA8D5BA),
                            child: ListView.builder(
                              itemCount: displayLogs.length,
                              itemBuilder: (context, index) {
                                final log = displayLogs[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(log.category),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.cloud,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    title: Text(log.title),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormatter.formatRelative(log.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _showEditLogDialog(0, log),
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
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Data tidak tersedia saat offline",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Hubungkan ke internet untuk melihat catatan",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
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