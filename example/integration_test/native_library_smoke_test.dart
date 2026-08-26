import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xelis_wallet_flutter_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads and calls the Rust library', (tester) async {
    await tester.pumpWidget(const NativeSmokeApp());
    await tester.pumpAndSettle();

    expect(find.text('Native bridge ready'), findsOneWidget);
  });
}
