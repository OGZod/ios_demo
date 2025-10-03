// services/user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAdmin => _isAdmin;

  UserProvider() {
    _loadUserDataFromPrefs();
  }

  Future<void> updateUser(User? user) async {
    _user = user;
    _isAdmin = user?.email?.endsWith('@admin.edu') ?? false;

    final moreUserData = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();

    final studentNumber = moreUserData.data()?['identificationNumber'];


    if (user != null) {
      // Store basic user data locally
      _userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isAdmin': _isAdmin,
        'identificationNumber': studentNumber,
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      // Save to SharedPreferences
      await _saveUserDataToPrefs();
    } else {
      _userData = null;
      await _clearUserDataFromPrefs();
    }
    
    notifyListeners();
  }
  
  // Save additional user data beyond what Firebase provides
  Future<void> updateUserData(Map<String, dynamic> additionalData) async {
    if (_userData != null) {
      _userData!.addAll(additionalData);
      await _saveUserDataToPrefs();
      notifyListeners();
    }
  }

  // Clear user data on logout
  Future<void> clearUser() async {
    _user = null;
    _userData = null;
    _isAdmin = false;
    await _clearUserDataFromPrefs();
    notifyListeners();
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userData != null) {
        await prefs.setString('user_data', jsonEncode(_userData));
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        _userData = jsonDecode(userData) as Map<String, dynamic>;
        _isAdmin = _userData!['isAdmin'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Clear user data from SharedPreferences
  Future<void> _clearUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }
}