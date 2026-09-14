import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openfood_models/openfood_models.dart';
import 'package:uuid/uuid.dart';

class LocationProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  String? _selectedAddressId;

  List<AddressModel> get addresses => _addresses;

  AddressModel? get selectedAddress {
    if (_selectedAddressId == null || _addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((a) => a.id == _selectedAddressId);
    } catch (_) {
      return null;
    }
  }

  LocationProvider() {
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final String? addressesJson = prefs.getString('user_addresses_list');
    final String? activeId = prefs.getString('user_active_address_id');

    if (addressesJson != null) {
      try {
        final List<dynamic> decoded = json.decode(addressesJson);
        _addresses = decoded.map((item) => AddressModel.fromJson(item)).toList();
      } catch (e) {
        _addresses = [];
      }
    }

    if (activeId != null) {
      _selectedAddressId = activeId;
    } else if (_addresses.isNotEmpty) {
      _selectedAddressId = _addresses.first.id;
    }

    notifyListeners();
  }

  Future<void> addAddress({required String label, required String addressName, required double lat, required double lng}) async {
    final newId = const Uuid().v4();
    final newAddress = AddressModel(id: newId, label: label, addressName: addressName, latitude: lat, longitude: lng);
    
    _addresses.add(newAddress);
    _selectedAddressId = newId; // Auto select newly added address
    
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> removeAddress(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.isNotEmpty ? _addresses.first.id : null;
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> selectAddress(String id) async {
    _selectedAddressId = id;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_addresses.map((a) => a.toJson()).toList());
    await prefs.setString('user_addresses_list', encoded);
    if (_selectedAddressId != null) {
      await prefs.setString('user_active_address_id', _selectedAddressId!);
    } else {
      await prefs.remove('user_active_address_id');
    }
  }
}
