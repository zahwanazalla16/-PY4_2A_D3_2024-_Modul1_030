import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load ENV (If file missing)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env file not found. Cloud features might fail.");
    }

    try {
      cameras = await availableCameras();
    } catch (e) {
      print(e);
    }
    
    // Initialize Intl
    await initializeDateFormatting('id_ID', null);
    Intl.defaultLocale = 'id_ID';

    // Hive Initialization
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
    }

    // Open Boxes (Harus dibuka sebelum digunakan di controller)
    await Hive.openBox<LogModel>('logsBox');
    
    // Buka box counter untuk user default agar tidak error saat login
    await Hive.openBox('counter_admin_box');
    await Hive.openBox('counter_zahwa_box');
    await Hive.openBox('counter_nazala_box');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("CRITICAL ERROR DURING STARTUP: $e");
    debugPrint(stackTrace.toString());
    
    // Run minimal app to show error if possible
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("App Error: $e\n\nSilakan restart aplikasi."),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA8D5BA),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFFA8D5BA),
          foregroundColor: Colors.white,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFA8D5BA)),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          backgroundColor: Color(0xFFA8D5BA),
          foregroundColor: Colors.white,
        ),
      ),

      home: const OnboardingView(),
    );
  }
}