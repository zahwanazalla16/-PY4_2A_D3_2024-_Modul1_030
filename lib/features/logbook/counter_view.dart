import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({
    super.key,
    required this.username,
  });

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _controller.loadData(widget.username);
    setState(() {
      _isLoading = false;
    });
  }

  Color _getHistoryBackground(String text) {
    if (text.contains('menambahkan')) {
      return Colors.green.shade100;
    }
    if (text.contains('mengurangi')) {
      return Colors.red.shade100;
    }
    if (text.contains('mereset')) {
      return Colors.grey.shade300;
    }
    return Colors.grey.shade200;
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reset'),
        content: const Text(
          'Apakah kamu yakin ingin mereset counter?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _controller.reset(widget.username);
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _logoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginView(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sectionStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('LogBook: ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logoutConfirmation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${_getGreeting()}, ${widget.username}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Counter
            Center(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Hitungan',
                        style: sectionStyle,
                      ),
                      const SizedBox(height: 12),

                      // Animated counter
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                        child: Text(
                          '${_controller.value}',
                          key: ValueKey(_controller.value),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            const SizedBox(height: 24),

            Text('Step: ${_controller.step}', style: sectionStyle),

            Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: _controller.step.toDouble(),
              label: _controller.step.toString(),
              onChanged: (value) {
                setState(() {
                  _controller.setStep(value.toInt(), widget.username);
                });
              },
            ),

            const SizedBox(height: 16),
            const Text('Riwayat Aktivitas', style: sectionStyle),
            const SizedBox(height: 8),

            Expanded(
              child: _controller.history.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada aktivitas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _controller.history.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final text = _controller.history[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _getHistoryBackground(text),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 30,
            child: FloatingActionButton(
              heroTag: 'decrement',
              onPressed: () {
                setState(() {
                  _controller.decrement(widget.username);
                });
              },
              child: const Icon(Icons.remove),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 30,
            child: FloatingActionButton(
              heroTag: 'increment',
              onPressed: () {
                setState(() {
                  _controller.increment(widget.username);
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                heroTag: 'reset',
                backgroundColor: Colors.grey,
                onPressed: _showResetConfirmation,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return "Selamat Pagi";
    } else if (hour >= 12 && hour < 18) {
      return "Selamat Siang";
    } else if (hour >= 18 && hour < 22) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }
}
