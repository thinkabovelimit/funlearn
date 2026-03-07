import 'package:flutter_test/flutter_test.dart';
import 'package:topic_guesser/main.dart';

void main() {
  testWidgets('renders topic title and start button', (tester) async {
    await tester.pumpWidget(const TopicGuesserApp());

    expect(find.text('Topic Guesser'), findsOneWidget);
    expect(find.text('Start Guessing'), findsOneWidget);
  });
}
