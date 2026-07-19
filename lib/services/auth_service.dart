import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Creates a new account (coach or player) without signing out the current admin.
  /// Uses a secondary Firebase app instance so the main auth session is untouched.
  Future<String> createAccountWithoutSignOut({
    required String email,
    required String password,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user!.uid;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Email Link (invitation flow) ─────────────────────

  /// Sends a sign-in link to [email]. Firebase delivers the email;
  /// the link opens the app via the continueUrl deep link.
  Future<void> sendInviteEmailLink(
      String email, ActionCodeSettings settings) {
    return _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: settings,
    );
  }

  /// Completes the sign-in after the user taps the email link.
  /// [email] must be the same address the link was sent to (read from
  /// SharedPreferences — Firebase requires it to prevent phishing).
  Future<UserCredential> completeEmailLinkSignIn(
      String email, String emailLink) {
    return _auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
  }

  /// Links a password credential to the currently signed-in (email-link)
  /// account so the user can also log in with email+password in future.
  Future<void> linkPasswordCredential(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user');
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.linkWithCredential(credential);
  }

  /// Returns true if [link] is a valid Firebase email sign-in link.
  bool isSignInWithEmailLink(String link) =>
      _auth.isSignInWithEmailLink(link);
}
