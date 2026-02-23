import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isButtonDisabled = false;

  int _remainingSeconds = 0;
  Timer? _timer;

  void _handleLogin() {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password wajib diisi"),
        ),
      );
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CounterView(username: user),
        ),
      );
    } else {
      if (_controller.isLocked) {
        setState(() {
          _isButtonDisabled = true;
          _remainingSeconds = 10;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terlalu banyak percobaan! Tunggu 10 detik."),
          ),
        );

        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Gagal! Periksa username dan password."),
          ),
        );
      }
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isButtonDisabled = false;
          _controller.resetLock();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Login Gatekeeper",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Masuk untuk melanjutkan ke LogBook",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passController,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden =
                              !_isPasswordHidden;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Animated Button
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      key: ValueKey(_isButtonDisabled),
                      onPressed:
                          _isButtonDisabled ? null : _handleLogin,
                      child: Text(
                        _isButtonDisabled
                            ? "Tunggu (${_remainingSeconds}s)"
                            : "Masuk",
                      ),
                    ),
                  ),
                ),

                if (_isButtonDisabled)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "Terlalu banyak percobaan gagal! Silahkan coba lagi nanti.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
