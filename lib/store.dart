import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String alphabetKey(String text) {
  var result = text.toLowerCase();
  const chars = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  chars.forEach((a, b) {
    result = result.replaceAll(a, b);
  });
  return result;
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.day,
    this.done = false,
  });
  final String id;
  final String title;
  final String day;
  bool done;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'day': day,
    'done': done,
  };
  factory Task.fromJson(Map<String, dynamic> j) =>
      Task(id: j['id'], title: j['title'], day: j['day'], done: j['done']);
}

List<Task> sortedTasks(Iterable<Task> tasks) => tasks.toList()
  ..sort((a, b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    return alphabetKey(a.title).compareTo(alphabetKey(b.title));
  });

// Persistência local para demonstração acadêmica; autenticação real exige servidor.
class AgendaStore {
  AgendaStore(this.prefs);
  final SharedPreferences prefs;
  String? email;
  Map<String, dynamic> get accounts =>
      jsonDecode(prefs.getString('accounts') ?? '{}');
  String get name => email == null ? '' : accounts[email]['name'];
  String digest(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  Future<void> register(String name, String email, String password) async {
    email = email.trim().toLowerCase();
    final all = accounts;
    if (all.containsKey(email)) {
      throw StateError('Este e-mail já está cadastrado.');
    }
    final salt = base64Url.encode(
      List.generate(24, (_) => Random.secure().nextInt(256)),
    );
    all[email] = {
      'name': name.trim(),
      'salt': salt,
      'hash': digest(password, salt),
    };
    if (!await prefs.setString('accounts', jsonEncode(all))) {
      throw StateError('Não foi possível salvar o cadastro.');
    }
  }

  bool login(String email, String password) {
    email = email.trim().toLowerCase();
    final account = accounts[email];
    if (account == null ||
        account['hash'] != digest(password, account['salt'])) {
      return false;
    }
    this.email = email;
    return true;
  }

  List<Task> get tasks {
    if (email == null) return [];
    final list = jsonDecode(prefs.getString('tasks:$email') ?? '[]') as List;
    return list.map((e) => Task.fromJson(e)).toList();
  }

  Future<void> save(List<Task> tasks) async {
    if (email == null) throw StateError('Entre na sua conta.');
    if (!await prefs.setString(
      'tasks:$email',
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    )) {
      throw StateError('Não foi possível salvar as tarefas.');
    }
  }

  Future<void> add(String title, DateTime day) async {
    title = title.trim();
    if (title.isEmpty) throw ArgumentError('Escreva uma tarefa.');
    final current = tasks;
    current.add(
      Task(
        id: '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(999999)}',
        title: title,
        day: dateKey(day),
      ),
    );
    await save(current);
  }

  Future<void> toggle(String id) async {
    final current = tasks;
    final task = current.firstWhere((e) => e.id == id);
    task.done = !task.done;
    await save(current);
  }

  Future<void> remove(String id) async =>
      save(tasks.where((e) => e.id != id).toList());
}
