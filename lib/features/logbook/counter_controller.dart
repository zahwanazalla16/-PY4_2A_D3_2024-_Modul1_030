class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  bool isValidStep(int value) => value > 0;

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '($hour:$minute)';
  }

  void _addHistory(String text) {
    _history.insert(0, text);
    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  void setStep(int value) {
    if (isValidStep(value)) {
      _step = value;
    }
  }

  void increment() {
    _counter += _step;
    _addHistory(
      '${_currentTime()} Tambah $_step, hasil menjadi $_counter',
    );
  }

  void decrement() {
    _counter -= _step;
    _addHistory(
      '${_currentTime()} Kurang $_step, hasil menjadi $_counter',
    );
  }

  void reset() {
    _counter = 0;
    _step = 1;

    _addHistory(
      '${_currentTime()} Berhasil Reset',
    );
  }
}
