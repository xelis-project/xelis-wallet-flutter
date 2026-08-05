import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  const fullAddress = 'xel:integrated-secret-address';
  const baseAddress = 'xel:base-address';
  const entry = XelisAddressBookEntry(
    id: 'opaque-id',
    displayName: 'Exchange account',
    destinationLabel: 'Deposit reference',
    note: 'Private local note',
    destination: XelisSavedDestination(
      address: fullAddress,
      baseAddress: baseAddress,
      kind: XelisSavedDestinationKind.integrated,
      integratedDataKind: XelisIntegratedDataKind.string,
    ),
  );

  test(
    'full destination remains authoritative and diagnostics are redacted',
    () {
      expect(entry.destination.address, fullAddress);
      expect(entry.destination.baseAddress, baseAddress);
      expect(entry.destination.hasIntegratedData, isTrue);

      final diagnostic = entry.toString();
      expect(diagnostic, isNot(contains(fullAddress)));
      expect(diagnostic, isNot(contains(baseAddress)));
      expect(diagnostic, isNot(contains('Exchange account')));
      expect(diagnostic, isNot(contains('Private local note')));
    },
  );

  test('pages and ambiguous matches expose immutable entry lists', () {
    final page = XelisAddressBookPage(
      entries: const [entry],
      total: 1,
      hasMore: false,
    );
    final ambiguous = XelisAddressBookAmbiguousMatch(const [entry, entry]);

    expect(() => page.entries.add(entry), throwsUnsupportedError);
    expect(() => ambiguous.entries.clear(), throwsUnsupportedError);
    final exact = const XelisAddressBookExactMatch(entry).entries;
    final baseOnly = const XelisAddressBookBaseOnlyMatch(entry).entries;
    expect(exact, [entry]);
    expect(baseOnly, [entry]);
    expect(() => exact.clear(), throwsUnsupportedError);
    expect(() => baseOnly.add(entry), throwsUnsupportedError);
    expect(const XelisAddressBookNoMatch().entries, isEmpty);
    expect(
      () => XelisAddressBookAmbiguousMatch(const [entry]),
      throwsArgumentError,
    );
  });

  test('address-book operation identifiers are stable and specific', () {
    expect(
      XelisWalletOperation.walletAddressBookMigrate.id,
      'wallet.address_book.migrate',
    );
    expect(
      XelisWalletOperation.walletAddressBookList.id,
      'wallet.address_book.list',
    );
    expect(
      XelisWalletOperation.walletAddressBookUpsert.id,
      'wallet.address_book.upsert',
    );
    expect(
      XelisWalletOperation.walletAddressBookRemove.id,
      'wallet.address_book.remove',
    );
    expect(
      XelisWalletOperation.walletAddressBookFind.id,
      'wallet.address_book.find',
    );
    expect(
      XelisWalletOperation.walletAddressBookMatch.id,
      'wallet.address_book.match',
    );
  });
}
