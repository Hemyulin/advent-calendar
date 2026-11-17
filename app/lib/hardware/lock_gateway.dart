/// Boundary for deliberate physical unlocking. Implementations verify the
/// device and bound their requests; callers never retry ambiguous commands.
/// The development admin PIN is only a UI entry credential. Firmware-side
/// authorization belongs in the hardware adapter when the protocol supports it.
/// Challenge rules and progress storage stay independent of this contract.
abstract interface class LockGateway {
  Future<void> unlock();
}
