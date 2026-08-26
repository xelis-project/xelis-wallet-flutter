import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter_example/main.dart';

void main() {
  testWidgets('reports a successful smoke run', (tester) async {
    await tester.pumpWidget(NativeSmokeApp(runSmoke: () async {}));
    await tester.pumpAndSettle();

    expect(find.text('Native bridge ready'), findsOneWidget);
  });
}
