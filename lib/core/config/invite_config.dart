import 'package:firebase_auth/firebase_auth.dart';

class InviteConfig {
  InviteConfig._();

  // Firebase project domains
  static const String _firebaseAuthDomain = 'play-academy-a73b2.firebaseapp.com';
  static const String _hostingDomain = 'play-academy-a73b2.web.app';

  // The continueUrl: where the user lands after Firebase verifies the link.
  // This must be an https URL in the authorised domains list in Firebase Console.
  static const String continueUrl = 'https://$_hostingDomain/accept-invite';

  // The base URL Firebase sends in the email — used to detect incoming links.
  static const String authDomain = _firebaseAuthDomain;

  // Android app ID — must match applicationId in build.gradle.kts
  static const String androidPackageName = 'com.example.play_academy';

  // iOS bundle ID — update once iOS is configured
  static const String iosBundleId = 'com.example.playAcademy';

  // How long an invitation stays valid
  static const Duration inviteExpiry = Duration(days: 7);

  static ActionCodeSettings get actionCodeSettings => ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: true,
        androidPackageName: androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: iosBundleId,
      );
}
