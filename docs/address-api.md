# Address and integrated-data API

This guide is for Flutter applications that validate, inspect, or create XELIS
standard and integrated addresses through the authored package façade. Parsing
and creation use `xelis-common` through the private native bridge and do not
contact a daemon.

## Public contract

`XelisWalletFlutter.parseAddress` returns a `XelisAddressDescriptor` with:

- `encodedAddress`: the complete standard or integrated address supplied to a
  transaction;
- `baseAddress`: the normal address for the same public key;
- `networkClass`: `mainnet` or `nonMainnet` as encoded by the address format;
- `integratedData`: the exact typed data, or `null` for a standard address.

An address cannot distinguish testnet, devnet, and stagenet from one another.
All three use the non-mainnet address class. Use the application-selected
`XelisNetwork` when that distinction matters.

```dart
final descriptor = XelisWalletFlutter.parseAddress(address: candidate);

if (descriptor.isIntegrated) {
  useDestination(descriptor.encodedAddress);
  showBaseAddress(descriptor.baseAddress);
  inspectTypedData(descriptor.integratedData!);
}
```

## Creating an integrated address

`XelisWalletFlutter.makeIntegratedAddress` accepts a normal base address and a
typed `XelisDataElement`. It returns the same descriptor shape used by parsing.
The base address must not already contain integrated data.

```dart
final paymentData = XelisDataElement.fields([
  XelisDataField(
    key: const XelisDataValue.string('payment_id'),
    value: XelisDataElement.value(
      XelisDataValue.unsigned(
        type: XelisUnsignedIntegerType.u64,
        value: BigInt.parse('18446744073709551615'),
      ),
    ),
  ),
]);

final integrated = XelisWalletFlutter.makeIntegratedAddress(
  baseAddress: recipient,
  integratedData: paymentData,
);

sendTo(integrated.encodedAddress);
```

Creation preserves the base address's network class. The XELIS protocol limits
serialized integrated data to 1,024 bytes. Arrays and field collections contain
at most 255 entries, and a blob contains at most 65,535 bytes. The authored
constructors reject invalid widths, hashes, bytes, duplicate field keys, and
collection counts before crossing the native boundary; the final serialized
size is checked by Rust.

## Lossless data-element contract

`XelisDataElement` mirrors every `xelis-common` variant:

- `XelisDataValueElement` for a scalar value;
- `XelisDataArray` for an ordered collection;
- `XelisDataFields` for ordered key/value fields.

Field keys are `XelisDataValue`, not only strings. The API preserves insertion
order and rejects duplicate typed keys. Scalar variants preserve booleans,
strings, 32-byte hashes, binary blobs, and the exact unsigned widths `u8`,
`u16`, `u32`, `u64`, and `u128`. Unsigned values are public `BigInt` values and
travel across the private bridge as canonical decimal strings, so native and
Web builds do not lose precision.

Arrays, fields, and blobs copy their input and expose unmodifiable lists. The
models deliberately do not stringify their payloads, because integrated data
may be application-sensitive even though it is public on the address.

## Visibility and transaction semantics

Integrated data is embedded in the address and is not secret. Anyone receiving
or inspecting the address can decode it. Applications must not place passwords,
seeds, private keys, personal secrets, or authentication tokens in it.

When an integrated address is used as a transfer destination, XELIS separates
the normal destination and the embedded data for the transaction payload. That
transaction behavior is distinct from parsing or creating the address. An
`encryptExtraData` transaction option applies when building the transfer; it
does not encrypt the integrated address itself.

AddressBook storage, exact destination matching, history disclosure, and
prepared-transaction inspection build on this same typed contract. Consumers
must store the complete `encodedAddress` when the integrated destination is
semantically important and use `baseAddress` only for identity/grouping
decisions that intentionally ignore embedded data. See
[`address-book-api.md`](address-book-api.md),
[`wallet-read-api.md`](wallet-read-api.md), and
[`prepared-transactions.md`](prepared-transactions.md).

## Errors and diagnostics

Invalid calls use the stable `XelisWalletException` contract:

| Operation | Typical code | Native kind examples |
| --- | --- | --- |
| `address.parse` | `input.invalid` | `ADDRESS_INVALID` |
| `address.integrated.create` | `input.invalid` | `ADDRESS_INVALID`, `ADDRESS_NOT_NORMAL`, `INTEGRATED_ADDRESS_DATA_TOO_LARGE` |

Model-constructor validation happens before a façade operation and uses normal
Dart `ArgumentError`, `RangeError`, or `FormatException` values. Once the
façade is called, native failures retain their `source`, stable `operation`,
package-owned `code`, optional `nativeKind`, support ID, diagnostic message, and
original Dart stack trace according to [`error-handling.md`](error-handling.md).
Do not show or log `diagnosticMessage` in the standard user flow.
