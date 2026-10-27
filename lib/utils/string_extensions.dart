import 'restaurant_helper.dart';

extension StringFormatting on String {
  /// Transforme un ID, un slug ou un nom en affichage propre et lisible pour le client.
  /// Protège rigoureusement contre l'affichage de hash ou identifiants techniques bruts.
  String get formattedRestaurantName {
    return RestaurantHelper.cleanRestaurantName(this);
  }
}
