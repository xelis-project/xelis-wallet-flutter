import 'dart:io';

const consumerSmokeUsage =
    'Usage: dart --packages=.dart_tool/package_config.json '
    'tool/consumer_smoke.dart '
    '--platform <linux|windows|macos|android|ios|web> '
    '--mode <run|build> [--keep]';

const consumerSmokeHelp =
    '''
$consumerSmokeUsage

Generate an isolated Flutter consumer in the system temporary directory.

The run mode loads and calls the Rust library on a desktop target or in a
headless Chrome Web consumer. The build mode creates a release application for
any supported target. By default, the generated workspace is deleted after the
command completes.
''';

const _workspacePrefix = 'xelis_wallet_flutter_consumer_smoke_';
const _webSmokeRunnerPath = 'tool/web_smoke_runner.dart';

enum ConsumerSmokePlatform {
  linux,
  windows,
  macos,
  android,
  ios,
  web;

  bool get supportsRun => switch (this) {
    linux || windows || macos || web => true,
    android || ios => false,
  };
}

enum ConsumerSmokeMode { run, build }

sealed class ConsumerSmokeArguments {
  const ConsumerSmokeArguments();
}

final class ConsumerSmokeHelpArguments extends ConsumerSmokeArguments {
  const ConsumerSmokeHelpArguments();
}

final class ConsumerSmokeExecutionArguments extends ConsumerSmokeArguments {
  const ConsumerSmokeExecutionArguments({
    required this.platform,
    required this.mode,
    required this.keep,
  });

  final ConsumerSmokePlatform platform;
  final ConsumerSmokeMode mode;
  final bool keep;
}

ConsumerSmokeArguments parseConsumerSmokeArguments(List<String> arguments) {
  if (arguments case ['--help']) {
    return const ConsumerSmokeHelpArguments();
  }

  String? platformValue;
  String? modeValue;
  var keep = false;

  for (var index = 0; index < arguments.length; index++) {
    switch (arguments[index]) {
      case '--platform':
        if (platformValue != null || index + 1 >= arguments.length) {
          throw const FormatException(
            'Expected exactly one value after --platform.',
          );
        }
        platformValue = arguments[++index];
      case '--mode':
        if (modeValue != null || index + 1 >= arguments.length) {
          throw const FormatException(
            'Expected exactly one value after --mode.',
          );
        }
        modeValue = arguments[++index];
      case '--keep':
        if (keep) {
          throw const FormatException('--keep may be specified only once.');
        }
        keep = true;
      default:
        throw FormatException('Unknown argument: ${arguments[index]}');
    }
  }

  final platform = ConsumerSmokePlatform.values
      .where((value) => value.name == platformValue)
      .firstOrNull;
  if (platform == null) {
    throw const FormatException(
      'Expected --platform <linux|windows|macos|android|ios|web>.',
    );
  }

  final mode = ConsumerSmokeMode.values
      .where((value) => value.name == modeValue)
      .firstOrNull;
  if (mode == null) {
    throw const FormatException('Expected --mode <run|build>.');
  }
  if (mode == ConsumerSmokeMode.run && !platform.supportsRun) {
    throw FormatException(
      'The run mode is supported only on desktop and Web targets, not '
      '${platform.name}.',
    );
  }

  return ConsumerSmokeExecutionArguments(
    platform: platform,
    mode: mode,
    keep: keep,
  );
}

final class ConsumerSmokeCommand {
  const ConsumerSmokeCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final Directory workingDirectory;
}

typedef ConsumerSmokeProcessRunner = Future<int> Function(
  ConsumerSmokeCommand command,
);

ConsumerSmokeCommand createConsumerProjectCommand({
  required ConsumerSmokePlatform platform,
  required Directory workspace,
}) {
  final consumerDirectory = Directory.fromUri(
    workspace.uri.resolve('consumer/'),
  );
  return ConsumerSmokeCommand(
    executable: 'flutter',
    arguments: [
      'create',
      '--empty',
      '--platforms=${platform.name}',
      '--project-name=xwf_consumer_smoke',
      consumerDirectory.path,
    ],
    workingDirectory: workspace,
  );
}

ConsumerSmokeCommand createConsumerActionCommand({
  required ConsumerSmokePlatform platform,
  required ConsumerSmokeMode mode,
  required Directory consumerDirectory,
}) {
  if (mode == ConsumerSmokeMode.run) {
    if (!platform.supportsRun) {
      throw ArgumentError.value(
        platform,
        'platform',
        'The run mode requires a desktop or Web target.',
      );
    }
    if (platform == ConsumerSmokePlatform.web) {
      return _createWebReleaseBuildCommand(consumerDirectory);
    }
    return ConsumerSmokeCommand(
      executable: 'flutter',
      arguments: [
        'test',
        'integration_test/native_library_smoke_test.dart',
        '-d',
        platform.name,
      ],
      workingDirectory: consumerDirectory,
    );
  }

  return ConsumerSmokeCommand(
    executable: 'flutter',
    arguments: switch (platform) {
      ConsumerSmokePlatform.android => ['build', 'apk', '--release'],
      ConsumerSmokePlatform.ios => [
        'build',
        'ios',
        '--release',
        '--no-codesign',
      ],
      ConsumerSmokePlatform.web => ['build', 'web', '--release'],
      _ => ['build', platform.name, '--release'],
    },
    workingDirectory: consumerDirectory,
  );
}

ConsumerSmokeCommand createWebPackageBuildCommand({
  required Directory consumerDirectory,
}) => ConsumerSmokeCommand(
  executable: 'dart',
  arguments: const [
    'run',
    'xelis_wallet_flutter:build_web',
    '--output',
    'web/pkg',
  ],
  workingDirectory: consumerDirectory,
);

ConsumerSmokeCommand createWebBrowserSmokeCommand({
  required Directory consumerDirectory,
}) => ConsumerSmokeCommand(
  executable: 'dart',
  arguments: const ['run', _webSmokeRunnerPath],
  workingDirectory: consumerDirectory,
);

ConsumerSmokeCommand _createWebReleaseBuildCommand(
  Directory consumerDirectory,
) => ConsumerSmokeCommand(
  executable: 'flutter',
  arguments: const ['build', 'web', '--release'],
  workingDirectory: consumerDirectory,
);

Future<void> writeConsumerSmokeProjectFiles({
  required Directory consumerDirectory,
  required Directory packageRoot,
  required ConsumerSmokePlatform platform,
}) async {
  final packagePath = packageRoot.absolute.path
      .replaceAll('\\', '/')
      .replaceAll("'", "''");

  await File.fromUri(consumerDirectory.uri.resolve('pubspec.yaml'))
      .writeAsString('''
name: xwf_consumer_smoke
description: Ephemeral release consumer for xelis_wallet_flutter.
publish_to: none

environment:
  sdk: ">=3.13.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  xelis_wallet_flutter:
    path: '$packagePath'

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: false
''');

  final libDirectory = Directory.fromUri(consumerDirectory.uri.resolve('lib/'));
  if (platform == ConsumerSmokePlatform.web) {
    await libDirectory.create(recursive: true);
    await File.fromUri(libDirectory.uri.resolve('main.dart'))
        .writeAsString(_webConsumerMainSource);
    final webDirectory = Directory.fromUri(
      consumerDirectory.uri.resolve('web/'),
    );
    final toolDirectory = Directory.fromUri(
      consumerDirectory.uri.resolve('tool/'),
    );
    await webDirectory.create(recursive: true);
    await toolDirectory.create(recursive: true);
    await File.fromUri(webDirectory.uri.resolve('index.html'))
        .writeAsString(_webConsumerIndexSource);
    await File.fromUri(toolDirectory.uri.resolve('web_smoke_runner.dart'))
        .writeAsString(_webSmokeRunnerSource);
    return;
  }

  final integrationTestDirectory = Directory.fromUri(
    consumerDirectory.uri.resolve('integration_test/'),
  );
  await libDirectory.create(recursive: true);
  await integrationTestDirectory.create(recursive: true);

  await File.fromUri(libDirectory.uri.resolve('main.dart')).writeAsString('''
import 'package:flutter/widgets.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

Future<void> runNativeSmoke() async {
  await XelisWalletFlutter.initialize();
  if (!XelisWalletFlutter.isInitialized) {
    throw StateError('The native bridge did not report successful startup.');
  }

  final valid = XelisWalletFlutter.isAddressValid(
    address: 'not-a-xelis-address',
    network: XelisNetwork.mainnet,
  );
  if (valid) {
    throw StateError('The native address validator accepted invalid input.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runNativeSmoke();
  debugPrint('XWF_NATIVE_CONSUMER_SMOKE_PASS');
  runApp(const Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: Text('XWF_NATIVE_CONSUMER_SMOKE_PASS')),
  ));
}
''');

  await File.fromUri(
    integrationTestDirectory.uri.resolve('native_library_smoke_test.dart'),
  ).writeAsString('''
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xwf_consumer_smoke/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads and calls the Rust library', (tester) async {
    await runNativeSmoke();
  });
}
''');
}

const _webConsumerMainSource = r'''
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _baseAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';
const _successMarker = 'XWF_WEB_CONSUMER_SMOKE_PASS';
const _failureMarker = 'XWF_WEB_CONSUMER_SMOKE_FAIL';
final _aboveJavaScriptSafeInteger = BigInt.parse('9007199254740993');
final _maximumUnsigned64 = BigInt.parse('18446744073709551615');

@JS('xwfReportResult')
external void _reportResult(JSString result);

Future<void> runWebAddressIntegerSmoke() async {
  await XelisWalletFlutter.initialize();
  if (!XelisWalletFlutter.isInitialized) {
    throw StateError('The Web bridge did not report successful startup.');
  }

  final integrated = XelisWalletFlutter.makeIntegratedAddress(
    baseAddress: _baseAddress,
    integratedData: XelisDataElement.fields([
      XelisDataField(
        key: const XelisDataValue.string('above_javascript_safe_integer'),
        value: XelisDataElement.value(
          XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u64,
            value: _aboveJavaScriptSafeInteger,
          ),
        ),
      ),
      XelisDataField(
        key: const XelisDataValue.string('maximum_u64'),
        value: XelisDataElement.value(
          XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u64,
            value: _maximumUnsigned64,
          ),
        ),
      ),
    ]),
  );
  final reparsed = XelisWalletFlutter.parseAddress(
    address: integrated.encodedAddress,
  );
  if (reparsed != integrated) {
    throw StateError('The Rust address round trip changed the descriptor.');
  }

  final data = reparsed.integratedData;
  if (data is! XelisDataFields) {
    throw StateError('The integrated address did not retain field data.');
  }
  _expectUnsigned(
    data,
    key: 'above_javascript_safe_integer',
    expected: _aboveJavaScriptSafeInteger,
  );
  _expectUnsigned(data, key: 'maximum_u64', expected: _maximumUnsigned64);
}

void _expectUnsigned(
  XelisDataFields data, {
  required String key,
  required BigInt expected,
}) {
  for (final field in data.fields) {
    if (field.key case XelisDataString(value: final fieldKey)
        when fieldKey == key) {
      final element = field.value;
      if (element is! XelisDataValueElement ||
          element.value is! XelisDataUnsigned) {
        throw StateError('The $key value did not remain an unsigned integer.');
      }
      final unsigned = element.value as XelisDataUnsigned;
      if (unsigned.type != XelisUnsignedIntegerType.u64 ||
          unsigned.value != expected) {
        throw StateError('The $key value changed during the Rust round trip.');
      }
      return;
    }
  }
  throw StateError('The $key value was missing after the Rust round trip.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await runWebAddressIntegerSmoke();
    _reportResult(_successMarker.toJS);
    runApp(const SizedBox.shrink());
  } catch (_) {
    _reportResult(_failureMarker.toJS);
    rethrow;
  }
}
''';

const _webConsumerIndexSource = r'''
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="XWF Web consumer smoke">
  <title>XWF Web consumer smoke</title>
  <script>
    window.xwfReportResult = function(result) {
      document.documentElement.dataset.xwfSmoke = result;
      fetch('/__xwf_smoke_result?value=' + encodeURIComponent(result), {
        cache: 'no-store'
      });
    };
  </script>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';

const _webSmokeRunnerSource = r'''
import 'dart:async';
import 'dart:io';

const _successMarker = 'XWF_WEB_CONSUMER_SMOKE_PASS';
const _successEvidence =
    'XWF_WEB_CONSUMER_SMOKE_PASS initialization=true '
    'address_round_trip=true above_javascript_safe_integer=9007199254740993 '
    'maximum_u64=18446744073709551615';
const _resultPath = '/__xwf_smoke_result';

Future<void> main() async {
  final webRoot = Directory('build/web').absolute;
  if (!await webRoot.exists()) {
    throw StateError('Missing built Web consumer at ${webRoot.path}.');
  }

  final handler = _WebSmokeRequestHandler(webRoot);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final subscription = server.listen(handler.handleRequest);
  final profile = await Directory.systemTemp.createTemp(
    'xwf_web_consumer_chrome_',
  );
  Process? browser;
  try {
    final executable = Platform.environment['CHROME_EXECUTABLE'] ??
        _defaultChromeExecutable();
    final url = 'http://${server.address.address}:${server.port}/';
    browser = await Process.start(
      executable,
      [
        '--headless=new',
        '--no-sandbox',
        '--disable-gpu',
        '--disable-dev-shm-usage',
        '--no-first-run',
        '--no-default-browser-check',
        '--user-data-dir=${profile.path}',
        url,
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    final result = await _waitForResult(handler.result, browser)
        .timeout(const Duration(minutes: 2));
    if (result != _successMarker) {
      throw StateError('The Web consumer reported failure.');
    }
    stdout.writeln(_successEvidence);
  } finally {
    browser?.kill();
    if (browser != null) {
      try {
        await browser.exitCode.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        stderr.writeln('Chrome did not exit within the cleanup timeout.');
      }
    }
    await subscription.cancel();
    await server.close(force: true);
    await _deleteChromeProfile(profile);
  }
}

String _defaultChromeExecutable() => switch (Platform.operatingSystem) {
  'windows' => r'C:\Program Files\Google\Chrome\Application\chrome.exe',
  'macos' => '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  _ => 'google-chrome',
};

Future<String> _waitForResult(Future<String> result, Process browser) =>
    Future.any([
      result,
      browser.exitCode.then<String>(
        (code) => throw StateError(
          'Chrome exited with code $code before the Web smoke completed.',
        ),
      ),
    ]);

Future<void> _deleteChromeProfile(Directory profile) async {
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
        stderr.writeln(
          'Could not delete the Chrome smoke profile after '
          '$maximumAttempts attempts: $error',
        );
        return;
      }
      await Future<void>.delayed(retryDelay);
    }
  }
}

final class _WebSmokeRequestHandler {
  _WebSmokeRequestHandler(this.webRoot);

  final Directory webRoot;
  final Completer<String> _result = Completer<String>();

  Future<String> get result => _result.future;

  Future<void> handleRequest(HttpRequest request) async {
    request.response.headers
      ..set('Cross-Origin-Opener-Policy', 'same-origin')
      ..set('Cross-Origin-Embedder-Policy', 'require-corp')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');

    if (request.uri.path == _resultPath) {
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

    final relativePath = _safeRelativePath(request.uri);
    if (relativePath == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final file = File(
      '${webRoot.path}${Platform.pathSeparator}$relativePath',
    );
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    request.response.headers.contentType = ContentType.parse(
      _contentType(file.path),
    );
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

String? _safeRelativePath(Uri uri) {
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

String _contentType(String path) {
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
''';

bool isOwnedConsumerSmokeWorkspace({
  required Directory workspace,
  required Directory systemTempDirectory,
}) {
  String normalized(String path) {
    final result = Directory(path).absolute.path
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'/+$'), '');
    return Platform.isWindows ? result.toLowerCase() : result;
  }

  return normalized(workspace.parent.path) ==
          normalized(systemTempDirectory.path) &&
      workspace.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last
          .startsWith(_workspacePrefix);
}

Future<int> runConsumerSmoke({
  required ConsumerSmokeExecutionArguments arguments,
  required Directory packageRoot,
  Directory? systemTempDirectory,
  ConsumerSmokeProcessRunner processRunner = runConsumerSmokeCommand,
  IOSink? outputSink,
  IOSink? errorSink,
}) async {
  final tempDirectory = (systemTempDirectory ?? Directory.systemTemp).absolute;
  final workspace = await tempDirectory.createTemp(_workspacePrefix);
  final consumerDirectory = Directory.fromUri(
    workspace.uri.resolve('consumer/'),
  );
  final out = outputSink ?? stdout;
  final errors = errorSink ?? stderr;

  out
    ..writeln('Consumer smoke workspace: ${workspace.path}')
    ..writeln('CONSUMER_SMOKE_WORKSPACE=${workspace.path}');

  try {
    final createExitCode = await processRunner(
      createConsumerProjectCommand(
        platform: arguments.platform,
        workspace: workspace,
      ),
    );
    if (createExitCode != 0) {
      return createExitCode;
    }

    await writeConsumerSmokeProjectFiles(
      consumerDirectory: consumerDirectory,
      packageRoot: packageRoot,
      platform: arguments.platform,
    );

    final pubGetExitCode = await processRunner(
      ConsumerSmokeCommand(
        executable: 'flutter',
        arguments: const ['pub', 'get'],
        workingDirectory: consumerDirectory,
      ),
    );
    if (pubGetExitCode != 0) {
      return pubGetExitCode;
    }

    if (arguments.platform == ConsumerSmokePlatform.web) {
      final webPackageExitCode = await processRunner(
        createWebPackageBuildCommand(consumerDirectory: consumerDirectory),
      );
      if (webPackageExitCode != 0) {
        return webPackageExitCode;
      }
    }

    final actionExitCode = await processRunner(
      createConsumerActionCommand(
        platform: arguments.platform,
        mode: arguments.mode,
        consumerDirectory: consumerDirectory,
      ),
    );
    if (actionExitCode != 0 ||
        arguments.platform != ConsumerSmokePlatform.web ||
        arguments.mode != ConsumerSmokeMode.run) {
      return actionExitCode;
    }

    return await processRunner(
      createWebBrowserSmokeCommand(consumerDirectory: consumerDirectory),
    );
  } on FileSystemException catch (error) {
    errors.writeln('Could not prepare the consumer smoke project: $error');
    return 74;
  } on ProcessException catch (error) {
    errors.writeln('Could not start the consumer smoke command: $error');
    return 127;
  } finally {
    if (arguments.keep) {
      out.writeln('Keeping consumer smoke workspace: ${workspace.path}');
    } else if (isOwnedConsumerSmokeWorkspace(
      workspace: workspace,
      systemTempDirectory: tempDirectory,
    )) {
      try {
        await workspace.delete(recursive: true);
      } on FileSystemException catch (error) {
        errors.writeln(
          'Could not delete consumer smoke workspace ${workspace.path}: $error',
        );
      }
    } else {
      errors.writeln(
        'Refusing to delete an unrecognized consumer smoke workspace: '
        '${workspace.path}',
      );
    }
  }
}

Future<int> runConsumerSmokeCommand(ConsumerSmokeCommand command) async {
  final process = await Process.start(
    command.executable,
    command.arguments,
    workingDirectory: command.workingDirectory.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  return process.exitCode;
}
