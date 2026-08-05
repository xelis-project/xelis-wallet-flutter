import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/bridge/adapters/xelis_wallet_adapter.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_book_v2.dart'
    as generated_address_book;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_dtos.dart'
    as generated_address;
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/wallet.dart'
    as generated_wallet;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('address-book CRUD maps every authored value and argument', () async {
    final entry = _nativeEntry('entry-1');
    final delegate = _AddressBookGeneratedWallet(entry: entry);
    final wallet = NativeXelisWallet(delegate);

    final migration = await wallet.migrateAddressBook();
    expect(migration.migratedEntries, 2);
    expect(migration.alreadyComplete, isFalse);

    final page = await wallet.addressBookEntries(
      query: 'alice',
      skip: 3,
      take: 4,
    );
    expect(page.total, 1);
    expect(page.hasMore, isFalse);
    expect(page.entries.single.id, 'entry-1');
    expect(
      page.entries.single.destination.kind,
      XelisSavedDestinationKind.integrated,
    );
    expect(
      page.entries.single.destination.integratedDataKind,
      XelisIntegratedDataKind.string,
    );
    expect(delegate.listArguments, ('alice', 3, 4));

    final upserted = await wallet.upsertAddressBookEntry(
      address: 'xel:integrated',
      displayName: 'Alice',
      destinationLabel: 'Invoice',
      note: 'Reviewed',
    );
    expect(upserted.id, 'entry-1');
    expect(delegate.upsertArguments, (
      'xel:integrated',
      'Alice',
      'Invoice',
      'Reviewed',
    ));

    expect((await wallet.addressBookEntry(entryId: 'entry-1')).id, 'entry-1');
    await wallet.removeAddressBookEntry(entryId: 'entry-1');
    expect(delegate.foundEntryId, 'entry-1');
    expect(delegate.removedEntryId, 'entry-1');
  });

  test(
    'address-book matching preserves exact and typed destination semantics',
    () async {
      final entry = _nativeEntry('entry-1');
      final delegate = _AddressBookGeneratedWallet(entry: entry);
      final wallet = NativeXelisWallet(delegate);

      final exact = await wallet.matchAddressBookAddress(
        address: 'xel:integrated',
      );
      expect(exact, isA<XelisAddressBookExactMatch>());
      expect(delegate.matchedAddress, 'xel:integrated');

      final destination = await wallet.matchAddressBookDestination(
        baseAddress: 'xel:base',
        integratedData: const XelisDataElement.value(
          XelisDataValue.string('invoice'),
        ),
      );
      expect(destination, isA<XelisAddressBookBaseOnlyMatch>());
      expect(delegate.matchedBaseAddress, 'xel:base');
      expect(
        delegate.matchedIntegratedData,
        const generated_address.NativeXelisDataElement.value(
          value: generated_address.NativeXelisDataValue.stringValue(
            value: 'invoice',
          ),
        ),
      );
    },
  );

  test(
    'address-book adapter rejects invalid pagination and native cardinality',
    () async {
      final delegate = _AddressBookGeneratedWallet(
        entry: _nativeEntry('entry-1'),
        malformedMatch: true,
      );
      final wallet = NativeXelisWallet(delegate);

      await expectLater(
        wallet.addressBookEntries(skip: -1),
        throwsA(
          isA<XelisWalletOperationException>().having(
            (error) => error.operation,
            'operation',
            XelisWalletOperation.walletAddressBookList,
          ),
        ),
      );
      expect(delegate.listCalls, 0);

      await expectLater(
        wallet.matchAddressBookAddress(address: 'xel:integrated'),
        throwsA(
          isA<XelisWalletBridgeException>()
              .having(
                (error) => error.operation,
                'operation',
                XelisWalletOperation.walletAddressBookMatch,
              )
              .having(
                (error) => error.nativeKind,
                'nativeKind',
                'ADDRESS_BOOK_MATCH_PROJECTION_INVALID',
              ),
        ),
      );
    },
  );
}

generated_address_book.NativeAddressBookEntry _nativeEntry(String id) =>
    generated_address_book.NativeAddressBookEntry(
      id: id,
      displayName: 'Alice',
      destinationLabel: 'Invoice',
      note: 'Reviewed',
      destination: const generated_address_book.NativeSavedDestination(
        address: 'xel:integrated',
        baseAddress: 'xel:base',
        kind: generated_address_book.NativeSavedDestinationKind.integrated,
        integratedDataKind:
            generated_address_book.NativeIntegratedDataKind.string,
      ),
    );

final class _AddressBookGeneratedWallet
    implements generated_wallet.XelisWallet {
  _AddressBookGeneratedWallet({
    required this.entry,
    this.malformedMatch = false,
  });

  final generated_address_book.NativeAddressBookEntry entry;
  final bool malformedMatch;
  int listCalls = 0;
  (String?, int, int?)? listArguments;
  (String, String, String?, String?)? upsertArguments;
  String? foundEntryId;
  String? removedEntryId;
  String? matchedAddress;
  String? matchedBaseAddress;
  generated_address.NativeXelisDataElement? matchedIntegratedData;

  @override
  bool get isDisposed => false;

  @override
  Future<generated_address_book.NativeAddressBookMigrationResult>
  migrateAddressBookV2() async =>
      const generated_address_book.NativeAddressBookMigrationResult(
        migratedEntries: 2,
        alreadyComplete: false,
      );

  @override
  Future<generated_address_book.NativeAddressBookPage>
  listAddressBookEntriesV2({
    String? query,
    required int skip,
    int? take,
  }) async {
    listCalls++;
    listArguments = (query, skip, take);
    return generated_address_book.NativeAddressBookPage(
      entries: [entry],
      total: 1,
      hasMore: false,
    );
  }

  @override
  Future<generated_address_book.NativeAddressBookEntry>
  upsertAddressBookEntryV2({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  }) async {
    upsertArguments = (address, displayName, destinationLabel, note);
    return entry;
  }

  @override
  Future<generated_address_book.NativeAddressBookEntry> findAddressBookEntryV2({
    required String entryId,
  }) async {
    foundEntryId = entryId;
    return entry;
  }

  @override
  Future<void> removeAddressBookEntryV2({required String entryId}) async {
    removedEntryId = entryId;
  }

  @override
  Future<generated_address_book.NativeAddressBookMatch>
  matchAddressBookAddressV2({required String address}) async {
    matchedAddress = address;
    return generated_address_book.NativeAddressBookMatch(
      kind: generated_address_book.NativeAddressBookMatchKind.exact,
      entries: malformedMatch ? const [] : [entry],
    );
  }

  @override
  Future<generated_address_book.NativeAddressBookMatch>
  matchAddressBookDestinationV2({
    required String baseAddress,
    generated_address.NativeXelisDataElement? integratedData,
  }) async {
    matchedBaseAddress = baseAddress;
    matchedIntegratedData = integratedData;
    return generated_address_book.NativeAddressBookMatch(
      kind: generated_address_book.NativeAddressBookMatchKind.baseOnly,
      entries: [entry],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
