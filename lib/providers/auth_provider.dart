import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _userModel;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isOrgAdmin => _userModel?.isOrgAdmin ?? false;
  bool get isCoach => _userModel?.isCoach ?? false;
  bool get isPlayer => _userModel?.isPlayer ?? false;

  AuthProvider() {
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _userModel = null;
        notifyListeners();
        return;
      }

      // Retry up to 5 times — the doc may still be mid-write (registration race)
      for (int i = 0; i < 5; i++) {
        try {
          _userModel = await _firestoreService
              .getUserDoc(user.uid)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          _userModel = null;
        }
        if (_userModel != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }

      if (_userModel != null) {
        if (!_userModel!.isActive) {
          _error = 'Your account has been deactivated. Please contact your administrator.';
          await _authService.signOut();
          _status = AuthStatus.unauthenticated;
          _userModel = null;
        } else {
          _status = AuthStatus.authenticated;
          try {
            await NotificationService().initialize(
              user.uid,
              isPlayer: _userModel!.isPlayer,
            );
          } catch (_) {
            // Notification init failure should not block login
          }
        }
      } else {
        // Auth account exists but no Firestore doc after retries — sign out
        await _authService.signOut();
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      _error = _friendlyAuthError(e.code);
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}
