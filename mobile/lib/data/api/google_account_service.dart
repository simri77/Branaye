import 'package:google_sign_in/google_sign_in.dart';

const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const googleDriveFileScope = 'https://www.googleapis.com/auth/drive.file';

class GoogleAccountService {
  GoogleAccountService()
    : _signIn = GoogleSignIn(
        serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
        scopes: const ['email', 'profile'],
      );

  final GoogleSignIn _signIn;

  Future<String?> signInForAuthentication() async {
    _ensureConfigured();
    final account = await _signIn.signIn();
    if (account == null) return null;
    final idToken = (await account.authentication).idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Check the Google OAuth client configuration.',
      );
    }
    return idToken;
  }

  Future<String?> authorizeDrive() async {
    _ensureConfigured();
    final driveSignIn = GoogleSignIn(
      serverClientId: googleWebClientId,
      scopes: const [googleDriveFileScope],
    );
    final account = await driveSignIn.signIn();
    if (account == null) return null;
    final accessToken = (await account.authentication).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Google did not grant access to Google Drive.');
    }
    return accessToken;
  }

  void _ensureConfigured() {
    if (googleWebClientId.isEmpty) {
      throw StateError(
        'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID when building the app.',
      );
    }
  }
}
