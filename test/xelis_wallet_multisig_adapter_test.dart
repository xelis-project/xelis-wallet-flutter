import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_models;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('multisig authored adapter', () {
    test('preserves u64 state and request fields as BigInt', () async {
      final exact = BigInt.parse('18446744073709551615');
      final delegate = _FakeGeneratedMultisigWallet(
        state: generated_models.NativeMultisigState(
          threshold: 2,
          participants: const [
            generated_models.NativeMultisigParticipant(
              id: 0,
              address: 'participant',
            ),
          ],
          topoheight: exact,
        ),
        pendingRequest: _nativeRequest(
          requestId: BigInt.one,
          fee: exact,
          nonce: exact,
          referenceTopoheight: exact,
        ),
      );
      final wallet = NativeXelisWallet(delegate);

      final state = await wallet.getMultisigState();
      final request = await wallet.prepareMultisigBurn(
        asset: 'asset',
        amountAtomic: exact,
      );

      expect(state?.topoheight, exact);
      expect(request.feeAtomic, exact);
      expect(request.nonce, exact);
      expect(request.referenceTopoheight, exact);
      expect(
        (request.transaction as XelisWalletMultisigBurn).amountAtomic,
        exact,
      );
      expect(delegate.preparedBurnAmount, exact);
    });

    test(
      'forwards every multisig preparation variant through authored inputs',
      () async {
        final setup = generated_models.NativePreparedTransaction(
          hash: 'setup-hash',
          preparationId: BigInt.from(3),
          fee: BigInt.from(4),
          transaction:
              const generated_models.NativePreparedTransactionKind.multisigSetup(
                threshold: 2,
                participants: [
                  generated_models.NativeMultisigParticipant(
                    id: 0,
                    address: 'participant-a',
                  ),
                  generated_models.NativeMultisigParticipant(
                    id: 1,
                    address: 'participant-b',
                  ),
                ],
              ),
        );
        final delegate = _FakeGeneratedMultisigWallet(
          pendingRequest: _nativeRequest(requestId: BigInt.one),
          setupPrepared: setup,
          participantAddressValid: true,
        );
        final wallet = NativeXelisWallet(delegate);

        final preparedSetup = await wallet.prepareMultisigSetup(
          threshold: 2,
          participants: ['participant-a', 'participant-b'],
        );
        expect(preparedSetup.feeAtomic, BigInt.from(4));
        expect(delegate.setupArguments?.$1, 2);
        expect(delegate.setupArguments?.$2, ['participant-a', 'participant-b']);
        expect(
          wallet.isMultisigParticipantAddressValid(address: 'participant-a'),
          isTrue,
        );
        expect(delegate.validatedParticipant, 'participant-a');

        await wallet.prepareMultisigTransfers(
          transfers: [
            XelisWalletTransferRequest(
              destination: 'destination',
              asset: 'asset',
              amountAtomic: BigInt.from(5),
              extraData: 'memo',
              encryptExtraData: false,
            ),
          ],
        );
        final transfer = delegate.preparedTransfers!.single;
        expect(transfer.destination, 'destination');
        expect(transfer.asset, 'asset');
        expect(transfer.amount, BigInt.from(5));
        expect(transfer.extraData, 'memo');
        expect(transfer.encryptExtraData, isFalse);

        await wallet.prepareMultisigTransferAll(
          destination: 'destination-all',
          asset: 'asset-all',
          extraData: 'all-memo',
          encryptExtraData: false,
        );
        expect(delegate.transferAllArguments, (
          'destination-all',
          'asset-all',
          'all-memo',
          false,
        ));

        await wallet.prepareMultisigBurnAll(asset: 'asset-burn-all');
        expect(delegate.burnAllAsset, 'asset-burn-all');
      },
    );

    test('rejects reconstructed and cross-wallet pending requests', () async {
      final firstDelegate = _FakeGeneratedMultisigWallet(
        pendingRequest: _nativeRequest(requestId: BigInt.one),
      );
      final secondDelegate = _FakeGeneratedMultisigWallet();
      final firstWallet = NativeXelisWallet(firstDelegate);
      final secondWallet = NativeXelisWallet(secondDelegate);
      final request = await firstWallet.prepareMultisigBurn(
        asset: 'asset',
        amountAtomic: BigInt.one,
      );
      final reconstructed = _copyRequest(request);

      await expectLater(
        firstWallet.cancelMultisigSigningRequest(request: reconstructed),
        throwsA(
          isA<XelisWalletException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletMultisigRequestCancel,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'MULTISIG_REQUEST_CAPABILITY_INVALID',
              ),
        ),
      );
      await expectLater(
        secondWallet.cancelMultisigSigningRequest(request: request),
        throwsA(isA<XelisWalletException>()),
      );
      expect(firstDelegate.cancelCalls, 0);
      expect(secondDelegate.cancelCalls, 0);

      await firstWallet.cancelMultisigSigningRequest(request: request);
      expect(firstDelegate.cancelCalls, 1);
      await expectLater(
        firstWallet.cancelMultisigSigningRequest(request: request),
        throwsA(isA<XelisWalletException>()),
      );
      expect(firstDelegate.cancelCalls, 1);
    });

    test(
      'binds inspected shares to finalization and consumes lifecycle',
      () async {
        final delegate = _FakeGeneratedMultisigWallet(
          pendingRequest: _nativeRequest(requestId: BigInt.from(7)),
          inspectedShare: _nativeShare(),
          finalized: generated_models.NativePreparedTransaction(
            hash: 'prepared-hash',
            preparationId: BigInt.from(9),
            fee: BigInt.from(11),
            transaction:
                const generated_models.NativePreparedTransactionKind.multisigFinalized(
                  transaction: generated_models
                      .NativeMultisigSigningTransaction.deleteMultisig(),
                ),
          ),
        );
        final wallet = NativeXelisWallet(delegate);
        final request = await wallet.prepareMultisigDeletion();
        final share = await wallet.inspectMultisigSignatureShare(
          request: request,
          encoded: 'encoded-share',
        );

        final prepared = await wallet.finalizeMultisigTransaction(
          request: request,
          shares: [share],
        );

        expect(delegate.finalizeCalls, 1);
        expect(delegate.finalizedRequestId, BigInt.from(7));
        expect(delegate.finalizedSigningHash, request.signingHash);
        expect(delegate.finalizedShares, ['encoded-share']);
        expect(prepared.feeAtomic, BigInt.from(11));
        expect(
          (prepared.details as XelisWalletPreparedMultisigTransaction)
              .transaction,
          isA<XelisWalletMultisigDelete>(),
        );

        await expectLater(
          wallet.finalizeMultisigTransaction(request: request, shares: [share]),
          throwsA(isA<XelisWalletException>()),
        );
        expect(delegate.finalizeCalls, 1);
      },
    );

    test('signs only the exact inspected participant request', () async {
      final delegate = _FakeGeneratedMultisigWallet(
        inspectedRequest: _nativeRequest(requestId: null, participantId: 1),
        signedShare: _nativeShare(),
      );
      final wallet = NativeXelisWallet(delegate);
      final request = await wallet.inspectMultisigSigningRequest(
        encoded: 'canonical-request',
      );

      final share = await wallet.signMultisigSigningRequest(request: request);
      expect(share.participantId, 1);
      expect(delegate.signCalls, 1);

      await expectLater(
        wallet.signMultisigSigningRequest(request: _copyRequest(request)),
        throwsA(
          isA<XelisWalletException>().having(
            (error) => error.nativeKind,
            'nativeKind',
            'MULTISIG_INSPECTED_REQUEST_CAPABILITY_INVALID',
          ),
        ),
      );
      expect(delegate.signCalls, 1);
    });
  });
}

generated_models.NativeMultisigSigningRequest _nativeRequest({
  required BigInt? requestId,
  BigInt? fee,
  BigInt? nonce,
  BigInt? referenceTopoheight,
  int? participantId,
}) => generated_models.NativeMultisigSigningRequest(
  requestId: requestId,
  encoded: 'canonical-request',
  signingHash:
      '1111111111111111111111111111111111111111111111111111111111111111',
  source: 'source',
  network: 'testnet',
  fee: fee ?? BigInt.one,
  feeLimit: fee ?? BigInt.one,
  nonce: nonce ?? BigInt.one,
  referenceTopoheight: referenceTopoheight ?? BigInt.one,
  threshold: 1,
  participants: const [
    generated_models.NativeMultisigParticipant(id: 1, address: 'participant'),
  ],
  signerId: participantId,
  transaction: generated_models.NativeMultisigSigningTransaction.burn(
    asset: 'asset',
    amount: fee ?? BigInt.one,
  ),
);

generated_models.NativeMultisigSignatureShare _nativeShare() =>
    const generated_models.NativeMultisigSignatureShare(
      encoded: 'encoded-share',
      signingHash:
          '1111111111111111111111111111111111111111111111111111111111111111',
      signerId: 1,
      signature: 'signature',
    );

XelisWalletMultisigSigningRequest _copyRequest(
  XelisWalletMultisigSigningRequest request,
) => XelisWalletMultisigSigningRequest(
  encoded: request.encoded,
  signingHash: request.signingHash,
  source: request.source,
  network: request.network,
  feeAtomic: request.feeAtomic,
  feeLimitAtomic: request.feeLimitAtomic,
  nonce: request.nonce,
  referenceTopoheight: request.referenceTopoheight,
  threshold: request.threshold,
  participants: request.participants,
  participantId: request.participantId,
  transaction: request.transaction,
);

final class _FakeGeneratedMultisigWallet
    implements generated_wallet.XelisWallet {
  _FakeGeneratedMultisigWallet({
    this.state,
    this.pendingRequest,
    this.inspectedRequest,
    this.inspectedShare,
    this.signedShare,
    this.finalized,
    this.setupPrepared,
    this.participantAddressValid = false,
  });

  final generated_models.NativeMultisigState? state;
  final generated_models.NativeMultisigSigningRequest? pendingRequest;
  final generated_models.NativeMultisigSigningRequest? inspectedRequest;
  final generated_models.NativeMultisigSignatureShare? inspectedShare;
  final generated_models.NativeMultisigSignatureShare? signedShare;
  final generated_models.NativePreparedTransaction? finalized;
  final generated_models.NativePreparedTransaction? setupPrepared;
  final bool participantAddressValid;

  BigInt? preparedBurnAmount;
  (int, List<String>)? setupArguments;
  String? validatedParticipant;
  List<generated_models.NativeTransactionTransferRequest>? preparedTransfers;
  (String, String?, String?, bool?)? transferAllArguments;
  String? burnAllAsset;
  var cancelCalls = 0;
  var finalizeCalls = 0;
  var signCalls = 0;
  BigInt? finalizedRequestId;
  String? finalizedSigningHash;
  List<String>? finalizedShares;

  @override
  bool get isDisposed => false;

  @override
  Future<generated_models.NativeMultisigState?> getMultisigState() async =>
      state;

  @override
  Future<generated_models.NativeMultisigSigningRequest>
  createMultisigBurnTransaction({
    required BigInt amount,
    required String assetHash,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    preparedBurnAmount = amount;
    return pendingRequest!;
  }

  @override
  Future<generated_models.NativePreparedTransaction> multisigSetup({
    required int threshold,
    required List<String> participants,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    setupArguments = (threshold, participants);
    return setupPrepared!;
  }

  @override
  bool isAddressValidForMultisig({required String address}) {
    validatedParticipant = address;
    return participantAddressValid;
  }

  @override
  Future<generated_models.NativeMultisigSigningRequest>
  createMultisigTransfersTransaction({
    required List<generated_models.NativeTransactionTransferRequest> transfers,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    preparedTransfers = transfers;
    return pendingRequest!;
  }

  @override
  Future<generated_models.NativeMultisigSigningRequest>
  createMultisigTransferAllTransaction({
    required String strAddress,
    String? assetHash,
    String? extraData,
    bool? encryptExtraData,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    transferAllArguments = (strAddress, assetHash, extraData, encryptExtraData);
    return pendingRequest!;
  }

  @override
  Future<generated_models.NativeMultisigSigningRequest>
  createMultisigBurnAllTransaction({
    required String assetHash,
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async {
    burnAllAsset = assetHash;
    return pendingRequest!;
  }

  @override
  Future<generated_models.NativeMultisigSigningRequest> initDeleteMultisig({
    required generated_models.NativeTransactionFeePolicy feePolicy,
  }) async => pendingRequest!;

  @override
  void cancelPendingMultisigRequest({
    required BigInt requestId,
    required String signingHash,
  }) {
    cancelCalls++;
  }

  @override
  Future<generated_models.NativeMultisigSignatureShare>
  inspectMultisigSignatureShare({
    required BigInt requestId,
    required String signingHash,
    required String encoded,
  }) async => inspectedShare!;

  @override
  Future<generated_models.NativePreparedTransaction>
  finalizeMultisigTransaction({
    required BigInt requestId,
    required String signingHash,
    required List<String> signatureShares,
  }) async {
    finalizeCalls++;
    finalizedRequestId = requestId;
    finalizedSigningHash = signingHash;
    finalizedShares = signatureShares;
    return finalized!;
  }

  @override
  Future<generated_models.NativeMultisigSigningRequest>
  inspectMultisigSigningRequest({required String encoded}) async =>
      inspectedRequest!;

  @override
  Future<generated_models.NativeMultisigSignatureShare>
  signMultisigSigningRequest({required String encoded}) async {
    signCalls++;
    return signedShare!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
