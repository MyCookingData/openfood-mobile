import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._();
  
  CartService._();

  double _total = 0.0;
  int _itemCount = 0;
  final double promoThreshold = 25.0;

  double get total => _total;
  int get itemCount => _itemCount;

  void addItem(double price) {
    _total += price;
    _itemCount++;
    notifyListeners();
  }

  void reset() {
    _total = 0.0;
    _itemCount = 0;
    notifyListeners();
  }
}
