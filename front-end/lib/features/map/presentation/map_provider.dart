import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/location/location_service.dart';

class MapProvider extends ChangeNotifier {
  final LocationService _locationService;

  MapProvider({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> getUserLocation() async {
    try {
      _setLoading(true);
      _setError(null);
      await _locationService.requestPermission();
      _currentPosition = await _locationService.getCurrentPosition();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
