import 'package:flutter_test/flutter_test.dart';
import 'package:brainbounce/main.dart';

void main() {
  testWidgets('renders topic title and start button', (tester) async {
    await tester.pumpWidget(const BrainBounceApp());

    expect(find.text('BrainBounce'), findsOneWidget);
    expect(find.text('Start Guessing'), findsOneWidget);
  });
}
