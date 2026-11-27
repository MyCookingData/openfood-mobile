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

  group('MenuOrderHelper & Ordering Models Tests', () {
    test('sortCategories prioritizes restaurant order, then global order, then alphabetical', () {
      final result = MenuOrderHelper.sortCategories(
        ['Zebra', 'Burgers & wraps', 'Poulet à partager', 'Soft & boissons', 'Alpha', 'Poulet'],
        restaurantCategoryOrder: ['Soft & boissons', 'burgers & wraps '],
        globalCategoryOrder: {'Poulet': 2, 'Poulet à partager': 21},
      );

      expect(result, [
        'Soft & boissons',
        'Burgers & wraps',
        'Poulet',
        'Poulet à partager',
        'Alpha',
        'Zebra',
      ]);
    });

    test('sortProductModels puts ordered items first, then legacy null sortOrder alphabetically by name then id', () {
      final products = [
        ProductModel(id: 'p_legacy_b', restaurantId: 'r1', category: 'Burgers', name: 'Burger B', description: '', image: '', priceHT: 10),
        ProductModel(id: 'p_2', restaurantId: 'r1', category: 'Burgers', name: 'Alpha', description: '', image: '', priceHT: 10, sortOrder: 1),
        ProductModel(id: 'p_legacy_a2', restaurantId: 'r1', category: 'Burgers', name: 'Burger A', description: '', image: '', priceHT: 10),
        ProductModel(id: 'p_1', restaurantId: 'r1', category: 'Burgers', name: 'Zeta', description: '', image: '', priceHT: 10, sortOrder: 0),
        ProductModel(id: 'p_legacy_a1', restaurantId: 'r1', category: 'Burgers', name: 'Burger A', description: '', image: '', priceHT: 10),
      ];

      final sorted = MenuOrderHelper.sortProductModels(products);
      expect(sorted.map((p) => p.id).toList(), [
        'p_1',
        'p_2',
        'p_legacy_a1',
        'p_legacy_a2',
        'p_legacy_b',
      ]);
    });

    test('nextSortOrderForCategory computes 0, max+1, or null for legacy categories', () {
      expect(MenuOrderHelper.nextSortOrderForCategory(const []), 0);

      final ordered = [
        ProductModel(id: 'a', restaurantId: 'r1', category: 'C', name: 'A', description: '', image: '', priceHT: 5, sortOrder: 0),
        ProductModel(id: 'b', restaurantId: 'r1', category: 'C', name: 'B', description: '', image: '', priceHT: 5, sortOrder: 3),
      ];
      expect(MenuOrderHelper.nextSortOrderForCategory(ordered), 4);

      final mixedLegacy = [
        ProductModel(id: 'a', restaurantId: 'r1', category: 'C', name: 'A', description: '', image: '', priceHT: 5, sortOrder: 0),
        ProductModel(id: 'b', restaurantId: 'r1', category: 'C', name: 'B', description: '', image: '', priceHT: 5),
      ];
      expect(MenuOrderHelper.nextSortOrderForCategory(mixedLegacy), isNull);
    });

    test('ProductModel serializes sortOrder and falls back to legacy order key', () {
      final fromSortOrder = ProductModel.fromJson({
        'id': 'p1',
        'restaurantId': 'r1',
        'category': 'Burgers',
        'name': 'Classic',
        'priceHT': 8.0,
        'sortOrder': 2,
      });
      expect(fromSortOrder.sortOrder, 2);
      expect(fromSortOrder.toJson()['sortOrder'], 2);

      final fromLegacyOrder = ProductModel.fromJson({
        'id': 'p2',
        'restaurantId': 'r1',
        'category': 'Burgers',
        'name': 'Legacy',
        'priceHT': 9.0,
        'order': 4.0,
      });
      expect(fromLegacyOrder.sortOrder, 4);

      final withoutOrder = ProductModel.fromJson({
        'id': 'p3',
        'restaurantId': 'r1',
        'category': 'Burgers',
        'name': 'NoOrder',
        'priceHT': 7.0,
      });
      expect(withoutOrder.sortOrder, isNull);
      expect(withoutOrder.toJson().containsKey('sortOrder'), isFalse);
    });

    test('RestaurantModel round-trips categoryOrder and defaults to empty list', () {
      final withOrder = RestaurantModel.fromJson({
        'id': 'r1',
        'name': 'Resto 1',
        'imageUrl': '',
        'categoryOrder': ['Burgers', ' Desserts ', '', null],
      });
      expect(withOrder.categoryOrder, ['Burgers', 'Desserts']);
      expect(withOrder.toJson()['categoryOrder'], ['Burgers', 'Desserts']);

      final withoutOrder = RestaurantModel.fromJson({
        'id': 'r2',
        'name': 'Resto 2',
        'imageUrl': '',
      });
      expect(withoutOrder.categoryOrder, isEmpty);
      expect(withoutOrder.toJson()['categoryOrder'], isEmpty);
    });
  });

  group('DriverPayoutHelper & OrderModel Payout Tests', () {
    OrderModel makeOrder({
      required String id,
      String? driverId = 'drv_1',
      String? driverName = 'Jean Livreur',
      int status = 3,
      double totalAmount = 25.0,
      double? driverPayout,
      bool driverPaid = false,
      DateTime? createdAt,
      DateTime? deliveredAt,
      DateTime? driverPaidAt,
    }) {
      return OrderModel(
        id: id,
        userId: 'cust_1',
        restaurantId: 'resto_1',
        restaurantName: 'Le Grill',
        status: status,
        totalAmount: totalAmount,
        items: const [],
        createdAt: createdAt ?? DateTime(2026, 11, 20, 12, 0),
        deliveredAt: deliveredAt,
        driverId: driverId,
        driverName: driverName,
        driverPayout: driverPayout,
        driverPaid: driverPaid,
        driverPaidAt: driverPaidAt,
      );
    }

    test('calculatePayout uses 2.50 + 10% with 2-decimal rounding', () {
      expect(DriverPayoutHelper.calculatePayout(0.0), 2.50);
      expect(DriverPayoutHelper.calculatePayout(25.0), 5.00);
      expect(DriverPayoutHelper.calculatePayout(19.95), 4.50);
    });

    test('resolveOrderPayout respects driverPayout override and falls back to formula', () {
      final standard = makeOrder(id: 'o1', totalAmount: 30.0);
      final overridden = makeOrder(id: 'o2', totalAmount: 30.0, driverPayout: 8.75);
      expect(DriverPayoutHelper.resolveOrderPayout(standard), 5.50);
      expect(DriverPayoutHelper.resolveOrderPayout(overridden), 8.75);
    });

    test('buildDriverSummaries aggregates delivered, in-progress, paid/unpaid and excludes cancelled/unassigned', () {
      final orders = [
        makeOrder(id: 'o1', driverId: 'd1', totalAmount: 20.0, driverPaid: true), // 4.50 paid
        makeOrder(id: 'o2', driverId: 'd1', totalAmount: 30.0, driverPaid: false), // 5.50 unpaid
        makeOrder(id: 'o3', driverId: 'd1', status: 2, totalAmount: 40.0), // in progress
        makeOrder(id: 'o4', driverId: 'd1', status: 4, totalAmount: 50.0), // cancelled
        makeOrder(id: 'o5', driverId: null, status: 3, totalAmount: 15.0), // unassigned
        makeOrder(id: 'o6', driverId: 'd2', driverName: null, totalAmount: 10.0, driverPayout: 6.00), // 6.00 unpaid
      ];

      final summaries = DriverPayoutHelper.buildDriverSummaries(
        orders,
        driverProfiles: {
          'd2': {'name': 'Marc Vélo', 'phone': '0696112233', 'vehicleType': 'Vélo'},
        },
      );

      expect(summaries.length, 2);
      // Sorted by unpaidAmount desc: d2 has 6.00 unpaid, d1 has 5.50 unpaid
      expect(summaries[0].driverId, 'd2');
      expect(summaries[0].driverName, 'Marc Vélo');
      expect(summaries[0].vehicleType, 'Vélo');
      expect(summaries[0].unpaidAmount, 6.00);
      expect(summaries[0].deliveredOrdersCount, 1);

      expect(summaries[1].driverId, 'd1');
      expect(summaries[1].deliveredOrdersCount, 2);
      expect(summaries[1].inProgressOrdersCount, 1);
      expect(summaries[1].totalOrderVolume, 50.0);
      expect(summaries[1].totalAmountDue, 10.0);
      expect(summaries[1].paidAmount, 4.50);
      expect(summaries[1].unpaidAmount, 5.50);
      expect(summaries[1].unpaidOrdersCount, 1);
    });

    test('buildPeriodSummaries groups properly by day, week (ISO Mon-Sun), and month', () {
      final orders = [
        makeOrder(id: 'o1', driverId: 'd1', totalAmount: 20.0, deliveredAt: DateTime(2026, 11, 23, 12, 0), driverPaid: true), // Mon W48, 4.50 paid
        makeOrder(id: 'o2', driverId: 'd2', totalAmount: 30.0, deliveredAt: DateTime(2026, 11, 25, 19, 0)), // Wed W48, 5.50 unpaid
        makeOrder(id: 'o3', driverId: 'd1', totalAmount: 10.0, deliveredAt: DateTime(2026, 10, 15, 13, 0)), // Oct W42, 3.50 unpaid
      ];

      final days = DriverPayoutHelper.buildPeriodSummaries(orders, granularity: PayoutPeriodGranularity.day);
      expect(days.length, 3);
      expect(days.first.periodLabel, '25/11/2026');
      expect(days.first.totalAmountDue, 5.50);

      final weeks = DriverPayoutHelper.buildPeriodSummaries(orders, granularity: PayoutPeriodGranularity.week);
      expect(weeks.length, 2);
      expect(weeks[0].deliveredOrdersCount, 2);
      expect(weeks[0].activeDriversCount, 2);
      expect(weeks[0].totalAmountDue, 10.00);
      expect(weeks[0].paidAmount, 4.50);
      expect(weeks[0].unpaidAmount, 5.50);

      final months = DriverPayoutHelper.buildPeriodSummaries(orders, granularity: PayoutPeriodGranularity.month);
      expect(months.length, 2);
      expect(months[0].periodLabel, 'Novembre 2026');
      expect(months[0].totalAmountDue, 10.00);
      expect(months[1].periodLabel, 'Octobre 2026');
      expect(months[1].totalAmountDue, 3.50);
    });

    test('CSV exports include UTF-8 BOM, semicolon separator, decimal comma, and quoting', () {
      final order = OrderModel(
        id: 'order123456',
        userId: 'u1',
        restaurantId: 'r1',
        restaurantName: 'Le "Grill"; Créole',
        status: 3,
        totalAmount: 25.0,
        items: const [],
        createdAt: DateTime(2026, 11, 27, 14, 5),
        deliveredAt: DateTime(2026, 11, 27, 14, 30),
        driverId: 'd1',
        driverName: 'Paul',
        driverPaid: false,
      );

      final summaries = DriverPayoutHelper.buildDriverSummaries([order]);
      final summaryCsv = DriverPayoutHelper.generateDriversSummaryCsv(summaries);
      expect(summaryCsv.startsWith('\uFEFF'), isTrue);
      expect(summaryCsv, contains('Paul;;;1;0;25,00;5,00;0,00;5,00;5,00'));

      final ordersCsv = DriverPayoutHelper.generateOrdersCsv([order]);
      expect(ordersCsv.startsWith('\uFEFF'), isTrue);
      expect(ordersCsv, contains('27/11/2026;14:30;#ORDER123;Paul;"Le ""Grill""; Créole";25,00;5,00;À payer;'));
    });

    test('Stripe Connect models and validation helpers', () {
      expect(DriverPayoutHelper.isValidStripeAccountId('acct_1N2abcXYZ'), isTrue);
      expect(DriverPayoutHelper.isValidStripeAccountId('  acct_1Q90ab  '), isTrue);
      expect(DriverPayoutHelper.isValidStripeAccountId(''), isFalse);
      expect(DriverPayoutHelper.isValidStripeAccountId(null), isFalse);
      expect(DriverPayoutHelper.isValidStripeAccountId('cus_123456'), isFalse);
      expect(DriverPayoutHelper.isValidStripeAccountId('acct_'), isFalse);
      expect(DriverPayoutHelper.isValidStripeAccountId('acct_123 456'), isFalse);

      final user = UserModel.fromJson({
        'id': 'u_drv_1',
        'email': 'driver@openfood.fr',
        'name': 'Alex',
        'role': 'livreur',
        'stripeAccountId': 'acct_1DriverXYZ',
        'createdAt': '2026-11-27T12:00:00.000Z',
      });
      expect(user.stripeAccountId, 'acct_1DriverXYZ');
      expect(user.toJson()['stripeAccountId'], 'acct_1DriverXYZ');

      final order = OrderModel(
        id: 'ord_stripe_1',
        userId: 'u_cust_1',
        restaurantId: 'r_1',
        restaurantName: 'Chez Léo',
        status: 3,
        totalAmount: 29.0,
        items: const [],
        createdAt: DateTime(2026, 11, 27, 12, 0),
        deliveredAt: DateTime(2026, 11, 27, 12, 30),
        driverId: 'u_drv_1',
        subtotalAmount: 25.0,
        deliveryFee: 2.75,
        managementFee: 1.25,
        smallOrderFee: 0.0,
        restaurantAmount: 25.0,
        restaurantStripeAccountId: 'acct_1RestoABC',
        driverStripeTransferId: 'tr_123456',
      );
      final mapped = order.toMap();
      expect(mapped['subtotalAmount'], 25.0);
      expect(mapped['deliveryFee'], 2.75);
      expect(mapped['managementFee'], 1.25);
      expect(mapped['smallOrderFee'], 0.0);
      expect(mapped['restaurantAmount'], 25.0);
      expect(mapped['restaurantStripeAccountId'], 'acct_1RestoABC');
      expect(mapped['driverStripeTransferId'], 'tr_123456');

      final summaries = DriverPayoutHelper.buildDriverSummaries(
        [order],
        driverProfiles: {
          'u_drv_1': {
            'name': 'Alex',
            'stripeAccountId': 'acct_1DriverXYZ',
          },
        },
      );
      expect(summaries.length, 1);
      expect(summaries.first.stripeAccountId, 'acct_1DriverXYZ');
    });
  });
}
