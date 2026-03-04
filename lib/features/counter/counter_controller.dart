import 'package:shared_preferences/shared_preferences.dart';

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

  // load data saat app dibuka 
  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt('counter_value_$username') ?? 0;
    _step = prefs.getInt('counter_step_$username') ?? 1;

    final savedHistory =
        prefs.getStringList('counter_history_$username');
    if (savedHistory != null) {
      _history.clear();
      _history.addAll(savedHistory);
    }
  }

  // simpan data
  Future<void> _saveData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('counter_value_$username', _counter);
    await prefs.setInt('counter_step_$username', _step);
    await prefs.setStringList(
        'counter_history_$username', _history);
  }

  void _addHistory(String username, String text) {
    _history.insert(0, text);
    if (_history.length > 5) {
      _history.removeLast();
    }
    _saveData(username);
  }

  void setStep(int value, String username) {
    if (isValidStep(value)) {
      _step = value;
      _saveData(username);
    }
  }

  void increment(String username) {
    _counter += _step;
    _addHistory(
      username,
      '${_currentTime()} user $username menambahkan $_step menjadi $_counter',
    );
  }

  void decrement(String username) {
    _counter -= _step;
    _addHistory(
      username,
      '${_currentTime()} user $username mengurangi $_step menjadi $_counter',
    );
  }

  void reset(String username) {
    _counter = 0;
    _step = 1;
    _addHistory(
      username,
      '${_currentTime()} user $username mereset nilai counter',
    );
  }
}
