import 'package:hive_flutter/hive_flutter.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;

  late Box<dynamic> _counterBox;
  late Future<void> initFuture;

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
  void loadData() {
    _counter = _counterBox.get('counter_value') ?? 0;
    _step = _counterBox.get('counter_step') ?? 1;

    final savedHistory = _counterBox.get('counter_history');
    if (savedHistory != null) {
      _history.clear();
      _history.addAll(List<String>.from(savedHistory));
    }
  }

  // simpan data
  void _saveData() {
    _counterBox.put('counter_value', _counter);
    _counterBox.put('counter_step', _step);
    _counterBox.put('counter_history', _history);
  }

  void _addHistory(String text) {
    _history.insert(0, text);
    if (_history.length > 5) {
      _history.removeLast();
    }
    _saveData();
  }

  void setStep(int value) {
    if (isValidStep(value)) {
      _step = value;
      _saveData();
    }
  }

  void increment(String username) {
    _counter += _step;
    _addHistory(
      '${_currentTime()} user $username menambahkan $_step menjadi $_counter',
    );
  }

  void decrement(String username) {
    _counter -= _step;
    _addHistory(
      '${_currentTime()} user $username mengurangi $_step menjadi $_counter',
    );
  }

  void reset(String username) {
    _counter = 0;
    _step = 1;
    _addHistory(
      '${_currentTime()} user $username mereset nilai counter',
    );
  }

  CounterController(String username) {
    initFuture = _init(username);
  }

  Future<void> _init(String username) async {
    _counterBox = await Hive.openBox<dynamic>('counter_${username}_box');
    loadData();
  }
}
