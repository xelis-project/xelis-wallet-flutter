import 'dart:io';

import 'package:xelis_wallet_flutter/src/tooling/consumer_smoke.dart';

Future<void> main(List<String> arguments) async {
  final ConsumerSmokeArguments parsedArguments;
  try {
    parsedArguments = parseConsumerSmokeArguments(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(consumerSmokeUsage);
    exitCode = 64;
    return;
  }

  if (parsedArguments is ConsumerSmokeHelpArguments) {
    stdout.write(consumerSmokeHelp);
    return;
  }

  exitCode = await runConsumerSmoke(
    arguments: parsedArguments as ConsumerSmokeExecutionArguments,
    packageRoot: Directory.current,
  );
}
