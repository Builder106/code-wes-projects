import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/main.dart';

void main() {
  testWidgets('PianoToolApp smoke test builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PianoToolApp());
    expect(find.byType(PianoToolApp), findsOneWidget);
  });
}
