import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/features/counter/counter_view.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_platform_interface/src/enums.dart'; // untuk StorageDirectory
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

// untuk PathProviderPlatform
class MockPathProviderPlatform extends MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationCachePath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getDownloadsPath() {
    throw UnimplementedError();
  }

  @override
  Future<List<String>?> getExternalCachePaths() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getExternalStoragePath() {
    throw UnimplementedError();
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type, // Corrected type
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getLibraryPath() {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    await Hive.initFlutter();
    Hive.registerAdapter(LogModelAdapter());
    await Hive.openBox<LogModel>('logsBox');
    await Hive.openBox<dynamic>('counter_test_user_box');
  });

  tearDownAll(() async {
    await Hive.close();
  });


  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: CounterView(username: 'test_user'),
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
