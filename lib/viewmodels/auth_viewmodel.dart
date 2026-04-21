import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showAccountLinkingPrompt = false;
  String? _pendingLinkEmail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showAccountLinkingPrompt => _showAccountLinkingPrompt;
  String? get pendingLinkEmail => _pendingLinkEmail;

  // Get current user email from FirebaseAuth (source of truth)
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;
  
  // Get linked providers
  Map<String, bool> get linkedProviders => _authService.getLinkedProviders();

  // Login with Email/Password
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _showAccountLinkingPrompt = false;
    notifyListeners();

    try {
      developer.log('[AuthViewModel] [LOGIN] Attempting email/password login for: $email');
      
      // Step 1: Email/password login
      await _authService.login(email, password);
      developer.log('[AuthViewModel] [LOGIN] Email/password login successful for: $email');
      
      // Step 2: Check if account linking is pending (CRITICAL AUTO-LINK)
      if (_authService.hasPendingLinking()) {
        developer.log('[AuthViewModel] [LINK] Pending credential detected for account linking');
        try {
          // Automatically complete the pending account linking
          await _authService.completePendingAccountLinking();
          developer.log('[AuthViewModel] [LINK] Linking success - providers: ${_authService.getLinkedProviders().keys.toList()}');
          
          _showAccountLinkingPrompt = false;
          _pendingLinkEmail = null;
        } catch (linkingError) {
          // Account linking failed, but email login succeeded
          // User can still use email/password login
          developer.log('[AuthViewModel] [LINK] Linking error (non-fatal): $linkingError', error: linkingError);
          _errorMessage = 'Account linking partially failed: $linkingError. You can still log in with email/password.';
        }
      } else {
        developer.log('[AuthViewModel] [LOGIN] No pending linking - login complete');
      }
      
      _errorMessage = null;
      developer.log('[AuthViewModel] [LOGIN] Final providers: ${_authService.getLinkedProviders().keys.toList()}');
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('[AuthViewModel] [LOGIN] Login failed: $_errorMessage', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with Email/Password
  Future<void> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _showAccountLinkingPrompt = false;
    notifyListeners();

    try {
      developer.log('[AuthViewModel] Registering with email: $email');
      await _authService.register(email, password);
      _errorMessage = null;
      developer.log('[AuthViewModel] Registration successful');
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('[AuthViewModel] Registration failed: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _showAccountLinkingPrompt = false;
    notifyListeners();

    try {
      developer.log('[AuthViewModel] Attempting Google Sign-In');
      await _authService.signInWithGoogle();
      _errorMessage = null;
      developer.log('[AuthViewModel] Google Sign-In successful');
    } catch (e) {
      final errorStr = e.toString();
      developer.log('[AuthViewModel] Google Sign-In failed: $errorStr');
      
      // Check if this is an account linking error
      if (errorStr.startsWith('account_linking_required:')) {
        _pendingLinkEmail = errorStr.replaceFirst('account_linking_required:', '');
        _showAccountLinkingPrompt = true;
        _errorMessage = 'This email is already registered. Please log in with email/password to link your Google account.';
        developer.log('[AuthViewModel] Account linking required for email: $_pendingLinkEmail');
      } else {
        _errorMessage = errorStr;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete pending account linking with email/password
  Future<void> completePendingAccountLinking(String email, String password) async {
    if (!_showAccountLinkingPrompt) {
      _errorMessage = 'No pending account linking request';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      developer.log('[AuthViewModel] [LINK] Starting manual account linking for: $email');
      
      // First, sign in with email/password
      developer.log('[AuthViewModel] [LINK] Logging in with email: $email');
      await _authService.login(email, password);
      developer.log('[AuthViewModel] [LINK] Email/password login successful');
      
      // Then complete the pending account linking
      developer.log('[AuthViewModel] [LINK] Linking started');
      await _authService.completePendingAccountLinking();
      
      final providers = _authService.getLinkedProviders();
      developer.log('[AuthViewModel] [LINK] Linking success - Providers: ${providers.keys.toList()}');
      
      _showAccountLinkingPrompt = false;
      _pendingLinkEmail = null;
      _errorMessage = null;
      developer.log('[AuthViewModel] [LINK] Account linking completed successfully');
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('[AuthViewModel] [LINK] Account linking failed: $_errorMessage', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel account linking
  void cancelAccountLinking() {
    _showAccountLinkingPrompt = false;
    _pendingLinkEmail = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Verify account linking status (for debugging)
  Map<String, dynamic> verifyAccountLinking() {
    final providers = _authService.getLinkedProviders();
    final hasEmailPassword = providers.containsKey('password');
    final hasGoogle = providers.containsKey('google.com');
    final isFullyLinked = hasEmailPassword && hasGoogle;
    
    developer.log('[AuthViewModel] [VERIFY] Email/Password provider: $hasEmailPassword');
    developer.log('[AuthViewModel] [VERIFY] Google provider: $hasGoogle');
    developer.log('[AuthViewModel] [VERIFY] Fully linked: $isFullyLinked');
    developer.log('[AuthViewModel] [VERIFY] All providers: ${providers.keys.toList()}');
    
    return {
      'hasEmailPassword': hasEmailPassword,
      'hasGoogle': hasGoogle,
      'isFullyLinked': isFullyLinked,
      'allProviders': providers.keys.toList(),
    };
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    _showAccountLinkingPrompt = false;
    _pendingLinkEmail = null;
    notifyListeners();

    try {
      developer.log('[AuthViewModel] [LOGOUT] Starting logout sequence');
      await _authService.logout();
      _errorMessage = null;
      developer.log('[AuthViewModel] [LOGOUT] Logout successful - Firebase auth cleared');
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('[AuthViewModel] [LOGOUT] Logout failed: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
