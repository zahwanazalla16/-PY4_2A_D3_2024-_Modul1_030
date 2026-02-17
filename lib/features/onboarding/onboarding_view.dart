import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  void _nextStep() {
    setState(() {
      step++;
    });

    if (step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ),
      );
    }
  }

  String _getTitle() {
    if (step == 1) return "Selamat Datang di LogBook";
    if (step == 2) return "Catat Aktivitasmu";
    if (step == 3) return "Pantau Perkembangan";
    return "";
  }

  String _getDescription() {
    if (step == 1) return "Aplikasi sederhana untuk mencatat aktivitas harian.";
    if (step == 2) return "Gunakan fitur counter untuk melacak progres.";
    if (step == 3) return "Lihat riwayat aktivitasmu dengan rapi.";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _getDescription(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _nextStep,
              child: Text(step == 3 ? "Mulai" : "Next"),
            ),
          ],
        ),
      ),
    );
  }
}
