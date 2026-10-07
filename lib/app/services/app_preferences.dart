import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  final SharedPreferences _prefs;

  AppPreferences({required SharedPreferences prefs}) : _prefs = prefs;

  // All read methods available directly
  SharedPreferences get prefs => _prefs;

  // Generic write helper — any setter, auto-notifies
  Future<void> update(Future<void> Function(SharedPreferences) action) async {
    await action(_prefs);
    notifyListeners();
  }
}
