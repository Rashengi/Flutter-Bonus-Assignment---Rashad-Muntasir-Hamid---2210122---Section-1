// Unit tests for the form validators and the Firestore data model.
//
// The old stock counter test was removed: it asserted on a "+" button that no
// longer exists, and MyApp now needs Firebase initialised before it can be
// pumped. These tests cover the logic that matters and need no emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:summer_iub_app/models/coffee_records_model.dart';
import 'package:summer_iub_app/utility/vlaidators.dart';

void main() {
  group('CustomValidators', () {
    test('title rejects empty, short and overlong values', () {
      expect(CustomValidators.validateTitle(null), isNotNull);
      expect(CustomValidators.validateTitle(''), isNotNull);
      expect(CustomValidators.validateTitle('ab'), isNotNull);
      expect(CustomValidators.validateTitle('a' * 21), isNotNull);
      expect(CustomValidators.validateTitle('Cappuccino'), isNull);
    });

    test('amount must be a positive number', () {
      expect(CustomValidators.validateAmount(''), isNotNull);
      expect(CustomValidators.validateAmount('abc'), isNotNull);
      expect(CustomValidators.validateAmount('0'), isNotNull);
      expect(CustomValidators.validateAmount('-5'), isNotNull);
      expect(CustomValidators.validateAmount('180.5'), isNull);
    });

    test('description needs 10 to 200 characters', () {
      expect(CustomValidators.validateDescreption('short'), isNotNull);
      expect(CustomValidators.validateDescreption('a' * 201), isNotNull);
      expect(
        CustomValidators.validateDescreption('Morning cup from the cafe'),
        isNull,
      );
    });
  });

  group('CoffeeRecordsModel', () {
    test('survives a toJson / fromJson round trip', () {
      final original = CoffeeRecordsModel(
        id: 1754654321000000,
        title: 'Cappuccino',
        des: 'Morning cup from the campus cafe',
        amount: 180.0,
        date: DateTime.parse('2026-08-08T09:15:00.000Z'),
      );

      final restored = CoffeeRecordsModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.des, original.des);
      expect(restored.amount, original.amount);
      expect(restored.date.toUtc(), original.date.toUtc());
    });

    test('copyWith attaches the Firestore document id', () {
      final record = CoffeeRecordsModel(
        id: 1,
        title: 'Latte',
        des: 'A description that is long enough',
        amount: 200.0,
        date: DateTime.now(),
      );

      expect(record.docId, isNull);
      expect(record.copyWith(docId: 'abc123').docId, 'abc123');
      // Other fields are untouched.
      expect(record.copyWith(docId: 'abc123').title, 'Latte');
    });

    test('date parsing accepts epoch milliseconds as well as ISO strings', () {
      final fromMillis = CoffeeRecordsModel.fromJson({
        'id': 1,
        'title': 'Espresso',
        'des': 'Parsed from epoch millis',
        'amount': 120,
        'date': 1754650500000,
      });

      expect(fromMillis.date.millisecondsSinceEpoch, 1754650500000);
      expect(fromMillis.amount, 120.0);
    });

    test('missing fields fall back to safe defaults instead of throwing', () {
      final sparse = CoffeeRecordsModel.fromJson({'title': 'Mocha'});

      expect(sparse.title, 'Mocha');
      expect(sparse.id, 0);
      expect(sparse.des, '');
      expect(sparse.amount, isNull);
      expect(sparse.date, isNotNull);
    });
  });
}
