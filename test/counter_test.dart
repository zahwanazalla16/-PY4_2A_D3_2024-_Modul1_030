// test/counter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/counter/counter_controller.dart';

void main() {
  var actual, expected;

  group('Module 1 - CounterController (with storage & step)', () {
    late CounterController controller;
    const username = "admin";

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({});
      controller = CounterController();
      await controller.loadData(username);
    });

    // ===================== TC01 =====================
    test('TC01 - initial value should be 0', () {
      // (2) exercise
      actual = controller.value;
      expected = 0;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC02 =====================
    test('TC02 - setStep should change step value', () {
      // (2) exercise
      controller.setStep(5, username);
      actual = controller.step;
      expected = 5;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC03 =====================
    test('TC03 - setStep should ignore negative value', () {
      // (1) setup tambahan
      controller.setStep(3, username);

      // (2) exercise
      controller.setStep(-1, username);
      actual = controller.step;
      expected = 3;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC04 =====================
    test('TC04 - increment should increase counter', () {
      // (1) setup tambahan
      controller.setStep(2, username);

      // (2) exercise
      controller.increment(username);
      actual = controller.value;
      expected = 2;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC05 =====================
    test('TC05 - increment should follow step value', () {
      // (1) setup tambahan
      controller.setStep(3, username);

      // (2) exercise
      controller.increment(username);
      actual = controller.value;
      expected = 3;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC06 =====================
    test('TC06 - decrement should decrease counter normally', () {
      // (1) setup tambahan
      controller.setStep(2, username);
      controller.increment(username); // 2
      controller.increment(username); // 4

      // (2) exercise
      controller.decrement(username);
      actual = controller.value;
      expected = 2;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC07 =====================
test('TC07 - decrement allows negative value', () {
  // (1) setup
  controller.setStep(5, username);

  // (2) exercise
  controller.decrement(username);
  actual = controller.value;
  expected = -5;

  // (3) verify
  expect(actual, expected, reason: 'Expected $expected but got $actual');
});

    // ===================== TC08 =====================
    test('TC08 - reset should set counter to zero', () {
      // (1) setup tambahan
      controller.increment(username);

      // (2) exercise
      controller.reset(username);
      actual = controller.value;
      expected = 0;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== TC09 =====================
    test('TC09 - history should record actions', () {
      // (1) setup tambahan
      controller.setStep(1, username);

      // (2) exercise
      controller.increment(username);
      var actual1 = controller.history.isNotEmpty;
      var expected1 = true;
      var actual2 = controller.history.first.contains("menambah");
      var expected2 = true;

      // (3) verify
      expect(actual1, expected1,
          reason: 'Expected $expected1 but got $actual1');
      expect(actual2, expected2,
          reason: 'Expected $expected2 but got $actual2');
    });

    // ===================== TC10 =====================
    test('TC10 - history should not exceed 5 items', () {
      // (1) setup tambahan
      controller.setStep(1, username);

      // (2) exercise
      for (int i = 0; i < 6; i++) {
        controller.increment(username);
      }
      actual = controller.history.length;
      expected = 5;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ===================== (Tambahan dari modul) =====================
    test('counter should persist using SharedPreferences', () async {
      // (1) setup
      controller.setStep(3, username);
      controller.increment(username);

      final newController = CounterController();

      // (2) exercise
      await newController.loadData(username);
      actual = newController.value;
      expected = 3;

      // (3) verify
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });
  });
}