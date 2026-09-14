extension StringFormatting on String {
  /// Transforms an ID like "open_food · 30 min" or "open_food" to "Open Food"
  String get formattedRestaurantName {
    final base = split(' · ').first.replaceAll('_', ' ');
    return base
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
}
