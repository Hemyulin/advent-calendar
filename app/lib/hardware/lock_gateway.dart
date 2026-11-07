/// Boundary for the lock controlled by the Raspberry Pi Pico W.
///
/// A future Wi-Fi adapter will own connection details, protocol, and failures.
/// Challenge logic and progress storage must not depend on that adapter.
abstract interface class LockGateway {
  Future<void> unlock();
}
