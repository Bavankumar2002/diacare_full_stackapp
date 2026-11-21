// =============================================================================
// DiaCare - Patient Profile State Management Provider
// =============================================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/profile_model.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Calculate Body Mass Index: weight(kg) / (height(m))^2
  static double calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Fetch user profile from API
  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.get('api/profile/get.php');
    _isLoading = false;

    if (res.success && res.data != null && res.data['profile'] != null) {
      _profile = ProfileModel.fromJson(res.data['profile']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Create or update profile
  Future<bool> saveProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/profile/update.php', body: profileData);
    _isLoading = false;

    if (res.success && res.data != null && res.data['profile'] != null) {
      _profile = ProfileModel.fromJson(res.data['profile']);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void setProfile(ProfileModel p) {
    _profile = p;
    notifyListeners();
  }
}
