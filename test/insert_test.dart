import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

void main() {
  const String sourceFile = "insert_test.dart";

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  test('Test Insert Catatan ke MongoDB', () async {
    final mongoService = MongoService();

    await LogHelper.writeLog(
      "--- START INSERT TEST ---",
      source: sourceFile,
    );

    try {
      // 1. Koneksi
      await mongoService.connect();
      await LogHelper.writeLog(
        "✓ Koneksi berhasil",
        source: sourceFile,
        level: 2,
      );

      // 2. Buat data baru
      final newLog = LogModel(
        id: ObjectId(),
        title: 'Test Catatan 123',
        description: 'Ini adalah test insert dari unit test',
        date: DateTime.now(),
        category: 'perkuliahan',
        username: 'test_user',
      );

      await LogHelper.writeLog(
        "✓ Data created: ${newLog.title} (ID: ${newLog.id})",
        source: sourceFile,
        level: 2,
      );

      // 3. Insert ke MongoDB
      await mongoService.insertLog(newLog);
      await LogHelper.writeLog(
        "✓ INSERT BERHASIL ke MongoDB!",
        source: sourceFile,
        level: 2,
      );

      // 4. Verifikasi dengan read
      final allLogs = await mongoService.getLogs();
      await LogHelper.writeLog(
        "✓ Verifikasi: Total dokumen = ${allLogs.length}",
        source: sourceFile,
        level: 2,
      );

      expect(allLogs.isNotEmpty, true, reason: 'Data harus tersimpan');
      expect(allLogs.any((log) => log.title == 'Test Catatan 123'), true,
          reason: 'Data yang disisipkan harus ditemukan');

      await LogHelper.writeLog(
        "SUCCESS: Semua test passed!",
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: $e",
        source: sourceFile,
        level: 1,
      );
      fail("Test failed: $e");
    } finally {
      await mongoService.close();
      await LogHelper.writeLog("--- END TEST ---", source: sourceFile);
    }
  });
}
