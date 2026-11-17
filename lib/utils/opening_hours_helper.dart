class DaySchedule {
  final bool isOpen;
  final String open;
  final String close;
  final bool hasSecondSlot;
  final String open2;
  final String close2;

  const DaySchedule({
    this.isOpen = true,
    this.open = '11:30',
    this.close = '14:30',
    this.hasSecondSlot = true,
    this.open2 = '18:30',
    this.close2 = '22:30',
  });

  Map<String, dynamic> toJson() => {
        'isOpen': isOpen,
        'open': open,
        'close': close,
        'hasSecondSlot': hasSecondSlot,
        'open2': open2,
        'close2': close2,
      };

  factory DaySchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DaySchedule();
    return DaySchedule(
      isOpen: json['isOpen'] as bool? ?? true,
      open: json['open'] as String? ?? '11:30',
      close: json['close'] as String? ?? '14:30',
      hasSecondSlot: json['hasSecondSlot'] as bool? ?? false,
      open2: json['open2'] as String? ?? '18:30',
      close2: json['close2'] as String? ?? '22:30',
    );
  }

  DaySchedule copyWith({
    bool? isOpen,
    String? open,
    String? close,
    bool? hasSecondSlot,
    String? open2,
    String? close2,
  }) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      open: open ?? this.open,
      close: close ?? this.close,
      hasSecondSlot: hasSecondSlot ?? this.hasSecondSlot,
      open2: open2 ?? this.open2,
      close2: close2 ?? this.close2,
    );
  }
}

class RestaurantOpenStatus {
  final bool isOpen;
  final String shortStatus;
  final String detailStatus;
  final String nextChangeText;
  final bool isClosedForDay;

  const RestaurantOpenStatus({
    required this.isOpen,
    required this.shortStatus,
    required this.detailStatus,
    this.nextChangeText = '',
    this.isClosedForDay = false,
  });
}

class OpeningHoursHelper {
  static const List<String> dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> dayNamesFr = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };

  static String dayKeyFromWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  static Map<String, Map<String, dynamic>> defaultOpeningHours() {
    return {
      'monday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      'tuesday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      'wednesday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      'thursday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '22:30').toJson(),
      'friday': const DaySchedule(isOpen: true, open: '11:30', close: '14:30', hasSecondSlot: true, open2: '18:30', close2: '23:00').toJson(),
      'saturday': const DaySchedule(isOpen: true, open: '18:30', close: '23:00', hasSecondSlot: false, open2: '', close2: '').toJson(),
      'sunday': const DaySchedule(isOpen: false, open: '11:30', close: '14:30', hasSecondSlot: false, open2: '', close2: '').toJson(),
    };
  }

  static int? parseMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final cleaned = timeStr.trim().replaceAll('h', ':').replaceAll('H', ':');
    final parts = cleaned.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  static String formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    final cleaned = timeStr.trim().replaceAll('h', ':').replaceAll('H', ':');
    final parts = cleaned.split(':');
    final h = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return '${h}h$m';
  }

  static String formatScheduleSummary(DaySchedule schedule) {
    if (!schedule.isOpen) return 'Fermé';
    final p1 = '${formatTimeDisplay(schedule.open)} - ${formatTimeDisplay(schedule.close)}';
    if (schedule.hasSecondSlot && schedule.open2.isNotEmpty && schedule.close2.isNotEmpty) {
      final p2 = '${formatTimeDisplay(schedule.open2)} - ${formatTimeDisplay(schedule.close2)}';
      return '$p1 & $p2';
    }
    return p1;
  }

  static bool _isTimeInSlot(int currentMin, int startMin, int endMin) {
    if (endMin < startMin) {
      return currentMin >= startMin || currentMin < endMin;
    }
    return currentMin >= startMin && currentMin < endMin;
  }

  static RestaurantOpenStatus getStatus(
    Map<String, dynamic>? openingHours, {
    String? manualStatus,
    DateTime? now,
  }) {
    if (manualStatus == 'inactif') {
      return const RestaurantOpenStatus(
        isOpen: false,
        shortStatus: 'Fermé',
        detailStatus: 'Fermé actuellement',
        nextChangeText: 'Fermé temporairement',
        isClosedForDay: true,
      );
    }

    if (openingHours == null || openingHours.isEmpty) {
      final bool isActive = manualStatus != 'inactif';
      return RestaurantOpenStatus(
        isOpen: isActive,
        shortStatus: isActive ? 'Ouvert' : 'Fermé',
        detailStatus: isActive ? 'Ouvert' : 'Fermé',
      );
    }

    final currentDateTime = now ?? DateTime.now();
    final todayKey = dayKeyFromWeekday(currentDateTime.weekday);
    final todayRaw = openingHours[todayKey];
    final DaySchedule todaySchedule = todayRaw is Map<String, dynamic>
        ? DaySchedule.fromJson(todayRaw)
        : (todayRaw is Map ? DaySchedule.fromJson(Map<String, dynamic>.from(todayRaw)) : const DaySchedule(isOpen: false));

    final int nowMinutes = currentDateTime.hour * 60 + currentDateTime.minute;

    if (todaySchedule.isOpen) {
      final open1 = parseMinutes(todaySchedule.open);
      final close1 = parseMinutes(todaySchedule.close);

      final open2 = todaySchedule.hasSecondSlot ? parseMinutes(todaySchedule.open2) : null;
      final close2 = todaySchedule.hasSecondSlot ? parseMinutes(todaySchedule.close2) : null;

      // Check slot 1
      if (open1 != null && close1 != null && _isTimeInSlot(nowMinutes, open1, close1)) {
        final closeStr = formatTimeDisplay(todaySchedule.close);
        return RestaurantOpenStatus(
          isOpen: true,
          shortStatus: 'Ouvert',
          detailStatus: 'Ouvert · ferme à $closeStr',
          nextChangeText: 'Ferme à $closeStr',
        );
      }

      // Check slot 2
      if (open2 != null && close2 != null && _isTimeInSlot(nowMinutes, open2, close2)) {
        final closeStr = formatTimeDisplay(todaySchedule.close2);
        return RestaurantOpenStatus(
          isOpen: true,
          shortStatus: 'Ouvert',
          detailStatus: 'Ouvert · ferme à $closeStr',
          nextChangeText: 'Ferme à $closeStr',
        );
      }

      // Currently closed today: will it open later today?
      if (open1 != null && nowMinutes < open1) {
        final openStr = formatTimeDisplay(todaySchedule.open);
        return RestaurantOpenStatus(
          isOpen: false,
          shortStatus: 'Fermé',
          detailStatus: 'Fermé · ouvre à $openStr',
          nextChangeText: 'Ouvre à $openStr',
        );
      }

      if (open2 != null && nowMinutes < open2) {
        final openStr = formatTimeDisplay(todaySchedule.open2);
        return RestaurantOpenStatus(
          isOpen: false,
          shortStatus: 'Fermé',
          detailStatus: 'Fermé · ouvre à $openStr',
          nextChangeText: 'Ouvre à $openStr',
        );
      }
    }

    // Closed for the rest of today, check next days
    for (int i = 1; i <= 7; i++) {
      final nextWeekday = ((currentDateTime.weekday - 1 + i) % 7) + 1;
      final nextDayKey = dayKeyFromWeekday(nextWeekday);
      final nextRaw = openingHours[nextDayKey];
      final nextSchedule = nextRaw is Map<String, dynamic>
          ? DaySchedule.fromJson(nextRaw)
          : (nextRaw is Map ? DaySchedule.fromJson(Map<String, dynamic>.from(nextRaw)) : const DaySchedule(isOpen: false));

      if (nextSchedule.isOpen) {
        final openTime = formatTimeDisplay(nextSchedule.open);
        final dayLabel = i == 1 ? 'demain' : dayNamesFr[nextDayKey]?.toLowerCase() ?? '';
        return RestaurantOpenStatus(
          isOpen: false,
          shortStatus: 'Fermé',
          detailStatus: 'Fermé · ouvre $dayLabel à $openTime',
          nextChangeText: 'Ouvre $dayLabel à $openTime',
          isClosedForDay: true,
        );
      }
    }

    return const RestaurantOpenStatus(
      isOpen: false,
      shortStatus: 'Fermé',
      detailStatus: 'Fermé',
      nextChangeText: 'Fermé',
      isClosedForDay: true,
    );
  }
}
