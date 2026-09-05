import 'dart:async';
import 'dart:io';

const webConsumerSmokeSuccessMarker = 'XWF_WEB_CONSUMER_SMOKE_PASS';
const webConsumerSmokeSuccessEvidence =
    'XWF_WEB_CONSUMER_SMOKE_PASS initialization=true '
    'address_round_trip=true above_javascript_safe_integer=9007199254740993 '
    'maximum_u64=18446744073709551615';
const webConsumerSmokeResultPath = '/__xwf_smoke_result';

Future<void> runWebConsumerSmoke({
  Directory? webRoot,
  Directory? systemTempDirectory,
  String? chromeExecutable,
  IOSink? outputSink,
  IOSink? errorSink,
}) async {
  final resolvedWebRoot = (webRoot ?? Directory('build/web')).absolute;
  if (!await resolvedWebRoot.exists()) {
    throw StateError('Missing built Web consumer at ${resolvedWebRoot.path}.');
  }

  final handler = WebSmokeRequestHandler(resolvedWebRoot);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final subscription = server.listen(handler.handleRequest);
  final profile = await (systemTempDirectory ?? Directory.systemTemp)
      .createTemp('xwf_web_consumer_chrome_');
  Process? browser;
  try {
    final executable =
        chromeExecutable ??
        Platform.environment['CHROME_EXECUTABLE'] ??
        defaultWebSmokeChromeExecutable();
    final url = 'http://${server.address.address}:${server.port}/';
    browser = await Process.start(executable, [
      '--headless=new',
      '--no-sandbox',
      '--disable-gpu',
      '--disable-dev-shm-usage',
      '--no-first-run',
      '--no-default-browser-check',
      '--user-data-dir=${profile.path}',
      url,
    ], mode: ProcessStartMode.inheritStdio);

    final result = await waitForWebSmokeResult(
      handler.result,
      browser,
    ).timeout(const Duration(minutes: 2));
    if (result != webConsumerSmokeSuccessMarker) {
      throw StateError('The Web consumer reported failure.');
    }
    (outputSink ?? stdout).writeln(webConsumerSmokeSuccessEvidence);
  } finally {
    browser?.kill();
    if (browser != null) {
      try {
        await browser.exitCode.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        (errorSink ?? stderr).writeln(
          'Chrome did not exit within the cleanup timeout.',
        );
      }
    }
    await subscription.cancel();
    await server.close(force: true);
    await deleteWebSmokeChromeProfile(profile, errorSink: errorSink);
  }
}

String defaultWebSmokeChromeExecutable() => switch (Platform.operatingSystem) {
  'windows' => r'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'macos' => '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  _ => 'google-chrome',
};

Future<String> waitForWebSmokeResult(Future<String> result, Process browser) =>
    Future.any([
      result,
      browser.exitCode.then<String>(
        (code) => throw StateError(
          'Chrome exited with code $code before the Web smoke completed.',
        ),
      ),
    ]);

Future<void> deleteWebSmokeChromeProfile(
  Directory profile, {
  IOSink? errorSink,
}) async {
  const retryDelay = Duration(milliseconds: 200);
  const maximumAttempts = 10;
  for (var attempt = 1; attempt <= maximumAttempts; attempt++) {
    try {
      if (await profile.exists()) {
        await profile.delete(recursive: true);
      }
      return;
    } on FileSystemException catch (error) {
      if (attempt == maximumAttempts) {
        (errorSink ?? stderr).writeln(
          'Could not delete the Chrome smoke profile after '
          '$maximumAttempts attempts: $error',
        );
        return;
      }
      await Future<void>.delayed(retryDelay);
    }
  }
}

final class WebSmokeRequestHandler {
  WebSmokeRequestHandler(this.webRoot);

  final Directory webRoot;
  final Completer<String> _result = Completer<String>();

  Future<String> get result => _result.future;

  Future<void> handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('Cross-Origin-Opener-Policy', 'same-origin')
      ..set('Cross-Origin-Embedder-Policy', 'require-corp')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');

    if (request.uri.path == webConsumerSmokeResultPath) {
      final value = request.uri.queryParameters['value'];
      if (value == null || value.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
      } else {
        if (!_result.isCompleted) {
          _result.complete(value);
        }
        request.response.statusCode = HttpStatus.noContent;
      }
      await request.response.close();
      return;
    }

    final relativePath = safeWebSmokeRelativePath(request.uri);
    if (relativePath == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final file = File('${webRoot.path}${Platform.pathSeparator}$relativePath');
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    request.response.headers.contentType = ContentType.parse(
      webSmokeContentType(file.path),
    );
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

String? safeWebSmokeRelativePath(Uri uri) {
  if (uri.path == '/') {
    return 'index.html';
  }
  final segments = uri.pathSegments;
  if (segments.isEmpty ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            segment.contains('/') ||
            segment.contains('\\'),
      )) {
    return null;
  }
  return segments.join(Platform.pathSeparator);
}

String webSmokeContentType(String path) {
  final extension = path.toLowerCase().split('.').last;
  return switch (extension) {
    'html' => 'text/html; charset=utf-8',
    'js' || 'mjs' => 'text/javascript; charset=utf-8',
    'css' => 'text/css; charset=utf-8',
    'json' => 'application/json; charset=utf-8',
    'wasm' => 'application/wasm',
    'png' => 'image/png',
    'svg' => 'image/svg+xml',
    'ico' => 'image/x-icon',
    _ => 'application/octet-stream',
  };
}
