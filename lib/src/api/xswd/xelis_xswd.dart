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
/// [payloadJson] is present only for permission and prefetch-permission
/// requests. It is an opaque RPC payload owned by the consuming application or
/// its RPC SDK, not a wallet model. It may contain sensitive request data and
/// must not enter logs, support references, analytics, or toasts.
final class XelisXswdRequest {
  const XelisXswdRequest({
    required this.kind,
    required this.application,
    this.payloadJson,
  });

  final XelisXswdRequestKind kind;
  final XelisXswdApplication application;
  final String? payloadJson;

  bool get isApplicationRequest => kind == XelisXswdRequestKind.application;
  bool get isPermissionRequest => kind == XelisXswdRequestKind.permission;
  bool get isPrefetchPermissionsRequest =>
      kind == XelisXswdRequestKind.prefetchPermissions;
  bool get isCancelRequest => kind == XelisXswdRequestKind.cancel;
  bool get isApplicationDisconnect =>
      kind == XelisXswdRequestKind.applicationDisconnect;

  @override
  String toString() =>
      'XelisXswdRequest(kind=$kind, hasPayload=${payloadJson != null})';
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
  final List<String> permissions;
  final String relayer;
  final XelisXswdEncryption? encryption;

  @override
  String toString() =>
      'XelisXswdRelayer(permissionCount=${permissions.length}, '
      'encrypted=${encryption != null})';
}

typedef XelisXswdNotificationCallback =
    FutureOr<void> Function(XelisXswdRequest request);
typedef XelisXswdDecisionCallback =
    FutureOr<XelisXswdDecision> Function(XelisXswdRequest request);

/// Consumer callbacks used by the local XSWD server and relayer handler.
///
/// Generated bridge callback types remain private behind the package adapter.
/// Callback exceptions and timeouts never cross into Rust: notification
/// callbacks are abandoned, while decision callbacks fail closed to
/// [XelisXswdDecision.reject].
final class XelisXswdCallbacks {
  const XelisXswdCallbacks({
    required this.onCancelRequest,
    required this.onApplicationRequest,
    required this.onPermissionRequest,
    required this.onPrefetchPermissionsRequest,
    required this.onApplicationDisconnect,
    this.timeout = const Duration(minutes: 1),
  });

  final XelisXswdNotificationCallback onCancelRequest;
  final XelisXswdDecisionCallback onApplicationRequest;
  final XelisXswdDecisionCallback onPermissionRequest;
  final XelisXswdDecisionCallback onPrefetchPermissionsRequest;
  final XelisXswdNotificationCallback onApplicationDisconnect;

  /// Maximum time a callback may retain the native XSWD event loop.
  final Duration timeout;
}
