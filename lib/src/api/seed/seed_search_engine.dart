/// Searches and validates words against one native XELIS mnemonic dictionary.
///
/// Seed words and returned invalid words are sensitive wallet material. This
/// interface does not retain or log them, and consumers must apply the same
/// rule.
abstract interface class SeedSearchEngine {
  /// Whether this engine's native handle has been released.
  bool get isDisposed;

  /// Returns dictionary words matching [query].
  List<String> search({required String query});

  /// Returns the entries from [words] that are absent from the dictionary.
  ///
  /// This checks dictionary membership only; it does not validate the complete
  /// mnemonic structure or checksum.
  List<String> findInvalidWords({required List<String> words});

  /// Releases this engine's native Arc handle.
  ///
  /// This operation is idempotent and does not dispose the process-wide FRB
  /// runtime.
  void dispose();
}
