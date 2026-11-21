import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/medicamento.dart';
import '../models/preferencias.dart';

/// Banco SQLite local (tudo fica no celular — RNF03/RNF11).
class Banco {
  Banco._();
  static final Banco instance = Banco._();

  Database? _db;

  Future<Database> get _banco async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), 'medcerto.db');
    return openDatabase(
      caminho,
      version: 1,
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE medicamentos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            dose TEXT,
            quantidade INTEGER,
            observacao TEXT,
            horarios TEXT,
            todo_dia INTEGER,
            dias TEXT,
            estoque INTEGER,
            caixa INTEGER,
            ativo INTEGER,
            cor INTEGER,
            criado_em TEXT
          )''');
        await db.execute('''
          CREATE TABLE registros(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            med_id INTEGER NOT NULL,
            data TEXT NOT NULL,
            horario TEXT NOT NULL,
            momento TEXT,
            UNIQUE(med_id, data, horario)
          )''');
        await db.execute(
            'CREATE TABLE preferencias(chave TEXT PRIMARY KEY, valor TEXT)');
      },
    );
  }

  // ---------------- Remédios ----------------

  Future<List<Medicamento>> listarMedicamentos({bool somenteAtivos = false}) async {
    final db = await _banco;
    final linhas = await db.query(
      'medicamentos',
      where: somenteAtivos ? 'ativo = 1' : null,
      orderBy: 'nome COLLATE NOCASE',
    );
    return linhas.map(Medicamento.fromMap).toList();
  }

  Future<Medicamento?> buscarMedicamento(int id) async {
    final db = await _banco;
    final linhas = await db.query('medicamentos', where: 'id = ?', whereArgs: [id]);
    return linhas.isEmpty ? null : Medicamento.fromMap(linhas.first);
  }

  /// Cria ou atualiza. Devolve o id.
  Future<int> salvarMedicamento(Medicamento m) async {
    final db = await _banco;
    final dados = m.toMap()..remove('id');
    if (m.id == null) return db.insert('medicamentos', dados);
    await db.update('medicamentos', dados, where: 'id = ?', whereArgs: [m.id]);
    return m.id!;
  }

  Future<void> removerMedicamento(int id) async {
    final db = await _banco;
    await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
    await db.delete('registros', where: 'med_id = ?', whereArgs: [id]);
  }

  // ---------------- Doses tomadas ----------------

  Future<void> registrarDose(int medId, String data, String horario) async {
    final db = await _banco;
    await db.insert(
      'registros',
      {
        'med_id': medId,
        'data': data,
        'horario': horario,
        'momento': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removerRegistro(int medId, String data, String horario) async {
    final db = await _banco;
    await db.delete(
      'registros',
      where: 'med_id = ? AND data = ? AND horario = ?',
      whereArgs: [medId, data, horario],
    );
  }

  /// Registros entre duas datas "aaaa-mm-dd" (inclusive).
  Future<List<RegistroDose>> registrosEntre(String inicio, String fim, {int? medId}) async {
    final db = await _banco;
    final linhas = await db.query(
      'registros',
      where: medId == null
          ? 'data >= ? AND data <= ?'
          : 'data >= ? AND data <= ? AND med_id = ?',
      whereArgs: medId == null ? [inicio, fim] : [inicio, fim, medId],
    );
    return linhas.map(RegistroDose.fromMap).toList();
  }

  // ---------------- Preferências ----------------

  Future<Preferencias> lerPreferencias() async {
    final db = await _banco;
    final linhas = await db.query('preferencias');
    return Preferencias.fromMap({
      for (final l in linhas) l['chave'] as String: (l['valor'] as String?) ?? '',
    });
  }

  /// Valor avulso guardado na tabela de preferências (ex.: token da API).
  /// Devolve null quando não existe ou está vazio.
  Future<String?> lerChave(String chave) async {
    final db = await _banco;
    final linhas = await db.query('preferencias',
        where: 'chave = ?', whereArgs: [chave], limit: 1);
    if (linhas.isEmpty) return null;
    final valor = linhas.first['valor'] as String?;
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  Future<void> salvarChave(String chave, String valor) async {
    final db = await _banco;
    await db.insert('preferencias', {'chave': chave, 'valor': valor},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> salvarPreferencias(Preferencias p) async {
    final db = await _banco;
    final lote = db.batch();
    p.toMap().forEach((chave, valor) {
      lote.insert('preferencias', {'chave': chave, 'valor': valor},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await lote.commit(noResult: true);
  }
}
