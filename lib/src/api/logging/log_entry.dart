/// Severity of a log record emitted by the native XELIS runtime.
enum XelisLogLevel { error, warn, info, debug, trace }

/// Native component that emitted a XELIS log record.
enum XelisLogSource {
  xelisWalletFlutter,
  xelisWallet,
  xelisCommon,
  flutterRustBridge,
  dependency,
}

/// A log record emitted by the native XELIS runtime.
///
/// This model is authored Dart API and is independent from generated Flutter
/// Rust Bridge types.
final class XelisLogEntry {
  const XelisLogEntry({
    required this.level,
    required this.source,
    required this.target,
    required this.message,
  });

  final XelisLogLevel level;

  /// Stable high-level provenance suitable for support diagnostics.
  final XelisLogSource source;

  /// Rust log target.
  ///
  /// In standard mode this is the package-owned, stable target. Diagnostic
  /// mode may expose detailed package module targets whose spelling is not API.
  final String target;

  /// Native diagnostic text.
  ///
  /// Standard mode only forwards package-authored safe records. Diagnostic
  /// mode can include local paths, amounts, hashes, or other package-owned
  /// context and must only be retained or displayed in an explicit developer
  /// workflow. Free-form upstream dependency messages are never forwarded.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XelisLogEntry &&
          level == other.level &&
          source == other.source &&
          target == other.target &&
          message == other.message;

  @override
  int get hashCode => Object.hash(level, source, target, message);
}
