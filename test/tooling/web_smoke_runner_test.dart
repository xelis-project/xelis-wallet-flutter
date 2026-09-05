import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/src/tooling/web_smoke_runner.dart';

void main() {
  test('maps supported Web asset content types', () {
    expect(webSmokeContentType('index.HTML'), 'text/html; charset=utf-8');
    expect(
      webSmokeContentType('flutter_bootstrap.js'),
      'text/javascript; charset=utf-8',
    );
    expect(webSmokeContentType('wallet.wasm'), 'application/wasm');
    expect(webSmokeContentType('asset.unknown'), 'application/octet-stream');
  });

  test('accepts only normalized relative Web asset paths', () {
    expect(safeWebSmokeRelativePath(Uri.parse('/')), 'index.html');
    expect(
      safeWebSmokeRelativePath(Uri.parse('/assets/wallet.wasm')),
      ['assets', 'wallet.wasm'].join(Platform.pathSeparator),
    );
    expect(safeWebSmokeRelativePath(Uri.parse('/a%2Fb')), isNull);
    expect(safeWebSmokeRelativePath(Uri.parse('/a%5Cb')), isNull);
  });

  test('serves assets with isolation headers and records the result', () async {
    final workspace = await Directory.systemTemp.createTemp(
      'xwf_web_smoke_server_test_',
    );
    addTearDown(() async {
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    });
    await File.fromUri(workspace.uri.resolve('index.html'))
        .writeAsString('<html>ready</html>');

    final handler = WebSmokeRequestHandler(workspace);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen(handler.handleRequest);
    final client = HttpClient();
    addTearDown(() async {
      client.close(force: true);
      await subscription.cancel();
      await server.close(force: true);
    });

    final base = Uri.parse('http://${server.address.address}:${server.port}');
    final assetResponse = await (await client.getUrl(base.resolve('/')))
        .close();
    expect(assetResponse.statusCode, HttpStatus.ok);
    expect(
      assetResponse.headers.value('Cross-Origin-Opener-Policy'),
      'same-origin',
    );
    expect(
      assetResponse.headers.value('Cross-Origin-Embedder-Policy'),
      'require-corp',
    );
    expect(
      assetResponse.headers.value(HttpHeaders.cacheControlHeader),
      'no-store',
    );
    expect(await utf8.decoder.bind(assetResponse).join(), '<html>ready</html>');

    final missingResponse = await (await client.getUrl(
      base.resolve('/missing.js'),
    )).close();
    expect(missingResponse.statusCode, HttpStatus.notFound);

    final resultResponse = await (await client.getUrl(
      base.resolve(
        '$webConsumerSmokeResultPath?value='
        '$webConsumerSmokeSuccessMarker',
      ),
    )).close();
    expect(resultResponse.statusCode, HttpStatus.noContent);
    expect(await handler.result, webConsumerSmokeSuccessMarker);
  });
}
