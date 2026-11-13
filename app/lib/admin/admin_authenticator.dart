/// Grants access to the administration UI only, never to a physical lock.
/// Replace this boundary with real authentication independently of the screens.
abstract interface class AdminAuthenticator {
  Future<bool> authenticate(String pin);
}

/// Initial development credential. Client-side checks are not device authorization.
class DevelopmentAdminAuthenticator implements AdminAuthenticator {
  const DevelopmentAdminAuthenticator();
  static const String _pin = '0542';

  @override
  Future<bool> authenticate(String pin) async => pin == _pin;
}
