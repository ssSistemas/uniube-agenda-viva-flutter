import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_viva/main.dart';
import 'package:agenda_viva/store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('contas isoladas, login, tarefas persistentes e ordenação', () async {
    final prefs = await SharedPreferences.getInstance();
    final s = AgendaStore(prefs);
    await s.register('Pessoa Teste', 'teste@example.test', 'teste123');
    expect(s.login('teste@example.test', 'errada'), false);
    expect(s.login('teste@example.test', 'teste123'), true);
    await s.add('Zebra', DateTime(2026, 9, 12));
    await s.add('Árvore', DateTime(2026, 9, 12));
    await s.add('Amanhã', DateTime(2026, 9, 13));
    final z = s.tasks.first;
    await s.toggle(z.id);
    final day = sortedTasks(s.tasks.where((t) => t.day == '2026-09-12'));
    expect(day.map((t) => t.title), ['Árvore', 'Zebra']);
    expect(day.last.done, true);
    final restored = AgendaStore(await SharedPreferences.getInstance());
    restored.login('teste@example.test', 'teste123');
    expect(restored.tasks.length, 3);
    await restored.remove(z.id);
    expect(restored.tasks.length, 2);
    await restored.register('Outra Pessoa', 'outra@example.test', 'teste123');
    restored.login('outra@example.test', 'teste123');
    expect(restored.tasks, isEmpty);
    await expectLater(s.add('  ', DateTime.now()), throwsArgumentError);
    expect(prefs.getString('accounts'), isNot(contains('teste123')));
    await expectLater(
      s.register('Duplicado', 'teste@example.test', 'teste123'),
      throwsStateError,
    );
  });
  testWidgets(
    'cadastro, calendário, tarefa, conclusão, cancelamento e remoção',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = AgendaStore(await SharedPreferences.getInstance());
      await tester.pumpWidget(AgendaApp(store: store));
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mode')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('name')), 'Pessoa Teste');
      await tester.enterText(
        find.byKey(const Key('email')),
        'teste@example.test',
      );
      await tester.enterText(find.byKey(const Key('password')), 'teste123');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('open_tasks')));
      await tester.tap(find.byKey(const Key('open_tasks')));
      await tester.pumpAndSettle();
      expect(find.text('Um dia para começar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_task')));
      await tester.pumpAndSettle();
      expect(find.text('Escreva uma tarefa.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('task_title')),
        'Aprender Flutter',
      );
      await tester.tap(find.byKey(const Key('save_task')));
      await tester.pumpAndSettle();
      expect(find.text('Aprender Flutter'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(store.tasks.single.done, true);
      await tester.tap(find.byTooltip('Remover Aprender Flutter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(store.tasks.length, 1);
      await tester.tap(find.byTooltip('Remover Aprender Flutter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
    },
  );
}
