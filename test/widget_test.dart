import 'package:flutter_test/flutter_test.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:openfood_mobile/services/auth_service.dart';
import 'package:openfood_mobile/utils/restaurant_helper.dart';

void main() {
  group('OpeningHoursHelper Tests', () {
    test('defaultOpeningHours structure', () {
      final hours = OpeningHoursHelper.defaultOpeningHours();
      expect(hours.containsKey('monday'), isTrue);
      expect(hours.containsKey('sunday'), isTrue);
      expect(hours['monday']!['isOpen'], isTrue);
      expect(hours['sunday']!['isOpen'], isFalse);
    });

    test('parseMinutes works properly', () {
      expect(OpeningHoursHelper.parseMinutes('11:30'), 11 * 60 + 30);
      expect(OpeningHoursHelper.parseMinutes('11h30'), 11 * 60 + 30);
      expect(OpeningHoursHelper.parseMinutes('00:00'), 0);
      expect(OpeningHoursHelper.parseMinutes(null), isNull);
    });

    test('formatTimeDisplay formats properly', () {
      expect(OpeningHoursHelper.formatTimeDisplay('11:30'), '11h30');
      expect(OpeningHoursHelper.formatTimeDisplay('9:05'), '09h05');
      expect(OpeningHoursHelper.formatTimeDisplay('18h00'), '18h00');
    });

    test('getStatus returns open during open slot', () {
      final hours = {
        'monday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      };
      // Monday at 12:15
      final dt = DateTime(2026, 11, 16, 12, 15); // Nov 16, 2026 is Monday
      final status = OpeningHoursHelper.getStatus(hours, now: dt);
      expect(status.isOpen, isTrue);
      expect(status.detailStatus, contains('ferme à 14h30'));
    });

    test('getStatus returns closed between lunch and dinner slot', () {
      final hours = {
        'monday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      };
      // Monday at 16:00
      final dt = DateTime(2026, 11, 16, 16, 00);
      final status = OpeningHoursHelper.getStatus(hours, now: dt);
      expect(status.isOpen, isFalse);
      expect(status.detailStatus, contains('ouvre à 18h30'));
    });

    test('getStatus respects manual inactif override', () {
      final hours = {
        'monday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: false).toJson(),
      };
      final dt = DateTime(2026, 11, 16, 12, 15);
      final status = OpeningHoursHelper.getStatus(hours, manualStatus: 'inactif', now: dt);
      expect(status.isOpen, isFalse);
      expect(status.detailStatus, contains('Fermé'));
    });
  });

  group('Restaurant startingPrice Tests', () {
    test('RestaurantModel correctly deserializes numeric startingPrice', () {
      final json = {
        'id': 'resto_1',
        'name': 'Test Resto',
        'imageUrl': '',
        'startingPrice': 8.5,
      };
      final resto = RestaurantModel.fromJson(json);
      expect(resto.startingPrice, 8.5);
    });

    test('RestaurantModel correctly deserializes string startingPrice', () {
      final json = {
        'id': 'resto_2',
        'name': 'Test Resto 2',
        'imageUrl': '',
        'startingPrice': '12,50 €',
      };
      final resto = RestaurantModel.fromJson(json);
      expect(resto.startingPrice, 12.5);
    });

    test('RestaurantModel correctly serializes startingPrice', () {
      final resto = RestaurantModel(
        id: 'resto_3',
        name: 'Test Resto 3',
        imageUrl: '',
        startingPrice: 9.0,
      );
      final json = resto.toJson();
      expect(json['startingPrice'], 9.0);
    });
  });

  group('AuthService.formatPhoneNumber Tests', () {
    test('normalizes Martinique, Guadeloupe, Guyane, and France numbers', () {
      expect(AuthService.formatPhoneNumber('0696 12 34 56'), '+596696123456');
      expect(AuthService.formatPhoneNumber('+596 0696 12 34 56'), '+596696123456');
      expect(AuthService.formatPhoneNumber('0690 11 22 33'), '+590690112233');
      expect(AuthService.formatPhoneNumber('0694 44 55 66'), '+594694445566');
      expect(AuthService.formatPhoneNumber('06 12 34 56 78'), '+33612345678');
    });
  });

  group('RestaurantHelper.closedOrderMessage Tests', () {
    test('formats message with nextChangeText when present', () {
      const status = RestaurantOpenStatus(
        isOpen: false,
        shortStatus: 'Fermé',
        detailStatus: 'Fermé · ouvre à 18h30',
        nextChangeText: 'ouvre à 18h30',
      );
      final msg = RestaurantHelper.closedOrderMessage('QG StreetFood', status);
      expect(msg, 'QG StreetFood est actuellement fermé (ouvre à 18h30). Impossible de commander pour le moment.');
    });

    test('formats message cleanly when nextChangeText is empty or name is empty', () {
      const status = RestaurantOpenStatus(
        isOpen: false,
        shortStatus: 'Fermé',
        detailStatus: 'Fermé',
      );
      final msg = RestaurantHelper.closedOrderMessage('', status);
      expect(msg, 'Ce restaurant est actuellement fermé. Impossible de commander pour le moment.');
    });
  });
}
