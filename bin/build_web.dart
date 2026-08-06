import 'dart:io';

import 'package:xelis_wallet_flutter/src/tooling/web_build.dart';

Future<void> main(List<String> arguments) async {
  final WebBuildArguments parsedArguments;
  try {
    parsedArguments = parseWebBuildArguments(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(buildWebUsage);
    exitCode = 64;
    return;
  }

  if (parsedArguments is WebBuildHelpArguments) {
    stdout.write(buildWebHelp);
    return;
  }

  final packageRoot = await resolveXwfPackageRoot();
  final outputArguments = parsedArguments as WebBuildOutputArguments;
  exitCode = await runWebBuild(
    packageRoot: packageRoot,
    outputDirectory: outputArguments.outputDirectory,
  );
}
