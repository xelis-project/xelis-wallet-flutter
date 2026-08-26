import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/xswd_dtos.dart'
    as generated_models;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('authored XSWD facade', () {
    test('maps lifecycle state, sessions, permissions, and relayers', () async {
      final delegate = _FakeGeneratedXswdWallet(
        applications: [_generatedApplication()],
      );
      final wallet = NativeXelisWallet(delegate);
      final callbacks = _callbacks();

      await wallet.startXswd(callbacks: callbacks);
      await wallet.startXswd(callbacks: callbacks);
      expect(delegate.startCalls, 2);

      final state = await wallet.getXswdState();
      expect(state.isRunning, isTrue);
      expect(state.applications, hasLength(1));
      expect(state.applications.single.id, 'application-id');
      expect(
        state.applications.single.permissions['get_balance'],
        XelisXswdPermissionPolicy.ask,
      );
      expect(state.toString(), isNot(contains('application-id')));

      await wallet.updateXswdApplicationPermissions(
        applicationId: 'application-id',
        permissions: const {'get_balance': XelisXswdPermissionPolicy.accept},
      );
      expect(delegate.lastPermissions, {
        'get_balance': generated_models.PermissionPolicy.accept,
      });

      await wallet.closeXswdApplicationSession(applicationId: 'application-id');
      expect(delegate.closedApplicationId, 'application-id');

      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: 'relay-description',
        url: null,
        permissions: const ['get_balance'],
        relayer: 'wss://relay.example',
        encryption: XelisXswdEncryption(
          algorithm: XelisXswdEncryptionAlgorithm.aes,
          key: List.filled(32, 7),
        ),
      );
      await wallet.addXswdRelayer(relayer: relayer, callbacks: callbacks);
      expect(delegate.lastRelayer?.id, 'relay-id');
      expect(delegate.lastRelayer?.encryptionMode, isNotNull);
      expect(relayer.toString(), isNot(contains('relay-id')));
      expect(relayer.toString(), isNot(contains('wss://')));
      expect(relayer.encryption.toString(), isNot(contains('7')));

      await wallet.stopXswd();
      await wallet.stopXswd();
      expect(delegate.stopCalls, 2);
    });

    test('adapts generated callbacks and redacts request payloads', () async {
      late XelisXswdRequest received;
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      final callbacks = _callbacks(
        onPermissionRequest: (request) {
          received = request;
          return XelisXswdDecision.alwaysAccept;
        },
      );

      await wallet.startXswd(callbacks: callbacks);
      final decision = await delegate.permissionCallback!(
        _generatedRequest(
          const generated_models.XswdRequestType.permission(
            '{"method":"wallet.sign","secret":"payload"}',
          ),
        ),
      );

      expect(decision, generated_models.UserPermissionDecision.alwaysAccept);
      expect(received.kind, XelisXswdRequestKind.permission);
      expect(received.application.id, 'application-id');
      expect(received.payloadJson, contains('wallet.sign'));
      expect(received.toString(), isNot(contains('wallet.sign')));
      expect(received.toString(), isNot(contains('payload')));
    });

    test('fails callback exceptions and timeouts closed', () async {
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      await wallet.startXswd(
        callbacks: _callbacks(
          timeout: Duration.zero,
          onCancelRequest: (_) => throw StateError('sensitive callback data'),
          onPermissionRequest: (_) => Completer<XelisXswdDecision>().future,
        ),
      );

      await expectLater(
        delegate.cancelCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.cancelRequest(),
          ),
        ),
        completes,
      );
      expect(
        await delegate.permissionCallback!(
          _generatedRequest(
            const generated_models.XswdRequestType.permission('secret'),
          ),
        ),
        generated_models.UserPermissionDecision.reject,
      );
    });

    test('rejects invalid relayer keys before the generated call', () async {
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);
      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: '',
        url: null,
        permissions: const [],
        relayer: 'wss://relay.example',
        encryption: XelisXswdEncryption(
          algorithm: XelisXswdEncryptionAlgorithm.aes,
          key: const [1, 2, 3],
        ),
      );

      await expectLater(
        wallet.addXswdRelayer(relayer: relayer, callbacks: _callbacks()),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdRelayerAdd,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              ),
        ),
      );
      expect(delegate.relayerCalls, 0);
    });

    test('rejects prefixed permission names before generated calls', () async {
      final delegate = _FakeGeneratedXswdWallet();
      final wallet = NativeXelisWallet(delegate);

      await expectLater(
        wallet.updateXswdApplicationPermissions(
          applicationId: 'application-id',
          permissions: const {
            'wallet.get_balance': XelisXswdPermissionPolicy.accept,
          },
        ),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdPermissionsUpdate,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'XSWD_PERMISSION_NAME_INVALID',
              ),
        ),
      );
      expect(delegate.lastPermissions, isNull);

      final relayer = XelisXswdRelayer(
        id: 'relay-id',
        name: 'relay-name',
        description: '',
        url: null,
        permissions: const ['wallet.get_balance'],
        relayer: 'wss://relay.example',
      );
      await expectLater(
        wallet.addXswdRelayer(relayer: relayer, callbacks: _callbacks()),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletXswdRelayerAdd,
              )
              .having(
                (error) => error.code,
                'code',
                XelisWalletErrorCode.invalidInput,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'XSWD_PERMISSION_NAME_INVALID',
              ),
        ),
      );
      expect(delegate.relayerCalls, 0);
    });

    test('authors an exact operation for every generated failure', () async {
      final failure = AnyhowException('sensitive XSWD diagnostic payload');

      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(startFailure: failure),
        ),
        call: (wallet) => wallet.startXswd(callbacks: _callbacks()),
        operation: XelisWalletOperation.walletXswdStart,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(running: true, stopFailure: failure),
        ),
        call: (wallet) => wallet.stopXswd(),
        operation: XelisWalletOperation.walletXswdStop,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(running: true, stateFailure: failure),
        ),
        call: (wallet) async {
          await wallet.getXswdState();
        },
        operation: XelisWalletOperation.walletXswdStateRead,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(relayerFailure: failure),
        ),
        call: (wallet) => wallet.addXswdRelayer(
          relayer: XelisXswdRelayer(
            id: 'id',
            name: 'name',
            description: '',
            url: null,
            permissions: const [],
            relayer: 'wss://relay.example',
          ),
          callbacks: _callbacks(),
        ),
        operation: XelisWalletOperation.walletXswdRelayerAdd,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(sessionFailure: failure),
        ),
        call: (wallet) =>
            wallet.closeXswdApplicationSession(applicationId: 'id'),
        operation: XelisWalletOperation.walletXswdSessionClose,
      );
      await _expectXswdOperation(
        wallet: NativeXelisWallet(
          _FakeGeneratedXswdWallet(permissionsFailure: failure),
        ),
        call: (wallet) => wallet.updateXswdApplicationPermissions(
          applicationId: 'id',
          permissions: const {},
        ),
        operation: XelisWalletOperation.walletXswdPermissionsUpdate,
      );
    });
  });
}

Future<void> _expectXswdOperation({
  required NativeXelisWallet wallet,
  required Future<void> Function(NativeXelisWallet wallet) call,
  required XelisWalletOperation operation,
}) async {
  try {
    await call(wallet);
    fail('XSWD operation should throw');
  } on XelisWalletException catch (error) {
    expect(error.operation, operation);
    expect(error.code, XelisWalletErrorCode.operationFailed);
    expect(error.toString(), isNot(contains('sensitive')));
    expect(error.toString(), isNot(contains('payload')));
  }
}

XelisXswdCallbacks _callbacks({
  Duration timeout = const Duration(minutes: 1),
  XelisXswdNotificationCallback? onCancelRequest,
  XelisXswdDecisionCallback? onPermissionRequest,
}) => XelisXswdCallbacks(
  timeout: timeout,
  onCancelRequest: onCancelRequest ?? (_) async {},
  onApplicationRequest: (_) async => XelisXswdDecision.accept,
  onPermissionRequest:
      onPermissionRequest ?? (_) async => XelisXswdDecision.accept,
  onPrefetchPermissionsRequest: (_) async => XelisXswdDecision.accept,
  onApplicationDisconnect: (_) async {},
);

generated_models.AppInfo _generatedApplication() =>
    const generated_models.AppInfo(
      id: 'application-id',
      name: 'application-name',
      description: 'application-description',
      url: 'https://application.example',
      permissions: {'get_balance': generated_models.PermissionPolicy.ask},
      isRelayer: false,
    );

generated_models.XswdRequestSummary _generatedRequest(
  generated_models.XswdRequestType type,
) => generated_models.XswdRequestSummary(
  eventType: type,
  applicationInfo: _generatedApplication(),
);

final class _FakeGeneratedXswdWallet implements generated_wallet.XelisWallet {
  _FakeGeneratedXswdWallet({
    this.running = false,
    this.applications = const [],
    this.startFailure,
    this.stopFailure,
    this.stateFailure,
    this.relayerFailure,
    this.sessionFailure,
    this.permissionsFailure,
  });

  bool running;
  final List<generated_models.AppInfo> applications;
  final Object? startFailure;
  final Object? stopFailure;
  final Object? stateFailure;
  final Object? relayerFailure;
  final Object? sessionFailure;
  final Object? permissionsFailure;

  var startCalls = 0;
  var stopCalls = 0;
  var relayerCalls = 0;
  String? closedApplicationId;
  Map<String, generated_models.PermissionPolicy>? lastPermissions;
  generated_models.ApplicationDataRelayer? lastRelayer;
  FutureOr<void> Function(generated_models.XswdRequestSummary)? cancelCallback;
  FutureOr<generated_models.UserPermissionDecision> Function(
    generated_models.XswdRequestSummary,
  )?
  permissionCallback;

  @override
  bool get isDisposed => false;

  @override
  Future<bool> isXswdRunning() async => running;

  @override
  Future<void> startXswd({
    required FutureOr<void> Function(generated_models.XswdRequestSummary)
    cancelRequestDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestApplicationDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestPermissionDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestPrefetchPermissionsDartCallback,
    required FutureOr<void> Function(generated_models.XswdRequestSummary)
    appDisconnectDartCallback,
  }) async {
    startCalls++;
    if (startFailure case final error?) throw error;
    cancelCallback = cancelRequestDartCallback;
    permissionCallback = requestPermissionDartCallback;
    running = true;
  }

  @override
  Future<void> stopXswd() async {
    stopCalls++;
    if (stopFailure case final error?) throw error;
    running = false;
  }

  @override
  Future<List<generated_models.AppInfo>> getApplicationPermissions() async {
    if (stateFailure case final error?) throw error;
    return applications;
  }

  @override
  Future<void> addXswdRelayer({
    required generated_models.ApplicationDataRelayer appData,
    required FutureOr<void> Function(generated_models.XswdRequestSummary)
    cancelRequestDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestApplicationDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestPermissionDartCallback,
    required FutureOr<generated_models.UserPermissionDecision> Function(
      generated_models.XswdRequestSummary,
    )
    requestPrefetchPermissionsDartCallback,
    required FutureOr<void> Function(generated_models.XswdRequestSummary)
    appDisconnectDartCallback,
  }) async {
    relayerCalls++;
    if (relayerFailure case final error?) throw error;
    lastRelayer = appData;
  }

  @override
  Future<void> closeApplicationSession({required String id}) async {
    if (sessionFailure case final error?) throw error;
    closedApplicationId = id;
  }

  @override
  Future<void> modifyApplicationPermissions({
    required String id,
    required Map<String, generated_models.PermissionPolicy> permissions,
  }) async {
    if (permissionsFailure case final error?) throw error;
    lastPermissions = permissions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
