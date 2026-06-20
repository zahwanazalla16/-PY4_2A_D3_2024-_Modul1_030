// test/saveToDisk_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

void main() {
  late LogController controller;

  // ================= SETUP GLOBAL =================
  setUpAll(() async {
    // fix error dotenv
    await dotenv.load(fileName: ".env");
  });

  // ================= SETUP PER TEST =================
  setUp(() async {
    // init Hive di temp folder
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);

    // fix adapter duplicate
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
    }

    // buka box
    await Hive.openBox<LogModel>('logsBox');

    // init controller dengan isTestMode=true
    controller = LogController(
      username: 'admin',
      userId: '1',
      userRole: 'admin',
      teamId: 'team1',
      isTestMode: true,
    );

    await controller.ensureInitialized();
  });

  // ================= CLEANUP =================
  tearDown(() async {
    // fix file closed error
    await Hive.close();
  });

  // ===================== TC01 =====================
  test('TC01 - should save log to Hive and update logsNotifier', () async {
    // (act)
    await controller.addLog("Test Log", "Desc");

    var actual = controller.logs.length;
    var expected = 1;

    // (assert)
    expect(actual, expected,
        reason: 'Expected $expected but got $actual');
  });

  // ===================== TC02 =====================
  test('TC02 - should update and remove log correctly', () async {
    // (arrange)
    await controller.addLog("Old Title", "Desc");

    // (act)
    await controller.updateLog(0, "New Title", "New Desc");
    await controller.removeLog(0);

    var actual = controller.logs.length;
    var expected = 0;

    // (assert)
    expect(actual, expected,
        reason: 'Expected $expected but got $actual');
  });

  // ===================== TC03 =====================
  test('TC03 - should filter pendingDelete logs and persist data', () async {
    // (arrange)
    final box = Hive.box<LogModel>('logsBox');

    final log1 = LogModel(
      title: "Visible",
      description: "Desc",
      date: DateTime.now(),
      category: "mechanical",
      username: "admin",
      authorId: "1",
      teamId: "team1",
      isSynced: false,  // Change to false so it gets merged
      pendingDelete: false,
    );

    final log2 = log1.copyWith(
      title: "Hidden",
      pendingDelete: true,
    );

    await box.add(log1);
    await box.add(log2);

    // (act)
    await controller.loadFromDisk();

    var actual = controller.logs.length;
    var expected = 1;

    // (assert)
    expect(actual, expected,
        reason: 'Expected $expected but got $actual');
  });
}