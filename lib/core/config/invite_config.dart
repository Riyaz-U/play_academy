import 'package:firebase_auth/firebase_auth.dart';

class InviteConfig {
  InviteConfig._();

  // Firebase project domains
  static const String _firebaseAuthDomain = 'play-academy-a73b2.firebaseapp.com';
  static const String _hostingDomain = 'play-academy-a73b2.web.app';

  // Base path for the accept-invite screen deep link
  static const String _acceptPath = '/accept-invite';

  // The base URL Firebase sends in the email — used to detect incoming links
  static const String authDomain = _firebaseAuthDomain;

  // Android app ID — must match applicationId in build.gradle.kts
  static const String androidPackageName = 'com.example.play_academy';

  // iOS bundle ID — update once iOS is configured
  static const String iosBundleId = 'com.example.playAcademy';

  // How long an invitation stays valid
  static const Duration inviteExpiry = Duration(days: 7);

  /// Builds the continueUrl with email + inviteId embedded as query params.
  /// Admin and invitee are on different devices, so we cannot use
  /// SharedPreferences — the email must travel inside the URL itself.
  static String buildContinueUrl(String email, String inviteId) {
    final params = Uri(queryParameters: {
      'email': email,
      'inviteId': inviteId,
    }).query;
    return 'https://$_hostingDomain$_acceptPath?$params';
  }

  /// Builds ActionCodeSettings for a specific invite.
  /// Called once per sendInvite / resendInvite.
  static ActionCodeSettings buildActionCodeSettings(
          String email, String inviteId) =>
      ActionCodeSettings(
        url: buildContinueUrl(email, inviteId),
        handleCodeInApp: true,
        androidPackageName: androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: iosBundleId,
      );

  /// Extracts email + inviteId from an incoming deep-link URL.
  /// Works on both the raw Firebase auth link and the continueUrl redirect.
  static ({String? email, String? inviteId}) parseIncomingLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return (email: null, inviteId: null);

    // Direct continueUrl hit (web.app/accept-invite?email=...&inviteId=...)
    if (uri.queryParameters.containsKey('email')) {
      return (
        email: uri.queryParameters['email'],
        inviteId: uri.queryParameters['inviteId'],
      );
    }

    // Firebase auth action URL — continueUrl is a nested query param
    final continueUrl = uri.queryParameters['continueUrl'];
    if (continueUrl != null) {
      final inner = Uri.tryParse(continueUrl);
      if (inner != null) {
        return (
          email: inner.queryParameters['email'],
          inviteId: inner.queryParameters['inviteId'],
        );
      }
    }

    return (email: null, inviteId: null);
  }
}
