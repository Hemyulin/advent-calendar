/// Boundary for the lock controlled by the Raspberry Pi Pico W.
///
/// A future Wi-Fi adapter must own device authorization, verified connection
/// details, protocol, and failures. The development admin PIN grants no
/// authority here. The current Pico firmware has no unlock endpoint.
/// Challenge logic and progress storage must not depend on that adapter.
abstract interface class LockGateway {
  Future<void> unlock();
}
