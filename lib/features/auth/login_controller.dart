class LoginController {
  final Map<String, String> _users = {
    "admin": "123",
    "zahwa": "456",
    "nazala": "789",
  };

  int _failedAttempts = 0;
  bool _isLocked = false;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;

  bool login(String username, String password) {
    if (_isLocked) return false;

    if (_users.containsKey(username) &&
        _users[username] == password) {
      _failedAttempts = 0;
      return true;
    } else {
      _failedAttempts++;

      if (_failedAttempts >= 3) {
        _isLocked = true;
      }

      return false;
    }
  }

  void resetLock() {
    _failedAttempts = 0;
    _isLocked = false;
  }
}
