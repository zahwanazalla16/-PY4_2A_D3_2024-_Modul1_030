// test/login_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';

void main() {
  var actual, expected;

  group('Module 2 - LoginController', () {
    late LoginController controller;

    setUp(() {
      // (1) setup (arrange, build)
      controller = LoginController();
    });

    // ===================== TC01 =====================
    test('TC01 - login should succeed and reset failedAttempts', () {
      // (2) exercise (act, operate)
      actual = controller.login("admin", "123");
      var actualAttempts = controller.failedAttempts;

      // expected
      expected = true;
      var expectedAttempts = 0;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
      expect(actualAttempts, expectedAttempts,
          reason:
              'Expected failedAttempts $expectedAttempts but got $actualAttempts');
    });

    // ===================== TC02 =====================
    test('TC02 - account should lock after 3 failed login attempts', () {
      // (2) exercise (act, operate)
      controller.login("admin", "wrong");
      controller.login("admin", "wrong");
      controller.login("admin", "wrong");

      actual = controller.failedAttempts;
      var actualLock = controller.isLocked;

      // expected
      expected = 3;
      var expectedLock = true;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
      expect(actualLock, expectedLock,
          reason: 'Expected $expectedLock but got $actualLock');
    });

    // ===================== TC03 =====================
    test('TC03 - resetLock should reset failedAttempts and unlock account', () {
      // (1) setup tambahan
      controller.login("admin", "wrong");
      controller.login("admin", "wrong");
      controller.login("admin", "wrong"); // terkunci

      // (2) exercise (act, operate)
      controller.resetLock();

      actual = controller.failedAttempts;
      var actualLock = controller.isLocked;

      // expected
      expected = 0;
      var expectedLock = false;

      // (3) verify (assert, check)
      expect(actual, expected,
          reason: 'Expected $expected but got $actual');
      expect(actualLock, expectedLock,
          reason: 'Expected $expectedLock but got $actualLock');
    });
  });
}