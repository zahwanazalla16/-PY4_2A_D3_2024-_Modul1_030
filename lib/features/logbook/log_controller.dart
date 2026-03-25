import 'package:flutter/material.dart';
import 'package:hive/hive.dart' as hive_box;
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/services/access_policy.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  final String username;
  final String userId;
  final String userRole;
  final String teamId;
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<String> searchNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> refreshTrigger = ValueNotifier<bool>(false);

  late hive_box.Box<LogModel> hiveBox;
  late Future<void> _initFuture;

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  // Constructor
  LogController({
    required this.username,
    required this.userId,
    required this.userRole,
    required this.teamId,
  }) {
    _initFuture = init();
  }

  Future<void> init() async {
    hiveBox = hive_box.Hive.box<LogModel>('logsBox');
    await loadFromDisk();
  }

  // Pastikan init selesai sebelum operation
  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  // Hybrid Sync
  Future<void> syncLog(int hiveIndex, LogModel log) async {
    try {
      if (log.id == null) {
        // Insert Baru ke Cloud
        await MongoService().insertLog(log);
      } else {
        // Update ke Cloud
        await MongoService().updateLog(log);
      }

      // Jika berhasil, update status di Hive
      final syncedLog = log.copyWith(isSynced: true);
      await hiveBox.putAt(hiveIndex, syncedLog);

      await LogHelper.writeLog(
        "Sync Success: '${log.title}'",
        source: "SyncManager",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "Offline Mode: Data '${log.title}' saved locally",
        level: 3,
      );
    }
  }

  Future<void> syncAllUnsyncedLogs() async {
    final allLogs = hiveBox.values.toList();
    for (int i = 0; i < allLogs.length; i++) {
      if (!allLogs[i].isSynced) {
        await syncLog(i, allLogs[i]);
      }
    }
    // Update UI
    logsNotifier.value = hiveBox.values.toList();
  }

  // ADD LOG
  Future<void> addLog(String title, String desc,
      [String category = 'mechanical']) async {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category,
      username: username,
      authorId: userId,
      teamId: teamId,
      isSynced: false,
    );

    try {
      // Simpan ke Hive (local)
      final index = await hiveBox.add(newLog);

      await LogHelper.writeLog(
        "SUCCESS: Data '${newLog.title}' tersimpan di Hive",
        source: "log_controller.dart",
        level: 2,
      );

      // Coba Sync ke cloud
      await syncLog(index, newLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Hive save gagal - $e",
        source: "log_controller.dart",
        level: 3,
      );
    } finally {
      // Update UI dari Hive
      logsNotifier.value = hiveBox.values.toList();

      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    }
  }

  // UPDATE LOG
  Future<void> updateLog(int index, String newTitle, String newDesc,
      [String category = 'mechanical']) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      category: category,
      username: username,
      authorId: userId,
      teamId: teamId,
      isSynced: false,
    );

    try {
      // Update Local Hive
      await hiveBox.putAt(index, updatedLog);

      // Coba Sync ke Cloud
      await syncLog(index, updatedLog);

      // Update UI dari Hive
      logsNotifier.value = hiveBox.values.toList();

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
    
  }

  // ADD LOG DIRECT (dari LogEditorPage)
  Future<void> addLogDirect(LogModel log) async {
    try {
      // Simpan ke Hive (local)
      final localLog = log.copyWith(isSynced: false);
      final index = await hiveBox.add(localLog);

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' tersimpan di Hive",
        source: "log_controller.dart",
        level: 2,
      );

      // Coba Sync ke cloud
      await syncLog(index, localLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Hive save gagal - $e",
        source: "log_controller.dart",
        level: 3,
      );
    } finally {
      // Update UI dari Hive
      logsNotifier.value = hiveBox.values.toList();

      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    }
  }

  // UPDATE LOG DIRECT (dari LogEditorPage)
  Future<void> updateLogDirect(int index, LogModel updatedLog) async {
    try {
      // Update Local Hive
      final localLog = updatedLog.copyWith(isSynced: false);
      await hiveBox.putAt(index, localLog);

      // Update ke Cloud
      await syncLog(index, localLog);

      // Update UI dari Hive
      logsNotifier.value = hiveBox.values.toList();

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${updatedLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // DELETE LOG
  Future<void> removeLog(int index) async {
  final currentLogs = List<LogModel>.from(logsNotifier.value);

  if (index < 0 || index >= currentLogs.length) {
    await LogHelper.writeLog(
      "ERROR: Index not found - $index",
      source: "log_controller.dart",
      level: 1,
    );
    return;
  }

  final targetLog = currentLogs[index];

  // SECURITY VALIDATION (RBAC)
  if (!AccessControlService.canPerform(
    userRole,
    'delete',
    isOwner: targetLog.authorId == userId,
  )) {
    await LogHelper.writeLog(
      "SECURITY BREACH: Unauthorized delete attempt by $userId",
      source: "log_controller.dart",
      level: 1,
    );
    return;
  }

  try {
    // Delete Local Hive
    await hiveBox.deleteAt(index);

    // Delete dari Cloud jika sudah punya ID
    if (targetLog.id != null) {
      await MongoService().deleteLog(targetLog.id!);
    }

    // Update UI dari Hive
    logsNotifier.value = hiveBox.values.toList();

    await LogHelper.writeLog(
      "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
      source: "log_controller.dart",
      level: 2,
    );
  } catch (e) {
    await LogHelper.writeLog(
      "ERROR: Gagal sinkronisasi Hapus - $e",
      source: "log_controller.dart",
      level: 1,
    );
  }
}

  // DELETE BY OBJECT
  Future<void> removeLogByObject(LogModel log) async {
    try {
      final index = hiveBox.values.toList().indexWhere((e) => e.id == log.id);

      if (index != -1) {
        await hiveBox.deleteAt(index);
      }

      if (log.id != null) {
        await MongoService().deleteLog(log.id!);
      }

      // Update UI dari Hive
      logsNotifier.value = hiveBox.values.toList();

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${log.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // LOAD DATA
  Future<void> loadFromDisk() async {
    try {
      // Ambil data dari Cloud
      final cloudData = await MongoService().getLogs();
      
      // Ambil data lokal yang belum sinkron
      final unsyncedLogs = hiveBox.values.where((log) => !log.isSynced).toList();

      // Update Hive: Hapus semua, masukkan data Cloud + data yang belum sinkron
      await hiveBox.clear();
      await hiveBox.addAll(cloudData); // Cloud data is already synced
      await hiveBox.addAll(unsyncedLogs);

      // Update UI dengan semua data yang ada di Hive sekarang
      logsNotifier.value = hiveBox.values.toList();
      searchNotifier.value = '';

      await LogHelper.writeLog(
        "SUCCESS: Data sinkron (Cloud: ${cloudData.length}, Unsynced: ${unsyncedLogs.length})",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud tidak tersedia, memuat dari Hive - $e",
        source: "log_controller.dart",
        level: 3,
      );

      // Jika gagal (offline), tampilkan apa adanya yang ada di Hive
      logsNotifier.value = hiveBox.values.toList();
    }
  }

  // REFRESH DATA
  Future<void> refreshData() async {
    try {
      await LogHelper.writeLog(
        "INFO: Melakukan refresh data...",
        source: "log_controller.dart",
        level: 3,
      );

      await loadFromDisk();

      refreshTrigger.value = !refreshTrigger.value;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Refresh gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // SEARCH LOG
  void searchLog(String query) {
    searchNotifier.value = query; // Update search notifier
    
    if (query.isEmpty) {
      logsNotifier.value = hiveBox.values.toList();
    } else {
      logsNotifier.value = hiveBox.values
          .where((log) =>
              log.title.toLowerCase().contains(query.toLowerCase()) ||
              log.description.toLowerCase().contains(query.toLowerCase()) ||
              log.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
