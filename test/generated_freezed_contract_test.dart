import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/address_book_v2.dart';
import 'package:xelis_wallet_flutter/src/generated/rust_bridge/api/models/runtime_event_dtos.dart';

void main() {
  group('Freezed generated bridge contracts', () {
    const destination = NativeSavedDestination(
      address: 'integrated-address',
      baseAddress: 'base-address',
      kind: NativeSavedDestinationKind.integrated,
      integratedDataKind: NativeIntegratedDataKind.string,
    );
    const entry = NativeAddressBookEntry(
      id: 'entry-1',
      displayName: 'Primary',
      destination: destination,
    );

    test('preserves value equality and copyWith', () {
      const page = NativeAddressBookPage(
        entries: [entry],
        total: 1,
        hasMore: false,
      );

      expect(
        page,
        const NativeAddressBookPage(entries: [entry], total: 1, hasMore: false),
      );
      expect(page.hashCode, equals(page.copyWith().hashCode));
      expect(page.copyWith(total: 2), isNot(equals(page)));
      expect(page.copyWith(total: 2).entries, equals(page.entries));
    });

    test('keeps generated collections unmodifiable', () {
      const page = NativeAddressBookPage(
        entries: [entry],
        total: 1,
        hasMore: false,
      );

      expect(() => page.entries.add(entry), throwsUnsupportedError);
    });

    test('preserves exhaustive union pattern matching', () {
      final event = NativeWalletRuntimeEvent.newTopoHeight(
        topoheight: BigInt.from(42),
      );

      final topoheight = switch (event) {
        NativeWalletRuntimeEvent_NewTopoHeight(:final topoheight) => topoheight,
        _ => fail('Unexpected runtime event variant'),
      };

      expect(topoheight, BigInt.from(42));
    });
  });
}
