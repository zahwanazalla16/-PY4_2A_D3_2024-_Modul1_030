import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/access_policy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  final mongoService = MongoService();
  // ================= TC01 =================
  test('TC01 - should connect and fetch logs from MongoDB', () async {
    // (1) SETUP
    await mongoService.connect();

    // (2) EXERCISE
    final logs = await mongoService.getLogs();

    // (3) VERIFY
    expect(mongoService.isConnected, true);
    expect(logs, isA<List<LogModel>>());
  });

  // ================= TC02 =================
  test('TC02 - should perform CRUD operations on MongoDB', () async {
    // (1) SETUP
    await mongoService.connect();

    final testLog = LogModel(
      id: ObjectId().toHexString(),
      title: "TEST_CRUD",
      description: "Testing CRUD",
      date: DateTime.now(),
      category: "test",
      username: "tester",
      authorId: "1",
      teamId: "team1",
      isSynced: true,
    );

    // (2) EXERCISE

    // CREATE
    await mongoService.insertLog(testLog);

    // UPDATE
    final updatedLog = testLog.copyWith(title: "UPDATED_TITLE");
    await mongoService.updateLog(updatedLog);

    // DELETE
    await mongoService.deleteLog(testLog.id!);

    // (3) VERIFY
    final logs = await mongoService.getLogs();

    expect(
      logs.any((log) => log.id == testLog.id),
      false,
      reason: "Data should be deleted",
    );
  });

  // ================= TC03 =================
  test('TC03 - should enforce RBAC and handle unauthorized delete', () {
    // (1) SETUP
    String role = "Anggota";
    bool isOwner = false;

    // (2) EXERCISE
    bool canDelete = AccessControlService.canPerform(
      role,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );

    // (3) VERIFY
    expect(canDelete, false,
        reason: "User should NOT be able to delete if not owner");
  });
}