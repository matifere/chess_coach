import 'package:flutter_test/flutter_test.dart';
import 'package:chess_coach/main.dart';

void main() {
  testWidgets('Chess board smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChessCoachApp());

    // Verify that the title is present.
    expect(find.text('Turno: Blancas'), findsOneWidget);
  });
}
