import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_viva/main.dart';
import 'package:agenda_viva/store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('fluxo integrado com armazenamento real e reabertura', (
    tester,
  ) async {
    Future<void> capture(String name) async {
      for (var frame = 0; frame < 10; frame++) {
        for (final view in binding.renderViews) {
          view.markNeedsPaint();
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      await binding.takeScreenshot(name);
    }

    final email = 'estudo${DateTime.now().millisecondsSinceEpoch}@example.test';
    final store = AgendaStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(AgendaApp(store: store));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await capture('01-login');
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name')), 'Rodrigo');
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.tap(find.byKey(const Key('password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('password')),
      'SomenteTeste123',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('password')))
          .controller!
          .text,
      'SomenteTeste123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await capture('02-calendario');
    await tester.ensureVisible(find.byKey(const Key('open_tasks')));
    await tester.tap(find.byKey(const Key('open_tasks')));
    await tester.pumpAndSettle();
    expect(find.text('Um dia para começar'), findsOneWidget);
    Future<void> add(String title) async {
      await tester.tap(find.byKey(const Key('add_task')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('task_title')), title);
      await tester.tap(find.byKey(const Key('save_task')));
      await tester.pumpAndSettle();
    }

    await add('Revisar widgets');
    await add('Aprender Dart');
    await add('Organizar estudos');
    expect(store.tasks.every((t) => !t.done), true);
    // Concluir a primeira alfabeticamente deve movê-la para o final.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text).data)
        .toList();
    expect(titles, ['Organizar estudos', 'Revisar widgets', 'Aprender Dart']);
    await capture('03-tarefas');
    // Recria a árvore e o repositório, mantendo o armazenamento real do dispositivo.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final restored = AgendaStore(await SharedPreferences.getInstance());
    expect(restored.accounts.containsKey(email), true);
    expect(
      restored.accounts[email]['hash'],
      restored.digest('SomenteTeste123', restored.accounts[email]['salt']),
    );
    await tester.pumpWidget(AgendaApp(store: restored));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), 'Errada123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('password')),
      'SomenteTeste123',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('password')))
          .controller!
          .text,
      'SomenteTeste123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(restored.email, email);
    expect(restored.tasks.length, 3);
    expect(restored.tasks.where((t) => t.done).length, 1);
    await tester.ensureVisible(find.byKey(const Key('open_tasks')));
    await tester.tap(find.byKey(const Key('open_tasks')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover Revisar widgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(restored.tasks.length, 3);
    await tester.tap(find.byTooltip('Remover Revisar widgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(restored.tasks.length, 2);
    await tester.tap(find.byKey(const Key('add_task')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_task')));
    await tester.pumpAndSettle();
    expect(find.text('Escreva uma tarefa.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Escolher outra data'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day == 1 ? 2 : 1);
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open_tasks')));
    await tester.tap(find.byKey(const Key('open_tasks')));
    await tester.pumpAndSettle();
    expect(find.text('Um dia para começar'), findsOneWidget);
    await add('Tarefa de amanhã');
    expect(restored.tasks.where((t) => t.day == dateKey(tomorrow)).length, 1);
  });
}
