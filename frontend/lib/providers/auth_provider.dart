// =============================================================================
// DiaCare - Authentication State Management Provider
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  ProfileModel? _profile;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasProfile = false;

  UserModel? get user => _user;
  ProfileModel? get profile => _profile;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get hasProfile => _hasProfile;

  /// Check stored token for automatic login
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(AppConstants.keyJwtToken);
      final storedUserData = prefs.getString(AppConstants.keyUserData);

      if (storedToken == null || storedToken.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = storedToken;
      _api.setToken(storedToken);

      if (storedUserData != null) {
        _user = UserModel.fromJson(jsonDecode(storedUserData));
      }

      // Verify token with backend by fetching profile
      final res = await _api.get('api/profile/get.php');
      if (res.success && res.data != null) {
        _hasProfile = res.data['has_profile'] == true;
        if (_hasProfile && res.data['profile'] != null) {
          _profile = ProfileModel.fromJson(res.data['profile']);
        }
        if (res.data['user'] != null) {
          _user = UserModel.fromJson(res.data['user']);
          await prefs.setString(AppConstants.keyUserData, jsonEncode(_user!.toJson()));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Token expired or invalid
        await logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request Mobile OTP (Static OTP: 1234)
  Future<Map<String, dynamic>?> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/send-otp.php', body: {
      'phone': phone,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      notifyListeners();
      return res.data as Map<String, dynamic>;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return null;
    }
  }

  /// Verify Mobile OTP & Auto Register/Login
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/verify-otp.php', body: {
      'phone': phone,
      'otp': otp,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      _token = res.data['token'];
      _api.setToken(_token);
      _user = UserModel.fromJson(res.data['user']);
      _hasProfile = res.data['has_profile'] == true;

      if (res.data['profile'] != null) {
        _profile = ProfileModel.fromJson(res.data['profile']);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyJwtToken, _token!);
      await prefs.setString(AppConstants.keyUserData, jsonEncode(_user!.toJson()));

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// User Registration
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/register.php', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'confirm_password': confirmPassword,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      _token = res.data['token'];
      _api.setToken(_token);
      _user = UserModel.fromJson(res.data['user']);
      _hasProfile = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyJwtToken, _token!);
      await prefs.setString(AppConstants.keyUserData, jsonEncode(_user!.toJson()));

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// User Login
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/login.php', body: {
      'identifier': identifier,
      'password': password,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      _token = res.data['token'];
      _api.setToken(_token);
      _user = UserModel.fromJson(res.data['user']);
      _hasProfile = res.data['has_profile'] == true;

      if (res.data['profile'] != null) {
        _profile = ProfileModel.fromJson(res.data['profile']);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyJwtToken, _token!);
      await prefs.setString(AppConstants.keyUserData, jsonEncode(_user!.toJson()));

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Request Forgot Password OTP
  Future<Map<String, dynamic>?> forgotPasswordRequest(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/forgot-password.php', body: {
      'action': 'request',
      'identifier': identifier,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      notifyListeners();
      return res.data as Map<String, dynamic>;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return null;
    }
  }

  /// Verify OTP and Reset Password
  Future<bool> forgotPasswordReset({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/forgot-password.php', body: {
      'action': 'verify_and_reset',
      'identifier': identifier,
      'code': code,
      'new_password': newPassword,
    });

    _isLoading = false;

    if (res.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Change Password for authenticated user
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _api.post('api/auth/change-password.php', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });

    _isLoading = false;

    if (res.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// Delete Account permanently
  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    final res = await _api.post('api/auth/delete-account.php');

    _isLoading = false;

    if (res.success) {
      await logout();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void setHasProfile(bool val, [ProfileModel? p]) {
    _hasProfile = val;
    if (p != null) _profile = p;
    notifyListeners();
  }

  /// Clear session and logout
  Future<void> logout() async {
    _user = null;
    _profile = null;
    _token = null;
    _hasProfile = false;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyJwtToken);
    await prefs.remove(AppConstants.keyUserData);

    _api.setToken(null);
    notifyListeners();
  }
}
