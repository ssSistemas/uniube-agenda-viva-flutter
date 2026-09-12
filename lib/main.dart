import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AgendaApp(store: AgendaStore(await SharedPreferences.getInstance())));
}

const violet = Color(0xFF6338D9);
const teal = Color(0xFF087F83);

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key, required this.store});
  final AgendaStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    title: 'Agenda Viva',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: violet),
      scaffoldBackgroundColor: const Color(0xFFF7F5FE),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
    ),
    home: LoginPage(store: store),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.store});
  final AgendaStore store;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false, busy = false, hide = true;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await widget.store.register(name.text, email.text, password.text);
      }
      if (!widget.store.login(email.text, password.text)) {
        throw StateError('E-mail ou senha incorretos.');
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => HomePage(store: widget.store)),
      );
      if (mounted) {
        password.clear();
        setState(() {
          register = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : 'Não foi possível entrar. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [violet, teal]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFD66B),
                        size: 42,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Agenda Viva',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Um dia de cada vez.\nEspaço para o que importa.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  register ? 'Vamos criar sua conta' : 'Bom ter você por aqui',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Seu calendário e suas tarefas, no mesmo lugar.'),
                const SizedBox(height: 20),
                Form(
                  key: form,
                  child: Column(
                    children: [
                      if (register) ...[
                        TextFormField(
                          key: const Key('name'),
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().length < 2
                              ? 'Informe seu nome.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        key: const Key('email'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) =>
                            v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim())
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('password'),
                        controller: password,
                        obscureText: hide,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: hide ? 'Mostrar senha' : 'Ocultar senha',
                            onPressed: () => setState(() => hide = !hide),
                            icon: Icon(
                              hide
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'Use pelo menos 6 caracteres.'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('submit'),
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Aguarde…'
                        : register
                        ? 'Criar conta e entrar'
                        : 'Entrar',
                  ),
                ),
                TextButton(
                  key: const Key('mode'),
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          register = !register;
                          error = null;
                        }),
                  child: Text(
                    register
                        ? 'Já tenho uma conta'
                        : 'Primeiro acesso? Criar conta',
                  ),
                ),
                const Center(
                  child: Text(
                    'Demonstração local • dados neste dispositivo',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final AgendaStore store;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selected = DateTime.now();
  int tab = 0;
  bool busy = false;
  Future<void> act(Future<void> Function() operation) async {
    setState(() => busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> add() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
    if (result != null) await act(() => widget.store.add(result, selected));
  }

  Future<void> remove(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover tarefa?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) await act(() => widget.store.remove(task.id));
  }

  @override
  Widget build(BuildContext context) {
    final list = sortedTasks(
      widget.store.tasks.where((e) => e.day == dateKey(selected)),
    );
    final pending = list.where((e) => !e.done).length;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Agenda Viva',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              widget.store.email = null;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [teal, Color(0xFF105D78)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${widget.store.name.split(' ').first} ☀',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pending == 0
                            ? 'Seu dia está aberto a possibilidades.'
                            : '$pending ${pending == 1 ? 'tarefa esperando' : 'tarefas esperando'} por você.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _badge('${list.length} tarefas'),
                          const SizedBox(width: 10),
                          _badge('${list.length - pending} concluídas'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (tab == 0) ...[
                  const Text(
                    'Escolha seu dia',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white,
                    child: CalendarDatePicker(
                      initialDate: selected,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: (date) => setState(() => selected = date),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    key: const Key('open_tasks'),
                    onPressed: () => setState(() => tab = 1),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Ver tarefas deste dia'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tarefas · ${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escolher outra data',
                        onPressed: () => setState(() => tab = 0),
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Pendentes primeiro • ordem alfabética'),
                  const SizedBox(height: 18),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.spa_outlined, size: 64, color: teal),
                          SizedBox(height: 16),
                          Text(
                            'Um dia para começar',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Toque em Nova tarefa e dê o primeiro passo.'),
                        ],
                      ),
                    )
                  else
                    ...list.map(
                      (task) => Card(
                        color: task.done
                            ? const Color(0xFFE8F5EF)
                            : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: Checkbox(
                            value: task.done,
                            onChanged: busy
                                ? null
                                : (_) =>
                                      act(() => widget.store.toggle(task.id)),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(task.done ? 'Concluída' : 'Pendente'),
                          trailing: IconButton(
                            tooltip: 'Remover ${task.title}',
                            onPressed: busy ? null : () => remove(task),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_task'),
        onPressed: busy ? null : add,
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendário',
          ),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tarefas'),
        ],
      ),
    );
  }

  Widget _badge(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final controller = TextEditingController();
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Um novo passo'),
    content: TextField(
      key: const Key('task_title'),
      controller: controller,
      autofocus: true,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: 'O que você quer fazer?',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('save_task'),
        onPressed: () {
          final title = controller.text.trim();
          if (title.isEmpty) {
            setState(() => error = 'Escreva uma tarefa.');
            return;
          }
          Navigator.pop(context, title);
        },
        child: const Text('Adicionar'),
      ),
    ],
  );
}
