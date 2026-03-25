import 'package:flutter/material.dart';
import 'package:hive/hive.dart' as hive_box;
import 'package:mongo_dart/mongo_dart.dart';
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

  List<LogModel> _visibleLogsFromHive() {
    return hiveBox.values.where((log) => !log.pendingDelete).toList();
  }

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
        final generatedId = ObjectId().oid;
        final logWithId = log.copyWith(id: generatedId);
        await MongoService().insertLog(logWithId);

        final syncedLog = logWithId.copyWith(isSynced: true, pendingDelete: false);
        await hiveBox.putAt(hiveIndex, syncedLog);
      } else {
        // Update ke Cloud
        await MongoService().updateLog(log);

        final syncedLog = log.copyWith(isSynced: true, pendingDelete: false);
        await hiveBox.putAt(hiveIndex, syncedLog);
      }

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
    for (int i = allLogs.length - 1; i >= 0; i--) {
      final currentLog = allLogs[i];

      if (currentLog.pendingDelete) {
        try {
          if (currentLog.id != null) {
            await MongoService().deleteLog(currentLog.id!);
          }

          await hiveBox.deleteAt(i);

          await LogHelper.writeLog(
            "SYNC DELETE: '${currentLog.title}' berhasil dihapus dari Cloud",
            source: "SyncManager",
            level: 2,
          );
        } catch (e) {
          await LogHelper.writeLog(
            "SYNC DELETE PENDING: '${currentLog.title}' belum bisa dihapus - $e",
            source: "SyncManager",
            level: 3,
          );
        }
        continue;
      }

      if (!currentLog.isSynced) {
        await syncLog(i, currentLog);
      }
    }
    // Update UI
    logsNotifier.value = _visibleLogsFromHive();
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
      logsNotifier.value = _visibleLogsFromHive();

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
      logsNotifier.value = _visibleLogsFromHive();

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
      logsNotifier.value = _visibleLogsFromHive();

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
      logsNotifier.value = _visibleLogsFromHive();

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
    if (targetLog.id == null) {
      // Log lokal yang belum pernah sync, cukup hapus dari Hive
      await hiveBox.deleteAt(index);
      logsNotifier.value = _visibleLogsFromHive();
      return;
    }

    try {
      await MongoService().deleteLog(targetLog.id!);
      await hiveBox.deleteAt(index);
      logsNotifier.value = _visibleLogsFromHive();

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      final pendingDeleteLog = targetLog.copyWith(isSynced: false, pendingDelete: true);
      await hiveBox.putAt(index, pendingDeleteLog);
      logsNotifier.value = _visibleLogsFromHive();

      await LogHelper.writeLog(
        "OFFLINE DELETE: '${targetLog.title}' disimpan sementara untuk sinkronisasi - $e",
        source: "log_controller.dart",
        level: 3,
      );
    }
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
      final index = hiveBox.values.toList().indexWhere(
        (e) =>
            (log.id != null && e.id == log.id) ||
            (log.id == null &&
                e.id == null &&
                e.title == log.title &&
                e.description == log.description &&
                e.date == log.date &&
                e.authorId == log.authorId &&
                e.teamId == log.teamId &&
                e.category == log.category),
      );

      if (index != -1) {
        if (log.id == null) {
          await hiveBox.deleteAt(index);
        } else {
          try {
            await MongoService().deleteLog(log.id!);
            await hiveBox.deleteAt(index);
          } catch (e) {
            final pendingDeleteLog = log.copyWith(isSynced: false, pendingDelete: true);
            await hiveBox.putAt(index, pendingDeleteLog);
          }
        }
      }

      // Update UI dari Hive
      logsNotifier.value = _visibleLogsFromHive();

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
      final localLogs = hiveBox.values.toList();
      final pendingDeleteLogs = localLogs.where((log) => log.pendingDelete).toList();
      final unsyncedLogs = localLogs.where((log) => !log.isSynced && !log.pendingDelete).toList();

      final mergedById = <String, LogModel>{};
      final mergedWithoutId = <LogModel>[];

      for (final cloudLog in cloudData) {
        if (cloudLog.id != null) {
          mergedById[cloudLog.id!] = cloudLog;
        } else {
          mergedWithoutId.add(cloudLog);
        }
      }

      for (final localLog in unsyncedLogs) {
        if (localLog.id != null) {
          mergedById[localLog.id!] = localLog;
        } else {
          mergedWithoutId.add(localLog);
        }
      }

      final visibleMerged = <LogModel>[...mergedById.values, ...mergedWithoutId];

      // Update Hive: Hapus semua, masukkan data Cloud + data yang belum sinkron
      await hiveBox.clear();
      await hiveBox.addAll(visibleMerged);
      await hiveBox.addAll(pendingDeleteLogs);

      // Update UI dengan semua data yang ada di Hive sekarang
      logsNotifier.value = visibleMerged;
      searchNotifier.value = '';

      await LogHelper.writeLog(
        "SUCCESS: Data sinkron (Cloud: ${cloudData.length}, Unsynced: ${unsyncedLogs.length}, PendingDelete: ${pendingDeleteLogs.length})",
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
      logsNotifier.value = _visibleLogsFromHive();
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
      logsNotifier.value = _visibleLogsFromHive();
    } else {
      logsNotifier.value = _visibleLogsFromHive()
          .where((log) =>
              log.title.toLowerCase().contains(query.toLowerCase()) ||
              log.description.toLowerCase().contains(query.toLowerCase()) ||
              log.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
