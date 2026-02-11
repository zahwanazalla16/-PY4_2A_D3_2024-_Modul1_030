import 'package:flutter/material.dart';
import '../counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  // Warna Riwayat
  Color _getHistoryColor(String text) {
    if (text.contains('Tambah')) {
      return Colors.green;
    } else if (text.contains('Kurang')) {
      return Colors.orange;
    }
    return Colors.black;
  }

  // Validasi Reset
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reset'),
        content: const Text(
          'Apakah kamu yakin ingin mereset counter?\n'
          'Semua riwayat akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _controller.reset();
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle sectionStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: const Text(
          'LogBook - Multi Step',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Hitungan
                const Center(
                  child: Text(
                    'Total Hitungan',
                    style: sectionStyle,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_controller.value}',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),

                const SizedBox(height: 20),

                // Slider
                Text('Step: ${_controller.step}', style: sectionStyle),
                Slider(
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _controller.step.toString(),
                  value: _controller.step.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _controller.setStep(value.toInt());
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Riwayat
                const Text('Riwayat Aktivitas', style: sectionStyle),
                const SizedBox(height: 4),

                Expanded(
                  child: ListView.separated(
                    itemCount: _controller.history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final text = _controller.history[index];
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _getHistoryColor(text),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tombol
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'decrement',
              onPressed: () {
                setState(() {
                  _controller.decrement();
                });
              },
              child: const Icon(Icons.remove),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                heroTag: 'reset',
                onPressed: _showResetConfirmation,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'increment',
              onPressed: () {
                setState(() {
                  _controller.increment();
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
