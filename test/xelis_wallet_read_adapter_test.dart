import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_business_event_adapter.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/error.dart'
    as generated_error;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_dtos.dart'
    as generated_address;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/business_event_dtos.dart'
    as generated_event;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/wallet_dtos.dart'
    as generated_models;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  final huge = BigInt.parse('18446744073709551615');

  test('history filter forwards the authored destination', () {
    const destination = XelisAddressDescriptor(
      encodedAddress: 'xel:integrated-address',
      baseAddress: 'xel:base-address',
      networkClass: XelisAddressNetworkClass.nonMainnet,
      integratedData: XelisDataElement.value(XelisDataValue.string('memo')),
    );

    expect(
      XelisWalletHistoryFilter(
        page: BigInt.one,
        destination: destination,
      ).encodedAddress,
      destination.encodedAddress,
    );
  });

  test(
    'read façade preserves atomic balances and typed asset metadata',
    () async {
      final metadata = generated_models.XelisAssetMetadata(
        name: 'Maximum asset',
        ticker: 'MAX',
        decimals: 8,
        maxSupply: generated_models.XelisMaxSupplyMode.mintable(huge),
        owner: generated_models.XelisAssetOwner.creator(
          contract: 'contract-hash',
          id: huge,
        ),
      );
      final delegate = _ReadGeneratedWallet(
        xelisBalance: huge,
        trackedBalances: {'asset-hash': huge},
        knownAssets: {'asset-hash': metadata},
        metadata: metadata,
      );
      final wallet = NativeXelisWallet(delegate);

      expect(await wallet.getXelisBalance(), huge);
      final balances = await wallet.getTrackedBalances();
      expect(balances, {'asset-hash': huge});
      expect(() => balances['other'] = BigInt.zero, throwsUnsupportedError);

      final assets = await wallet.getKnownAssets();
      final asset = assets['asset-hash']!;
      expect(asset.name, 'Maximum asset');
      expect((asset.maxSupply as XelisWalletMintableMaxSupply).amount, huge);
      expect((asset.owner as XelisWalletAssetCreator).id, huge);
      expect(() => assets['other'] = asset, throwsUnsupportedError);

      expect(
        (await wallet.getAssetMetadata(asset: 'asset-hash')).ticker,
        'MAX',
      );
      expect(await wallet.trackAsset(asset: 'asset-hash'), isTrue);
      expect(await wallet.untrackAsset(asset: 'asset-hash'), isTrue);
      expect(delegate.trackedAsset, 'asset-hash');
      expect(delegate.untrackedAsset, 'asset-hash');
    },
  );

  test(
    'explicit history preserves typed payloads and forwards every filter',
    () async {
      final extraData = generated_event.NativeWalletExtraData(
        flag: generated_event.NativeWalletExtraDataFlag.private,
        hasPayload: true,
        payload: const generated_address.NativeXelisDataElement.value(
          value: generated_address.NativeXelisDataValue.stringValue(
            value: 'private application payload',
          ),
        ),
        payloadKind: generated_event.NativeWalletExtraDataPayloadKind.blob,
      );
      final entry = generated_event.NativeWalletTransactionEntryData.incoming(
        from: 'xel:source',
        transfers: [
          generated_event.NativeWalletTransferIn(
            asset: 'asset-hash',
            amount: huge,
            extraData: extraData,
          ),
        ],
      );
      final delegate = _ReadGeneratedWallet(
        historyCount: huge,
        historyEntries: [
          generated_event.NativeWalletTransactionEntry(
            hash: 'confirmed-hash',
            topoheight: huge,
            timestampMillis: huge,
            entry: entry,
          ),
        ],
        pendingEntries: [
          generated_event.NativeWalletPendingTransaction(
            hash: 'pending-hash',
            timestampMillis: huge,
            entry: entry,
          ),
        ],
      );
      final wallet = NativeXelisWallet(delegate);
      const destination = XelisAddressDescriptor(
        encodedAddress: 'xel:integrated-address',
        baseAddress: 'xel:address',
        networkClass: XelisAddressNetworkClass.nonMainnet,
        integratedData: XelisDataElement.value(
          XelisDataValue.string('payment-reference'),
        ),
      );
      final filter = XelisWalletHistoryFilter(
        page: BigInt.two,
        limit: BigInt.from(25),
        assetHash: 'asset-hash',
        destination: destination,
        minTopoheight: BigInt.from(3),
        maxTopoheight: BigInt.from(4),
        acceptIncoming: true,
        acceptOutgoing: false,
        acceptCoinbase: false,
        acceptBurn: true,
        acceptBlob: false,
        minTimestampMillis: BigInt.from(5),
        maxTimestampMillis: BigInt.from(6),
      );

      expect(await wallet.getHistoryCount(), huge);
      final history = await wallet.history(
        filter: filter,
        extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
      );
      final pending = await wallet.pendingTransactions(
        extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
      );

      final mappedFilter = delegate.lastFilter!;
      expect(mappedFilter.page, BigInt.two);
      expect(mappedFilter.limit, BigInt.from(25));
      expect(mappedFilter.assetHash, 'asset-hash');
      expect(mappedFilter.address, destination.encodedAddress);
      expect(mappedFilter.minTopoheight, BigInt.from(3));
      expect(mappedFilter.maxTopoheight, BigInt.from(4));
      expect(mappedFilter.acceptIncoming, isTrue);
      expect(mappedFilter.acceptOutgoing, isFalse);
      expect(mappedFilter.acceptCoinbase, isFalse);
      expect(mappedFilter.acceptBurn, isTrue);
      expect(mappedFilter.acceptBlob, isFalse);
      expect(mappedFilter.minTimestamp, BigInt.from(5));
      expect(mappedFilter.maxTimestamp, BigInt.from(6));
      expect(
        delegate.lastHistoryExtraDataDisclosure,
        generated_event.NativeWalletExtraDataDisclosure.detailed,
      );
      expect(
        delegate.lastPendingExtraDataDisclosure,
        generated_event.NativeWalletExtraDataDisclosure.detailed,
      );

      final historyExtra = (history.single.entry as XelisWalletIncomingEntry)
          .transfers
          .single
          .extraData!;
      final pendingExtra = (pending.single.entry as XelisWalletIncomingEntry)
          .transfers
          .single
          .extraData!;
      expect(history.single.topoheight, huge);
      expect(
        historyExtra.payload,
        const XelisDataElement.value(
          XelisDataValue.string('private application payload'),
        ),
      );
      expect(pendingExtra.payload, historyExtra.payload);
      expect(historyExtra.payloadKind, XelisWalletExtraDataPayloadKind.blob);
      expect(pendingExtra.payloadKind, XelisWalletExtraDataPayloadKind.blob);
      expect(historyExtra.toString(), isNot(contains('private application')));
    },
  );

  test('CSV operations use the authored filter and exact boundaries', () async {
    final delegate = _ReadGeneratedWallet(csv: 'hash,amount\nabc,1\n');
    final wallet = NativeXelisWallet(delegate);
    final filter = XelisWalletHistoryFilter(
      page: BigInt.one,
      assetHash: 'asset-hash',
      acceptIncoming: false,
      maxTimestampMillis: BigInt.from(42),
    );

    expect(
      await wallet.convertTransactionsToCsv(filter: filter),
      'hash,amount\nabc,1\n',
    );
    await wallet.exportTransactionsToCsvFile(
      filePath: r'C:\private\exports\history.csv',
      filter: filter,
    );

    expect(delegate.lastCsvConversionFilter?.assetHash, 'asset-hash');
    expect(delegate.lastCsvConversionFilter?.acceptIncoming, isFalse);
    expect(delegate.lastCsvFileExportFilter?.maxTimestamp, BigInt.from(42));
    expect(delegate.lastCsvFileExportPath, r'C:\private\exports\history.csv');
    expect(
      XelisWalletOperation.walletHistoryCsvConvert.id,
      'wallet.history.csv.convert',
    );
    expect(
      XelisWalletOperation.walletHistoryCsvExport.id,
      'wallet.history.csv.export',
    );
  });

  test('CSV path diagnostics stay outside the safe exception text', () async {
    final delegate = _ReadGeneratedWallet(
      csvError: const generated_error.NativeXelisError(
        version: XelisWalletErrorContract.currentVersion,
        source: generated_error.NativeXelisErrorSource.xelisWalletFlutter,
        code: generated_error.NativeXelisErrorCode.storage,
        nativeKind: 'WALLET_HISTORY_CSV_TEMP_FILE_CREATE_FAILED',
        diagnosticMessage: r'path=C:\private\exports\history.csv',
      ),
    );
    final wallet = NativeXelisWallet(delegate);

    try {
      await wallet.exportTransactionsToCsvFile(
        filePath: r'C:\private\exports\history.csv',
        filter: XelisWalletHistoryFilter(page: BigInt.one),
      );
      fail('exportTransactionsToCsvFile should throw');
    } on XelisWalletException catch (error) {
      expect(error.operation, XelisWalletOperation.walletHistoryCsvExport);
      expect(error.code, XelisWalletErrorCode.storageFailure);
      expect(error.diagnosticMessage, contains(r'C:\private\exports'));
      expect(error.toString(), isNot(contains('private')));
    }
  });

  test(
    'detail reads forward hash and disclosure without rebuilding entries',
    () async {
      final confirmed = generated_event.NativeWalletTransactionEntry(
        hash: 'confirmed-hash',
        topoheight: BigInt.from(7),
        timestampMillis: BigInt.from(8),
        entry: generated_event.NativeWalletTransactionEntryData.coinbase(
          reward: BigInt.one,
        ),
      );
      final pending = generated_event.NativeWalletPendingTransaction(
        hash: 'pending-hash',
        timestampMillis: BigInt.from(9),
        entry: generated_event.NativeWalletTransactionEntryData.coinbase(
          reward: BigInt.two,
        ),
      );
      final delegate = _ReadGeneratedWallet(
        detailEntry: confirmed,
        pendingDetailEntry: pending,
      );
      final wallet = NativeXelisWallet(delegate);

      final confirmedResult = await wallet.transactionByHash(
        hash: 'confirmed-hash',
        extraDataDisclosure: XelisWalletExtraDataDisclosure.metadata,
      );
      final pendingResult = await wallet.pendingTransactionByHash(
        hash: 'pending-hash',
      );

      expect(confirmedResult.hash, 'confirmed-hash');
      expect(pendingResult.hash, 'pending-hash');
      expect(delegate.detailArguments, (
        'confirmed-hash',
        generated_event.NativeWalletExtraDataDisclosure.metadata,
      ));
      expect(delegate.pendingDetailArguments, (
        'pending-hash',
        generated_event.NativeWalletExtraDataDisclosure.detailed,
      ));
    },
  );

  test(
    'every read applies all three disclosure levels to its output',
    () async {
      final confirmed = _overinformativeConfirmedTransaction();
      final pending = _overinformativePendingTransaction();
      final delegate = _ReadGeneratedWallet(
        historyEntries: [confirmed],
        pendingEntries: [pending],
        detailEntry: confirmed,
        pendingDetailEntry: pending,
      );
      final wallet = NativeXelisWallet(delegate);
      final cases = [
        (
          XelisWalletExtraDataDisclosure.redacted,
          generated_event.NativeWalletExtraDataDisclosure.redacted,
        ),
        (
          XelisWalletExtraDataDisclosure.metadata,
          generated_event.NativeWalletExtraDataDisclosure.metadata,
        ),
        (
          XelisWalletExtraDataDisclosure.detailed,
          generated_event.NativeWalletExtraDataDisclosure.detailed,
        ),
      ];

      for (final (authored, generated) in cases) {
        final history = await wallet.history(
          filter: XelisWalletHistoryFilter(page: BigInt.one),
          extraDataDisclosure: authored,
        );
        final pendingTransactions = await wallet.pendingTransactions(
          extraDataDisclosure: authored,
        );
        final detail = await wallet.transactionByHash(
          hash: 'confirmed-hash',
          extraDataDisclosure: authored,
        );
        final pendingDetail = await wallet.pendingTransactionByHash(
          hash: 'pending-hash',
          extraDataDisclosure: authored,
        );

        for (final extraData in [
          _confirmedExtraData(history.single),
          _pendingExtraData(pendingTransactions.single),
          _confirmedExtraData(detail),
          _pendingExtraData(pendingDetail),
        ]) {
          _expectExtraDataDisclosure(extraData, authored);
        }
        expect(delegate.lastHistoryExtraDataDisclosure, generated);
        expect(delegate.lastPendingExtraDataDisclosure, generated);
        expect(delegate.detailArguments, ('confirmed-hash', generated));
        expect(delegate.pendingDetailArguments, ('pending-hash', generated));
      }
    },
  );

  test(
    'read operations have exact identifiers and preserve native errors',
    () async {
      expect(
        XelisWalletOperation.walletBalanceRead.id,
        'wallet.balance.xelis.read',
      );
      expect(
        XelisWalletOperation.walletTrackedBalancesRead.id,
        'wallet.balances.tracked.read',
      );
      expect(
        XelisWalletOperation.walletKnownAssetsRead.id,
        'wallet.assets.known.read',
      );
      expect(
        XelisWalletOperation.walletAssetMetadataRead.id,
        'wallet.asset.metadata.read',
      );
      expect(XelisWalletOperation.walletAssetTrack.id, 'wallet.asset.track');
      expect(
        XelisWalletOperation.walletAssetUntrack.id,
        'wallet.asset.untrack',
      );
      expect(
        XelisWalletOperation.walletHistoryCountRead.id,
        'wallet.history.count.read',
      );
      expect(XelisWalletOperation.walletHistoryRead.id, 'wallet.history.read');
      expect(
        XelisWalletOperation.walletPendingTransactionsRead.id,
        'wallet.transactions.pending.read',
      );

      final delegate = _ReadGeneratedWallet(
        balanceError: const generated_error.NativeXelisError(
          version: XelisWalletErrorContract.currentVersion,
          source: generated_error.NativeXelisErrorSource.xelisWallet,
          code: generated_error.NativeXelisErrorCode.storage,
          nativeKind: 'WALLET_XELIS_BALANCE_READ_FAILED',
          diagnosticMessage: r'database failure at C:\private\wallet.db',
        ),
      );
      final wallet = NativeXelisWallet(delegate);

      try {
        await wallet.getXelisBalance();
        fail('getXelisBalance should throw');
      } on XelisWalletException catch (error) {
        expect(error.source, XelisWalletErrorSource.xelisWallet);
        expect(error.operation, XelisWalletOperation.walletBalanceRead);
        expect(error.code, XelisWalletErrorCode.storageFailure);
        expect(error.nativeKind, 'WALLET_XELIS_BALANCE_READ_FAILED');
        expect(error.toString(), isNot(contains('private')));
      }
    },
  );

  test('explicit u128 payload remains exact through the Dart adapter', () {
    const maximum = '340282366920938463463374607431768211455';
    final transaction = xelisWalletTransactionFromGenerated(
      generated_event.NativeWalletTransactionEntry(
        hash: 'hash',
        topoheight: BigInt.one,
        timestampMillis: BigInt.one,
        entry: generated_event.NativeWalletTransactionEntryData.incoming(
          from: 'xel:source',
          transfers: [
            generated_event.NativeWalletTransferIn(
              asset: 'asset',
              amount: BigInt.one,
              extraData: generated_event.NativeWalletExtraData(
                flag: generated_event.NativeWalletExtraDataFlag.public,
                hasPayload: true,
                payload: const generated_address.NativeXelisDataElement.value(
                  value: generated_address.NativeXelisDataValue.unsignedInteger(
                    integerType:
                        generated_address.NativeXelisUnsignedIntegerType.u128,
                    decimalValue: maximum,
                  ),
                ),
                payloadKind:
                    generated_event.NativeWalletExtraDataPayloadKind.u128,
              ),
            ),
          ],
        ),
      ),
      extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
    );

    final extraData = (transaction.entry as XelisWalletIncomingEntry)
        .transfers
        .single
        .extraData!;
    expect(
      extraData.payload,
      XelisDataElement.value(
        XelisDataValue.unsigned(
          type: XelisUnsignedIntegerType.u128,
          value: BigInt.parse(maximum),
        ),
      ),
    );
    expect(extraData.payloadKind, XelisWalletExtraDataPayloadKind.u128);
  });
}

const _sensitivePayload = XelisDataElement.value(
  XelisDataValue.string('sensitive application payload'),
);

const _overinformativeNativeExtraData = generated_event.NativeWalletExtraData(
  flag: generated_event.NativeWalletExtraDataFlag.private,
  hasPayload: true,
  payload: generated_address.NativeXelisDataElement.value(
    value: generated_address.NativeXelisDataValue.stringValue(
      value: 'sensitive application payload',
    ),
  ),
  payloadKind: generated_event.NativeWalletExtraDataPayloadKind.string,
);

generated_event.NativeWalletTransactionEntry
_overinformativeConfirmedTransaction() =>
    generated_event.NativeWalletTransactionEntry(
      hash: 'confirmed-hash',
      topoheight: BigInt.one,
      timestampMillis: BigInt.two,
      entry: generated_event.NativeWalletTransactionEntryData.incoming(
        from: 'xel:source',
        transfers: [
          generated_event.NativeWalletTransferIn(
            asset: 'asset',
            amount: BigInt.one,
            extraData: _overinformativeNativeExtraData,
          ),
        ],
      ),
    );

generated_event.NativeWalletPendingTransaction
_overinformativePendingTransaction() =>
    generated_event.NativeWalletPendingTransaction(
      hash: 'pending-hash',
      timestampMillis: BigInt.two,
      entry: generated_event.NativeWalletTransactionEntryData.incoming(
        from: 'xel:source',
        transfers: [
          generated_event.NativeWalletTransferIn(
            asset: 'asset',
            amount: BigInt.one,
            extraData: _overinformativeNativeExtraData,
          ),
        ],
      ),
    );

XelisWalletExtraData _confirmedExtraData(
  XelisWalletTransactionEntry transaction,
) =>
    (transaction.entry as XelisWalletIncomingEntry).transfers.single.extraData!;

XelisWalletExtraData _pendingExtraData(
  XelisWalletPendingTransaction transaction,
) =>
    (transaction.entry as XelisWalletIncomingEntry).transfers.single.extraData!;

void _expectExtraDataDisclosure(
  XelisWalletExtraData extraData,
  XelisWalletExtraDataDisclosure disclosure,
) {
  expect(extraData.flag, XelisWalletExtraDataFlag.private);
  expect(extraData.hasPayload, isTrue);
  expect(
    extraData.payload,
    disclosure == XelisWalletExtraDataDisclosure.detailed
        ? _sensitivePayload
        : null,
  );
  expect(
    extraData.payloadKind,
    disclosure == XelisWalletExtraDataDisclosure.redacted
        ? null
        : XelisWalletExtraDataPayloadKind.string,
  );
}

final class _ReadGeneratedWallet implements generated_wallet.XelisWallet {
  _ReadGeneratedWallet({
    BigInt? xelisBalance,
    this.trackedBalances = const {},
    this.knownAssets = const {},
    generated_models.XelisAssetMetadata? metadata,
    BigInt? historyCount,
    this.historyEntries = const [],
    this.pendingEntries = const [],
    this.detailEntry,
    this.pendingDetailEntry,
    this.balanceError,
    this.csv = '',
    this.csvError,
  }) : xelisBalance = xelisBalance ?? BigInt.zero,
       historyCount = historyCount ?? BigInt.zero,
       metadata =
           metadata ??
           const generated_models.XelisAssetMetadata(
             name: 'XELIS',
             ticker: 'XEL',
             decimals: 8,
             maxSupply: generated_models.XelisMaxSupplyMode.none(),
             owner: generated_models.XelisAssetOwner.none(),
           );

  final BigInt xelisBalance;
  final Map<String, BigInt> trackedBalances;
  final Map<String, generated_models.XelisAssetMetadata> knownAssets;
  final generated_models.XelisAssetMetadata metadata;
  final BigInt historyCount;
  final List<generated_event.NativeWalletTransactionEntry> historyEntries;
  final List<generated_event.NativeWalletPendingTransaction> pendingEntries;
  final generated_event.NativeWalletTransactionEntry? detailEntry;
  final generated_event.NativeWalletPendingTransaction? pendingDetailEntry;
  final Object? balanceError;
  final String csv;
  final Object? csvError;

  generated_models.HistoryPageFilter? lastFilter;
  generated_models.HistoryPageFilter? lastCsvConversionFilter;
  generated_models.HistoryPageFilter? lastCsvFileExportFilter;
  String? lastCsvFileExportPath;
  generated_event.NativeWalletExtraDataDisclosure?
  lastHistoryExtraDataDisclosure;
  generated_event.NativeWalletExtraDataDisclosure?
  lastPendingExtraDataDisclosure;
  (String, generated_event.NativeWalletExtraDataDisclosure)? detailArguments;
  (String, generated_event.NativeWalletExtraDataDisclosure)?
  pendingDetailArguments;
  String? trackedAsset;
  String? untrackedAsset;

  @override
  bool get isDisposed => false;

  @override
  Future<BigInt> getXelisBalance() async {
    if (balanceError case final error?) {
      throw error;
    }
    return xelisBalance;
  }

  @override
  Future<Map<String, BigInt>> getTrackedBalances() async => trackedBalances;

  @override
  Future<Map<String, generated_models.XelisAssetMetadata>>
  getKnownAssets() async => knownAssets;

  @override
  Future<generated_models.XelisAssetMetadata> getAssetMetadata({
    required String asset,
  }) async => metadata;

  @override
  Future<bool> trackAsset({required String asset}) async {
    trackedAsset = asset;
    return true;
  }

  @override
  Future<bool> untrackAsset({required String asset}) async {
    untrackedAsset = asset;
    return true;
  }

  @override
  Future<BigInt> getHistoryCount() async => historyCount;

  @override
  Future<List<generated_event.NativeWalletTransactionEntry>> history({
    required generated_models.HistoryPageFilter filter,
    required generated_event.NativeWalletExtraDataDisclosure
    extraDataDisclosure,
  }) async {
    lastFilter = filter;
    lastHistoryExtraDataDisclosure = extraDataDisclosure;
    return historyEntries;
  }

  @override
  Future<String> convertTransactionsToCsv({
    required generated_models.HistoryPageFilter filter,
  }) async {
    if (csvError case final error?) {
      throw error;
    }
    lastCsvConversionFilter = filter;
    return csv;
  }

  @override
  Future<void> exportTransactionsToCsvFile({
    required String filePath,
    required generated_models.HistoryPageFilter filter,
  }) async {
    if (csvError case final error?) {
      throw error;
    }
    lastCsvFileExportPath = filePath;
    lastCsvFileExportFilter = filter;
  }

  @override
  Future<List<generated_event.NativeWalletPendingTransaction>>
  getPendingTransactions({
    required generated_event.NativeWalletExtraDataDisclosure
    extraDataDisclosure,
  }) async {
    lastPendingExtraDataDisclosure = extraDataDisclosure;
    return pendingEntries;
  }

  @override
  Future<generated_event.NativeWalletTransactionEntry> getTransactionByHash({
    required String hash,
    required generated_event.NativeWalletExtraDataDisclosure
    extraDataDisclosure,
  }) async {
    detailArguments = (hash, extraDataDisclosure);
    return detailEntry!;
  }

  @override
  Future<generated_event.NativeWalletPendingTransaction>
  getPendingTransactionByHash({
    required String hash,
    required generated_event.NativeWalletExtraDataDisclosure
    extraDataDisclosure,
  }) async {
    pendingDetailArguments = (hash, extraDataDisclosure);
    return pendingDetailEntry!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
