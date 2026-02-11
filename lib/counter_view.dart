import 'package:flutter/material.dart';
import '../counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  Color _getHistoryBackground(String text) {
    if (text.contains('Tambah')) return const Color.fromARGB(255, 186, 225, 188);
    if (text.contains('Kurang')) return const Color.fromARGB(255, 231, 161, 150);
    if (text.contains('Reset')) return const Color.fromARGB(255, 194, 193, 196);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            onPressed: () {
              Navigator.pop(context); 

              setState(() {
                _controller.reset();
            });
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
          'LogBook: SRP Version',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('Total Hitungan:', style: sectionStyle),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_controller.value}',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),

                const SizedBox(height: 28),

                Text('Step: ${_controller.step}', style: sectionStyle),
                Slider(
                  min: 1,
                  max: 10,
                  divisions: 9,
                  value: _controller.step.toDouble(),
                  label: _controller.step.toString(),
                  onChanged: (value) {
                    setState(() {
                      _controller.setStep(value.toInt());
                    });
                  },
                ),

                const SizedBox(height: 20),

                const Text('Riwayat Aktivitas:', style: sectionStyle),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.separated(
                    itemCount: _controller.history.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final text = _controller.history[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getHistoryBackground(text),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tombol Aksi
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
                backgroundColor: Colors.grey,
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
