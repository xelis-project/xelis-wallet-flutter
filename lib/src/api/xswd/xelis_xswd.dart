import 'dart:async';
import 'dart:collection';

/// Policy retained for one permission of an active XSWD application.
enum XelisXswdPermissionPolicy { ask, accept, reject }

/// Decision returned to an external XSWD application.
enum XelisXswdDecision { accept, reject, alwaysAccept, alwaysReject }

/// Stable kind of request delivered through [XelisXswdCallbacks].
enum XelisXswdRequestKind {
  application,
  permission,
  prefetchPermissions,
  cancel,
  applicationDisconnect,
}

/// Lossless authored value from the effective RPC request delivered by XSWD.
///
/// Values may contain active secrets supplied by the requesting application,
/// including explicit signer private keys. Inspect them only inside the
/// callback that received them, and never log, retain, or display an entire
/// payload. Every [toString] implementation is deliberately redacted.
sealed class XelisXswdValue {
  const XelisXswdValue();
}

/// Resource budget used while projecting one parsed XSWD request to Dart.
///
/// These limits protect the Rust/FRB/Dart boundary. They are not XELIS
/// protocol limits. Custom values may be stricter or more permissive than the
/// defaults but cannot exceed the package-owned technical ceilings.
final class XelisXswdProjectionLimits {
  const XelisXswdProjectionLimits({
    this.maxDepth = defaultMaxDepth,
    this.maxTokens = defaultMaxTokens,
    this.maxContainerMembers = defaultMaxContainerMembers,
    this.maxTextBytes = defaultMaxTextBytes,
    this.maxTotalTextBytes = defaultMaxTotalTextBytes,
  });

  static const defaultMaxDepth = 64;
  static const defaultMaxTokens = 65536;
  static const defaultMaxContainerMembers = 4096;
  static const defaultMaxTextBytes = 4 * 1024 * 1024;
  static const defaultMaxTotalTextBytes = 8 * 1024 * 1024;

  static const technicalMaxDepth = 128;
  static const technicalMaxTokens = 262144;
  static const technicalMaxContainerMembers = 65536;
  static const technicalMaxTextBytes = 8 * 1024 * 1024;
  static const technicalMaxTotalTextBytes = 16 * 1024 * 1024;

  final int maxDepth;
  final int maxTokens;
  final int maxContainerMembers;
  final int maxTextBytes;
  final int maxTotalTextBytes;

  @override
  String toString() =>
      'XelisXswdProjectionLimits(maxDepth=$maxDepth, '
      'maxTokens=$maxTokens, maxContainerMembers=$maxContainerMembers, '
      'maxTextBytes=$maxTextBytes, maxTotalTextBytes=$maxTotalTextBytes)';
}

/// Authored JSON null value.
final class XelisXswdNullValue extends XelisXswdValue {
  const XelisXswdNullValue();

  @override
  String toString() => 'XelisXswdNullValue(redacted)';
}

/// Authored JSON boolean value.
final class XelisXswdBoolValue extends XelisXswdValue {
  const XelisXswdBoolValue(this.value);

  final bool value;

  @override
  String toString() => 'XelisXswdBoolValue(redacted)';
}

/// Authored JSON string value.
final class XelisXswdStringValue extends XelisXswdValue {
  const XelisXswdStringValue(this.value);

  final String value;

  @override
  String toString() => 'XelisXswdStringValue(redacted)';
}

/// Exact authored JSON integer value.
///
/// Native `i64` and `u64` values cross the private bridge as canonical decimal
/// strings and are reconstructed as [BigInt], including on Web.
final class XelisXswdIntegerValue extends XelisXswdValue {
  const XelisXswdIntegerValue(this.value);

  final BigInt value;

  @override
  String toString() => 'XelisXswdIntegerValue(redacted)';
}

/// Authored JSON floating-point value.
///
/// This represents a genuine upstream `f64`, not an integer transport. A
/// consumer expecting an integer authority field must reject this variant.
final class XelisXswdFloatValue extends XelisXswdValue {
  const XelisXswdFloatValue(this.value);

  final double value;

  @override
  String toString() => 'XelisXswdFloatValue(redacted)';
}

/// Deeply immutable authored JSON array.
final class XelisXswdArrayValue extends XelisXswdValue {
  XelisXswdArrayValue(List<XelisXswdValue> values)
    : values = List.unmodifiable(values);

  final List<XelisXswdValue> values;

  @override
  String toString() => 'XelisXswdArrayValue(length=${values.length})';
}

/// Deeply immutable authored JSON object.
final class XelisXswdObjectValue extends XelisXswdValue {
  XelisXswdObjectValue(Map<String, XelisXswdValue> fields)
    : fields = UnmodifiableMapView(Map.of(fields));

  final Map<String, XelisXswdValue> fields;

  @override
  String toString() => 'XelisXswdObjectValue(fieldCount=${fields.length})';
}

/// Authored projection of one application connected through XSWD.
final class XelisXswdApplication {
  XelisXswdApplication({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required Map<String, XelisXswdPermissionPolicy> permissions,
    required this.isRelayer,
  }) : permissions = UnmodifiableMapView(Map.of(permissions));

  final String id;
  final String name;
  final String description;
  final String? url;

  /// Wallet RPC policies keyed by unprefixed method identifiers.
  ///
  /// For example, the balance method is represented as `get_balance`.
  final Map<String, XelisXswdPermissionPolicy> permissions;
  final bool isRelayer;

  @override
  String toString() =>
      'XelisXswdApplication(permissionCount=${permissions.length}, '
      'isRelayer=$isRelayer)';
}

/// Snapshot of the process state owned by one wallet's XSWD integration.
final class XelisXswdState {
  XelisXswdState({
    required this.isRunning,
    required List<XelisXswdApplication> applications,
  }) : applications = List.unmodifiable(applications);

  final bool isRunning;
  final List<XelisXswdApplication> applications;

  @override
  String toString() =>
      'XelisXswdState(isRunning=$isRunning, '
      'applicationCount=${applications.length})';
}

/// Authored XSWD request delivered to a consumer callback.
///
/// [payload] is an object for permission and prefetch-permission requests and
/// is absent for lifecycle notifications. It may contain sensitive request
/// data and must not enter logs, support references, analytics, or toasts.
/// A deliberate permission-review UI may inspect and render the fields needed
/// for informed consent. Redacted [toString] output is only a safe implicit
/// representation: accessing [XelisXswdObjectValue.fields], collection values,
/// or scalar values transfers responsibility to the consumer.
final class XelisXswdRequest {
  const XelisXswdRequest({
    required this.kind,
    required this.application,
    this.payload,
  });

  final XelisXswdRequestKind kind;
  final XelisXswdApplication application;
  final XelisXswdValue? payload;

  bool get isApplicationRequest => kind == XelisXswdRequestKind.application;
  bool get isPermissionRequest => kind == XelisXswdRequestKind.permission;
  bool get isPrefetchPermissionsRequest =>
      kind == XelisXswdRequestKind.prefetchPermissions;
  bool get isCancelRequest => kind == XelisXswdRequestKind.cancel;
  bool get isApplicationDisconnect =>
      kind == XelisXswdRequestKind.applicationDisconnect;

  @override
  String toString() =>
      'XelisXswdRequest(kind=$kind, hasPayload=${payload != null})';
}

/// Supported encryption algorithms for one relayed XSWD session.
enum XelisXswdEncryptionAlgorithm { aes, chacha20Poly1305 }

/// Encryption configuration for one relayed XSWD session.
///
/// The key is copied into an immutable list and deliberately omitted from
/// [toString]. Native validation still requires exactly 32 bytes.
final class XelisXswdEncryption {
  XelisXswdEncryption({required this.algorithm, required List<int> key})
    : key = List.unmodifiable(key);

  final XelisXswdEncryptionAlgorithm algorithm;
  final List<int> key;

  @override
  String toString() => 'XelisXswdEncryption(algorithm=$algorithm, redacted)';
}

/// Authored input used to add one relayed XSWD application.
///
/// This value may originate from a QR code, paste, or deep link. Consumers
/// must parse it as untrusted input and never log the complete source payload.
final class XelisXswdRelayer {
  XelisXswdRelayer({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required List<String> permissions,
    required this.relayer,
    this.encryption,
  }) : permissions = List.unmodifiable(permissions);

  final String id;
  final String name;
  final String description;
  final String? url;

  /// Requested wallet RPC methods in their unprefixed form.
  ///
  /// A prefixed identifier such as `wallet.get_balance` is invalid.
  final List<String> permissions;
  final String relayer;
  final XelisXswdEncryption? encryption;

  @override
  String toString() =>
      'XelisXswdRelayer(permissionCount=${permissions.length}, '
      'encrypted=${encryption != null})';
}

typedef XelisXswdNotificationCallback = FutureOr<void> Function(
  XelisXswdRequest request,
);
typedef XelisXswdDecisionCallback = FutureOr<XelisXswdDecision> Function(
  XelisXswdRequest request,
);

/// Consumer callbacks used by the local XSWD server and relayer handler.
///
/// Generated bridge callback types remain private behind the package adapter.
/// Callback exceptions and timeouts never cross into Rust as arbitrary Dart
/// errors. They become static technical XSWD failures. Only an explicit
/// [XelisXswdDecision.reject] is represented as a user rejection.
final class XelisXswdCallbacks {
  const XelisXswdCallbacks({
    required this.onCancelRequest,
    required this.onApplicationRequest,
    required this.onPermissionRequest,
    required this.onPrefetchPermissionsRequest,
    required this.onApplicationDisconnect,
    this.timeout = const Duration(minutes: 1),
    this.projectionLimits = const XelisXswdProjectionLimits(),
  });

  final XelisXswdNotificationCallback onCancelRequest;
  final XelisXswdDecisionCallback onApplicationRequest;
  final XelisXswdDecisionCallback onPermissionRequest;
  final XelisXswdDecisionCallback onPrefetchPermissionsRequest;
  final XelisXswdNotificationCallback onApplicationDisconnect;

  /// Maximum time a callback may retain the native XSWD event loop.
  final Duration timeout;

  /// Resource budget fixed when these callbacks create the native handler.
  final XelisXswdProjectionLimits projectionLimits;
}
