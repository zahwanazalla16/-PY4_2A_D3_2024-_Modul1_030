import 'dart:convert'; // Wajib ditambahkan untuk jsonEncode & jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<String> searchNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> refreshTrigger = ValueNotifier<bool>(false);

  // Kunci unik untuk penyimpanan lokal di Shared Preferences
  static const String _storageKey = 'user_logs_data';

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  // --- BARU: KONSTRUKTOR ---
  // Saat Controller dibuat, ia otomatis mencoba mengambil data lama
  LogController({required this.username}) {
    loadFromDisk();
  }

  // 1. Menambah data ke Cloud
  Future<void> addLog(String title, String desc, [String category = 'perkuliahan']) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now(),
      category: category,
      username: username,
    );

    try {
      // 2. Kirim ke MongoDB Atlas
      await MongoService().insertLog(newLog);

      await LogHelper.writeLog(
        "SUCCESS: Data '${newLog.title}' tersimpan di Cloud dan UI",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      // Jika cloud gagal, simpan ke local dulu
      await LogHelper.writeLog(
        "WARNING: Cloud gagal, menyimpan ke local - $e",
        source: "log_controller.dart",
        level: 3,
      );
      await saveToDisk();
    } finally {
      // 3. SELALU Update UI Lokal, apapun hasilnya
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;

      // Simpan ke local storage agar data tidak hilang
      await saveToDisk();

      // Trigger refresh untuk update UI
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    }
  }

  // 2. Memperbarui data di Cloud (HOTS: Sinkronisasi Terjamin)
  Future<void> updateLog(int index, String newTitle, String newDesc, [String category = 'perkuliahan']) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama agar MongoDB mengenali dokumen ini
      title: newTitle,
      description: newDesc,
      date: DateTime.now(),
      category: category,
      username: username,
    );

    try {
      // 1. Jalankan update di MongoService (Tunggu konfirmasi Cloud)
      await MongoService().updateLog(updatedLog);

      // 2. Jika sukses, baru perbarui state lokal
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );

      // Trigger refresh untuk update UI
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshTrigger.value = !refreshTrigger.value;
      });
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Data di UI tidak berubah jika proses di Cloud gagal
    }
  }

  // 3. Menghapus data dari Cloud (HOTS: Sinkronisasi Terjamin)
  Future<void> removeLog(int index) async {
    // Jika index adalah dari filtered list, kita perlu hitung ulang index dari original list
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

    try {
      if (targetLog.id == null) {
        throw Exception(
          "ID Log tidak ditemukan, tidak bisa menghapus di Cloud.",
        );
      }

      // 1. Hapus data di MongoDB Atlas (Tunggu konfirmasi Cloud)
      await MongoService().deleteLog(targetLog.id!);

      // 2. Jika sukses, baru hapus dari state lokal
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

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

  // Alternative: Delete by LogModel object (lebih aman untuk filtered list)
  Future<void> removeLogByObject(LogModel log) async {
    try {
      if (log.id == null) {
        throw Exception(
          "ID Log tidak ditemukan, tidak bisa menghapus di Cloud.",
        );
      }

      // 1. Hapus data di MongoDB Atlas (Tunggu konfirmasi Cloud)
      await MongoService().deleteLog(log.id!);

      // 2. Jika sukses, baru hapus dari state lokal
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeWhere((item) => item.id == log.id);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${log.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );

      // Trigger refresh untuk update UI
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

  // --- BARU: FUNGSI PERSISTENCE (SINKRONISASI JSON) ---

  // Fungsi untuk menyimpan seluruh List ke penyimpanan lokal
  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Mengubah List of Object -> List of Map -> String JSON
      final String encodedData = jsonEncode(
        logsNotifier.value.map((log) => log.toMap()).toList(),
      );
      await prefs.setString(_storageKey, encodedData);
      
      await LogHelper.writeLog(
        "INFO: Data tersimpan ke local storage (${logsNotifier.value.length} items)",
        source: "log_controller.dart",
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal menyimpan ke local storage - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // Ganti pemanggilan SharedPreferences menjadi MongoService
  Future<void> loadFromDisk() async {
    try {
      // Mencoba ambil dari Cloud terlebih dahulu
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
      searchNotifier.value = ''; // Reset search
      
      await LogHelper.writeLog(
        "SUCCESS: Data dimuat dari MongoDB Cloud (${cloudData.length} items)",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      // Jika cloud gagal, coba load dari local storage
      await LogHelper.writeLog(
        "WARNING: Cloud tidak tersedia, memuat dari local storage - $e",
        source: "log_controller.dart",
        level: 3,
      );
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString(_storageKey);
        
        if (savedData != null && savedData.isNotEmpty) {
          final List<dynamic> decodedData = jsonDecode(savedData);
          final localLogs = decodedData
              .map((log) => LogModel.fromMap(log as Map<String, dynamic>))
              .toList();
          logsNotifier.value = localLogs;
          
          await LogHelper.writeLog(
            "SUCCESS: Data dimuat dari local storage (${localLogs.length} items)",
            source: "log_controller.dart",
            level: 2,
          );
        } else {
          logsNotifier.value = [];
          
          await LogHelper.writeLog(
            "INFO: Tidak ada data di local storage",
            source: "log_controller.dart",
            level: 3,
          );
        }
      } catch (localError) {
        logsNotifier.value = [];
        
        await LogHelper.writeLog(
          "ERROR: Gagal load local storage - $localError",
          source: "log_controller.dart",
          level: 1,
        );
      }
      
      searchNotifier.value = '';
    }
  }

  // Fungsi untuk mencari log berdasarkan keyword
  Future<void> searchLog(String keyword) async {
    try {
      searchNotifier.value = keyword;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Pencarian gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // Fungsi helper untuk get filtered logs
  List<LogModel> getFilteredLogs() {
    final keyword = searchNotifier.value.toLowerCase();
    if (keyword.isEmpty) {
      return logsNotifier.value;
    }
    return logsNotifier.value
        .where((log) =>
            log.title.toLowerCase().contains(keyword) ||
            log.description.toLowerCase().contains(keyword))
        .toList();
  }

  /// Refresh data dari Cloud
  Future<void> refreshData() async {
    try {
      await LogHelper.writeLog(
        "INFO: Melakukan refresh data dari MongoDB...",
        source: "log_controller.dart",
        level: 3,
      );

      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
      searchNotifier.value = ''; // Reset search

      await LogHelper.writeLog(
        "SUCCESS: Refresh data selesai (${cloudData.length} items)",
        source: "log_controller.dart",
        level: 2,
      );

      // Trigger refresh untuk UI update
      refreshTrigger.value = !refreshTrigger.value;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Refresh gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }
}
