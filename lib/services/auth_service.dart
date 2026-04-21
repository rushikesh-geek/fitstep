import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Store pending credential for account linking flow
  AuthCredential? _pendingCredential;
  String? _pendingEmail;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Email/Password Register
  Future<UserCredential> register(String email, String password) async {
    try {
      developer.log('[AuthService] Attempting registration for: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('[AuthService] Registration SUCCESS, UID: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('[AuthService] Registration FAILED: code=${e.code}, message=${e.message}', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('[AuthService] Unexpected registration error: $e', error: e);
      throw 'Unexpected error: $e';
    }
  }

  // Email/Password Login
  Future<UserCredential> login(String email, String password) async {
    try {
      developer.log('[AuthService] Attempting email/password login for: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('[AuthService] Email/password login SUCCESS for: $email, UID: ${userCredential.user!.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('[AuthService] Email/password login FAILED: code=${e.code}, message=${e.message}', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('[AuthService] Unexpected login error: $e', error: e);
      throw 'Unexpected error: $e';
    }
  }

  // Google Sign-In with account linking support
  Future<UserCredential> signInWithGoogle() async {
    try {
      developer.log('[AuthService] Starting Google Sign-In');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        developer.log('[AuthService] Google sign-in cancelled by user');
        throw 'Google sign-in cancelled';
      }

      developer.log('[AuthService] Google sign-in succeeded for: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        developer.log('[AuthService] Attempting to sign in with Google credential');
        final userCredential = await _auth.signInWithCredential(credential);
        developer.log('[AuthService] Google sign-in SUCCESS, UID: ${userCredential.user!.uid}');
        return userCredential;
      } on FirebaseAuthException catch (e) {
        // Handle account-exists-with-different-credential error
        // This occurs when email is already registered with another provider
        if (e.code == 'account-exists-with-different-credential') {
          final email = e.email;
          developer.log('[AuthService] Account exists with different credential for email: $email');
          
          if (email != null) {
            // CRITICAL FIX: Store the pending credential and email for account linking
            _pendingCredential = credential;
            _pendingEmail = email;
            
            developer.log('[AuthService] Stored pending credential for account linking. User must login with email/password first.');
            throw 'account_linking_required:$email';
          }
          
          throw 'This email is already linked with another provider';
        }
        
        developer.log('[AuthService] Google sign-in error: code=${e.code}, message=${e.message}', error: e);
        throw _handleAuthException(e);
      }
    } on FirebaseAuthException catch (e) {
      developer.log('[AuthService] Firebase exception in signInWithGoogle: ${e.message}', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('[AuthService] Unexpected error in signInWithGoogle: $e', error: e);
      throw 'Google sign-in error: $e';
    }
  }

  // Complete pending account linking after email/password login
  // Call this AFTER user successfully logs in with email/password credentials
  Future<UserCredential> completePendingAccountLinking() async {
    try {
      if (_pendingCredential == null || _pendingEmail == null) {
        throw 'No pending account linking request. Please try Google Sign-In again.';
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Not logged in. Cannot complete account linking.';
      }

      developer.log('[AuthService] Attempting to link pending Google credential to user: ${currentUser.email}');
      
      // Link the stored Google credential to the current user
      final linkedCredential = await currentUser.linkWithCredential(_pendingCredential!);
      
      // Clear the pending credential after successful linking
      _pendingCredential = null;
      _pendingEmail = null;
      
      developer.log('[AuthService] Account linking SUCCESSFUL. Email: ${linkedCredential.user!.email}, Providers: ${linkedCredential.user!.providerData.map((p) => p.providerId).toList()}');
      
      return linkedCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('[AuthService] Account linking FAILED: code=${e.code}, message=${e.message}', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('[AuthService] Unexpected error during account linking: $e', error: e);
      throw 'Account linking error: $e';
    }
  }

  // Verify account linking status
  Map<String, bool> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }
    
    final providers = <String, bool>{};
    for (final provider in user.providerData) {
      providers[provider.providerId] = true;
    }
    
    developer.log('[AuthService] Linked providers for ${user.email}: ${providers.keys.toList()}');
    return providers;
  }

  // Get pending email (for UI to know which account needs linking)
  String? getPendingEmail() => _pendingEmail;

  // Check if account linking is pending
  bool hasPendingLinking() => _pendingCredential != null && _pendingEmail != null;

  // Logout
  Future<void> logout() async {
    try {
      developer.log('[AuthService] Logging out current user: ${_auth.currentUser?.email}');
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // Clear any pending linking data
      _pendingCredential = null;
      _pendingEmail = null;
      
      developer.log('[AuthService] Logout SUCCESS');
    } catch (e) {
      developer.log('[AuthService] Logout error: $e', error: e);
      throw 'Logout error: $e';
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'User account is disabled';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}
