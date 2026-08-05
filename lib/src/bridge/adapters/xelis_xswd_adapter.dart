import 'dart:async';
import 'dart:typed_data';

import '../../api/errors/xelis_wallet_exception.dart';
import '../../api/xswd/xelis_xswd.dart';
import '../../generated/rust_bridge/api/models/xswd_dtos.dart' as generated;
import 'xelis_error_adapter.dart';

XelisXswdApplication xelisXswdApplicationFromGenerated(
  generated.AppInfo application,
) => XelisXswdApplication(
  id: application.id,
  name: application.name,
  description: application.description,
  url: application.url,
  permissions: application.permissions.map(
    (name, policy) => MapEntry(name, _permissionPolicyFromGenerated(policy)),
  ),
  isRelayer: application.isRelayer,
);

XelisXswdRequest xelisXswdRequestFromGenerated(
  generated.XswdRequestSummary request,
) {
  final (kind, payloadJson) = switch (request.eventType) {
    generated.XswdRequestType_Application() => (
      XelisXswdRequestKind.application,
      null,
    ),
    generated.XswdRequestType_Permission(:final field0) => (
      XelisXswdRequestKind.permission,
      field0,
    ),
    generated.XswdRequestType_PrefetchPermissions(:final field0) => (
      XelisXswdRequestKind.prefetchPermissions,
      field0,
    ),
    generated.XswdRequestType_CancelRequest() => (
      XelisXswdRequestKind.cancel,
      null,
    ),
    generated.XswdRequestType_AppDisconnect() => (
      XelisXswdRequestKind.applicationDisconnect,
      null,
    ),
  };

  return XelisXswdRequest(
    kind: kind,
    application: xelisXswdApplicationFromGenerated(request.applicationInfo),
    payloadJson: payloadJson,
  );
}

Map<String, generated.PermissionPolicy> generatedXswdPermissionsFromXelis(
  Map<String, XelisXswdPermissionPolicy> permissions,
) => permissions.map(
  (name, policy) => MapEntry(name, _permissionPolicyToGenerated(policy)),
);

generated.ApplicationDataRelayer generatedXswdRelayerFromXelis(
  XelisXswdRelayer relayer, {
  required XelisWalletOperation operation,
}) => generated.ApplicationDataRelayer(
  id: relayer.id,
  name: relayer.name,
  description: relayer.description,
  url: relayer.url,
  permissions: List.of(relayer.permissions),
  relayer: relayer.relayer,
  encryptionMode: _encryptionToGenerated(
    relayer.encryption,
    operation: operation,
  ),
);

/// Private generated callback bundle used only by bridge adapters.
final class GeneratedXswdCallbacks {
  const GeneratedXswdCallbacks({
    required this.cancelRequest,
    required this.applicationRequest,
    required this.permissionRequest,
    required this.prefetchPermissionsRequest,
    required this.applicationDisconnect,
  });

  final Future<void> Function(generated.XswdRequestSummary) cancelRequest;
  final Future<generated.UserPermissionDecision> Function(
    generated.XswdRequestSummary,
  )
  applicationRequest;
  final Future<generated.UserPermissionDecision> Function(
    generated.XswdRequestSummary,
  )
  permissionRequest;
  final Future<generated.UserPermissionDecision> Function(
    generated.XswdRequestSummary,
  )
  prefetchPermissionsRequest;
  final Future<void> Function(generated.XswdRequestSummary)
  applicationDisconnect;
}

GeneratedXswdCallbacks generatedXswdCallbacksFromXelis(
  XelisXswdCallbacks callbacks,
) => GeneratedXswdCallbacks(
  cancelRequest: (request) => _runNotificationCallback(
    callbacks.onCancelRequest,
    request,
    timeout: callbacks.timeout,
  ),
  applicationRequest: (request) => _runDecisionCallback(
    callbacks.onApplicationRequest,
    request,
    timeout: callbacks.timeout,
  ),
  permissionRequest: (request) => _runDecisionCallback(
    callbacks.onPermissionRequest,
    request,
    timeout: callbacks.timeout,
  ),
  prefetchPermissionsRequest: (request) => _runDecisionCallback(
    callbacks.onPrefetchPermissionsRequest,
    request,
    timeout: callbacks.timeout,
  ),
  applicationDisconnect: (request) => _runNotificationCallback(
    callbacks.onApplicationDisconnect,
    request,
    timeout: callbacks.timeout,
  ),
);

Future<void> _runNotificationCallback(
  XelisXswdNotificationCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
}) async {
  try {
    await Future<void>.sync(
      () => callback(xelisXswdRequestFromGenerated(request)),
    ).timeout(timeout);
  } catch (_) {
    // Consumer callbacks are outside the package trust boundary. Never let an
    // arbitrary Dart exception cross through FRB or retain its payload.
  }
}

Future<generated.UserPermissionDecision> _runDecisionCallback(
  XelisXswdDecisionCallback callback,
  generated.XswdRequestSummary request, {
  required Duration timeout,
}) async {
  try {
    final decision = await Future<XelisXswdDecision>.sync(
      () => callback(xelisXswdRequestFromGenerated(request)),
    ).timeout(timeout);
    return _decisionToGenerated(decision);
  } catch (_) {
    // A failed or stalled consumer must fail closed without sending its
    // exception or the external request payload through native diagnostics.
    return generated.UserPermissionDecision.reject;
  }
}

XelisXswdPermissionPolicy _permissionPolicyFromGenerated(
  generated.PermissionPolicy policy,
) => switch (policy) {
  generated.PermissionPolicy.ask => XelisXswdPermissionPolicy.ask,
  generated.PermissionPolicy.accept => XelisXswdPermissionPolicy.accept,
  generated.PermissionPolicy.reject => XelisXswdPermissionPolicy.reject,
};

generated.PermissionPolicy _permissionPolicyToGenerated(
  XelisXswdPermissionPolicy policy,
) => switch (policy) {
  XelisXswdPermissionPolicy.ask => generated.PermissionPolicy.ask,
  XelisXswdPermissionPolicy.accept => generated.PermissionPolicy.accept,
  XelisXswdPermissionPolicy.reject => generated.PermissionPolicy.reject,
};

generated.UserPermissionDecision _decisionToGenerated(
  XelisXswdDecision decision,
) => switch (decision) {
  XelisXswdDecision.accept => generated.UserPermissionDecision.accept,
  XelisXswdDecision.reject => generated.UserPermissionDecision.reject,
  XelisXswdDecision.alwaysAccept =>
    generated.UserPermissionDecision.alwaysAccept,
  XelisXswdDecision.alwaysReject =>
    generated.UserPermissionDecision.alwaysReject,
};

generated.EncryptionMode? _encryptionToGenerated(
  XelisXswdEncryption? encryption, {
  required XelisWalletOperation operation,
}) {
  if (encryption == null) {
    return null;
  }
  if (encryption.key.length != 32 ||
      encryption.key.any((byte) => byte < 0 || byte > 255)) {
    throw xelisOperationPreconditionException(
      operation: operation,
      code: XelisWalletErrorCode.invalidInput,
      nativeKind: 'XSWD_ENCRYPTION_KEY_INVALID',
      diagnosticMessage: 'An XSWD encryption key must contain 32 bytes.',
    );
  }

  final key = Uint8List.fromList(encryption.key);
  return switch (encryption.algorithm) {
    XelisXswdEncryptionAlgorithm.aes => generated.EncryptionMode.aes(key: key),
    XelisXswdEncryptionAlgorithm.chacha20Poly1305 =>
      generated.EncryptionMode.chacha20Poly1305(key: key),
  };
}
