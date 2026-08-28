/// Severity of a log record emitted by the native XELIS runtime.
enum XelisLogLevel { error, warn, info, debug, trace }

/// Process-wide native log visibility selected before logger initialization.
enum XelisNativeLogScope {
  standard,
  packageDiagnostic,
  unsafeUpstreamDiagnostic,
}

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
  /// Safe scopes expose package-owned targets only. The unsafe upstream scope
  /// can also expose `xelis_wallet` and `xelis_common` module targets.
  final String target;

  /// Native diagnostic text.
  ///
  /// The unsafe upstream scope carries no XWF redaction guarantee and is only
  /// suitable for an explicit local diagnostic workflow.
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
