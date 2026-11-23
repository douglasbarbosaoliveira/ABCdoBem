import 'package:flutter_test/flutter_test.dart';
import 'package:abc_do_bem/acessibilidade/acessibilidade.dart';
import 'package:abc_do_bem/main.dart';

void main() {
  testWidgets('ABC do Bem renderiza com acessibilidade',
      (WidgetTester tester) async {
    final controller = AcessibilidadeController();

    await tester.pumpWidget(
      MyApp(acessibilidadeController: controller),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}
