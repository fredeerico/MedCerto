import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicamento.dart';
import '../utils/datas.dart';

/// Minutos até a notificação "Você já tomou?" se a dose não for confirmada.
const int kMinutosAcompanhamento = 30;

/// Minutos do botão "+10 min".
const int kMinutosAdiar = 10;

typedef AoResponderNotificacao = void Function(
    int medId, String horario, String? acao);

/// =========================================================================
/// NOTIFICAÇÕES LOCAIS — 2ª tentativa com agendamento NATIVO
///
/// Por que não funcionava antes: o AndroidManifest não declarava os
/// receivers do plugin (ScheduledNotificationReceiver e
/// ScheduledNotificationBootReceiver). Sem eles o Android até guarda o
/// alarme, mas na hora certa não existe ninguém para "acordar" e mostrar a
/// notificação. O `show()` funcionava porque não depende desses receivers.
///
/// O que mudou agora:
///  1. Manifest com os receivers + permissões USE_EXACT_ALARM,
///     SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, USE_FULL_SCREEN_INTENT.
///  2. Modo `AndroidScheduleMode.alarmClock`: o mesmo usado por apps de
///     despertador; é o mais resistente a economia de bateria (Doze).
///  3. Fuso horário configurado (America/Sao_Paulo quando for o caso).
///  4. Cada horário é um alarme que se repete sozinho todo dia (ou nos dias
///     escolhidos) — funciona com o app FECHADO e após reiniciar o celular.
///  5. Modo reserva opcional (Timer), igual ao que funcionava antes, para
///     o caso de algum aparelho ainda bloquear.
/// =========================================================================
class Notificacoes {
  Notificacoes._();
  static final Notificacoes instance = Notificacoes._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Definido no main.dart: o que fazer quando a pessoa toca na notificação.
  AoResponderNotificacao? aoResponder;

  /// Preferências do Perfil que mudam o som/vibração.
  bool vibrar = true;
  bool somAlto = true;

  NotificationResponse? _respostaDeAbertura;
  Timer? _reserva;
  final Set<String> _disparadosReserva = {};

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // ---------------------------------------------------------------------
  // Inicialização e permissões
  // ---------------------------------------------------------------------

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _configurarFuso();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _aoTocar,
    );

    // O app foi aberto tocando numa notificação (estava fechado)?
    final abertura = await _plugin.getNotificationAppLaunchDetails();
    if (abertura?.didNotificationLaunchApp ?? false) {
      _respostaDeAbertura = abertura!.notificationResponse;
    }
  }

  void _configurarFuso() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      const fusos = {
        -2: 'America/Noronha',
        -3: 'America/Sao_Paulo',
        -4: 'America/Manaus',
        -5: 'America/Rio_Branco',
      };
      final nome = fusos[offset.inHours];
      if (nome != null && offset.inMinutes % 60 == 0) {
        tz.setLocalLocation(tz.getLocation(nome));
      }
      // Fora do Brasil fica em UTC: o instante continua certo, porque
      // sempre convertemos a partir do horário local do aparelho.
    } catch (_) {}
  }

  /// Usado no main.dart depois que a primeira tela aparece.
  NotificationResponse? consumirRespostaDeAbertura() {
    final r = _respostaDeAbertura;
    _respostaDeAbertura = null;
    return r;
  }

  Future<void> pedirPermissoes() async {
    final a = _android;
    if (a == null) return;
    await a.requestNotificationsPermission();
    final podeExato = await a.canScheduleExactNotifications() ?? true;
    if (!podeExato) await a.requestExactAlarmsPermission();
  }

  Future<bool> notificacoesPermitidas() async =>
      await _android?.areNotificationsEnabled() ?? false;

  Future<bool> alarmeExatoPermitido() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  Future<void> pedirAlarmeExato() async {
    await _android?.requestExactAlarmsPermission();
  }

  Future<void> pedirTelaCheia() async {
    await _android?.requestFullScreenIntentPermission();
  }

  // ---------------------------------------------------------------------
  // Toque na notificação
  // ---------------------------------------------------------------------

  void _aoTocar(NotificationResponse r) {
    final dados = lerPayload(r.payload);
    if (dados == null) return;
    aoResponder?.call(dados.$1, dados.$2, r.actionId);
  }

  static String criarPayload(int medId, String horario) => '$medId|$horario';

  static (int, String)? lerPayload(String? payload) {
    if (payload == null) return null;
    final partes = payload.split('|');
    if (partes.length != 2) return null;
    final id = int.tryParse(partes[0]);
    if (id == null) return null;
    return (id, partes[1]);
  }

  // ---------------------------------------------------------------------
  // Aparência da notificação
  // ---------------------------------------------------------------------

  /// No Android 8+, som e vibração ficam presos ao canal; por isso há um
  /// canal para cada combinação das preferências.
  String get _canal => 'medcerto_v${vibrar ? 1 : 0}_s${somAlto ? 1 : 0}';

  NotificationDetails _detalhes({bool comAcoes = true}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _canal,
        'Hora do remédio',
        channelDescription: 'Alarmes nos horários dos seus remédios',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        ticker: 'Hora do remédio',
        color: const Color(0xFF7A1E2C),
        enableVibration: vibrar,
        vibrationPattern: vibrar
            ? Int64List.fromList([0, 800, 400, 800, 400, 800])
            : null,
        audioAttributesUsage: somAlto
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        // FLAG_INSISTENT (4): repete o som até a pessoa responder.
        additionalFlags: somAlto ? Int32List.fromList([4]) : null,
        actions: comAcoes
            ? const [
                AndroidNotificationAction('tomei', 'Já tomei',
                    showsUserInterface: true),
                AndroidNotificationAction('adiar', '+$kMinutosAdiar min',
                    showsUserInterface: true),
              ]
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Identificadores
  // id = medId*1000 + indiceHorario*20 + dia   (dia 0 = todo dia; 1..7)
  // acompanhamento = mesmo + 10;  adiar = medId*1000 + 999
  // ---------------------------------------------------------------------

  static int idPrincipal(int medId, int i, int dia) => medId * 1000 + i * 20 + dia;
  static int idAcompanhamento(int medId, int i, int dia) =>
      medId * 1000 + i * 20 + 10 + dia;
  static int idAdiar(int medId) => medId * 1000 + 999;
  static int idReserva(int medId) => medId * 1000 + 998;
  static const int idTesteAgora = 2000000001;
  static const int idTesteAgendado = 2000000002;

  // ---------------------------------------------------------------------
  // Agendamento
  // ---------------------------------------------------------------------

  /// Próxima ocorrência de "HH:mm" depois de [depoisDe].
  /// [dia] 0 = qualquer dia; 1..7 = só naquele dia da semana.
  tz.TZDateTime _proxima(String horario, int dia, tz.TZDateTime depoisDe) {
    final (h, m) = lerHorario(horario);
    var t = tz.TZDateTime(
        tz.local, depoisDe.year, depoisDe.month, depoisDe.day, h, m);
    while (!t.isAfter(depoisDe) || (dia != 0 && t.weekday != dia)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Agenda com o modo mais forte; se o aparelho recusar alarme exato,
  /// cai para o modo inexato (pode atrasar alguns minutos).
  Future<String> _agendar(
    int id,
    String titulo,
    String corpo,
    tz.TZDateTime quando, {
    String? payload,
    DateTimeComponents? repetir,
    bool comAcoes = true,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        titulo,
        corpo,
        quando,
        _detalhes(comAcoes: comAcoes),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
        matchDateTimeComponents: repetir,
      );
      return 'exato (alarmClock)';
    } catch (e) {
      debugPrint('Alarme exato recusado ($e). Usando modo inexato.');
      await _plugin.zonedSchedule(
        id,
        titulo,
        corpo,
        quando,
        _detalhes(comAcoes: comAcoes),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: repetir,
      );
      return 'inexato (sem permissão de alarme exato)';
    }
  }

  String _corpo(Medicamento m) =>
      '${m.textoQuantidade}${m.observacao.isEmpty ? '' : ' · ${m.observacao}'}';

  Future<void> _agendarPar(
    Medicamento m,
    int i,
    int dia,
    tz.TZDateTime depoisDe, {
    bool principal = true,
    bool acompanhamento = true,
  }) async {
    final horario = m.horarios[i];
    final quando = _proxima(horario, dia, depoisDe);
    final repetir = dia == 0
        ? DateTimeComponents.time
        : DateTimeComponents.dayOfWeekAndTime;
    final payload = criarPayload(m.id!, horario);

    if (principal) {
      await _agendar(
        idPrincipal(m.id!, i, dia),
        'Hora do remédio: ${m.nomeCompleto}',
        _corpo(m),
        quando,
        payload: payload,
        repetir: repetir,
      );
    }
    if (acompanhamento) {
      await _agendar(
        idAcompanhamento(m.id!, i, dia),
        'Você já tomou ${m.nomeCompleto}?',
        'Era às $horario. Toque em "Já tomei" para confirmar.',
        quando.add(const Duration(minutes: kMinutosAcompanhamento)),
        payload: payload,
        repetir: repetir,
      );
    }
  }

  /// Agenda todos os horários de um remédio (repetindo sozinhos).
  Future<void> agendarMedicamento(Medicamento m) async {
    if (m.id == null) return;
    await cancelarMedicamento(m.id!);
    if (!m.ativo) return;
    final agora = tz.TZDateTime.now(tz.local);
    final dias = m.todoDia ? const [0] : m.dias;
    for (var i = 0; i < m.horarios.length; i++) {
      for (final dia in dias) {
        await _agendarPar(m, i, dia, agora);
      }
    }
  }

  /// Remove todos os alarmes de um remédio.
  Future<void> cancelarMedicamento(int medId) async {
    final pendentes = await _plugin.pendingNotificationRequests();
    for (final p in pendentes) {
      if (p.id < idTesteAgora && p.id ~/ 1000 == medId) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// Reagenda tudo (ex.: depois de mudar som/vibração no Perfil).
  Future<void> reagendarTodos(List<Medicamento> meds) async {
    await _plugin.cancelAll();
    for (final m in meds) {
      await agendarMedicamento(m);
    }
  }

  /// Dose confirmada: tira a notificação da tela e pula o
  /// "Você já tomou?" de hoje, mantendo os próximos dias.
  Future<void> marcarTomado(Medicamento m, String horario, DateTime dia) async {
    if (m.id == null) return;
    await _plugin.cancel(idAdiar(m.id!));
    final i = m.horarios.indexOf(horario);
    if (i < 0) return;
    final d = m.todoDia ? 0 : dia.weekday;
    if (!m.todoDia && !m.dias.contains(d)) return;

    await _plugin.cancel(idPrincipal(m.id!, i, d));
    await _plugin.cancel(idAcompanhamento(m.id!, i, d));

    // Reagenda a partir do fim do dia da dose (amanhã ou próxima semana).
    final fimDoDia = tz.TZDateTime(tz.local, dia.year, dia.month, dia.day, 23, 59);
    final agora = tz.TZDateTime.now(tz.local);
    await _agendarPar(m, i, d, fimDoDia.isAfter(agora) ? fimDoDia : agora);
  }

  /// Dose desfeita: volta a agendar normalmente.
  Future<void> desmarcarTomado(Medicamento m) => agendarMedicamento(m);

  /// Botão "+10 min".
  Future<DateTime> adiar(Medicamento m, String horario) async {
    final quando = tz.TZDateTime.now(tz.local)
        .add(const Duration(minutes: kMinutosAdiar));
    await _agendar(
      idAdiar(m.id!),
      'Lembrete adiado: ${m.nomeCompleto}',
      _corpo(m),
      quando,
      payload: criarPayload(m.id!, horario),
    );
    return quando;
  }

  // ---------------------------------------------------------------------
  // Modo reserva (Timer) — só funciona com o app aberto ou em 2º plano
  // ---------------------------------------------------------------------

  void ligarReserva(Future<List<Medicamento>> Function() carregar) {
    _reserva?.cancel();
    _reserva = Timer.periodic(const Duration(seconds: 20), (_) async {
      final agora = DateTime.now();
      final hm = hhmmDe(agora);
      for (final m in await carregar()) {
        if (m.id == null || !m.tomaNoDia(agora) || !m.horarios.contains(hm)) {
          continue;
        }
        final chave = '${m.id}|${dataChave(agora)}|$hm';
        if (!_disparadosReserva.add(chave)) continue;
        await _plugin.show(
          idReserva(m.id!),
          'Hora do remédio: ${m.nomeCompleto}',
          _corpo(m),
          _detalhes(),
          payload: criarPayload(m.id!, hm),
        );
      }
    });
  }

  void desligarReserva() {
    _reserva?.cancel();
    _reserva = null;
  }

  bool get reservaLigada => _reserva != null;

  // ---------------------------------------------------------------------
  // Testes (tela "Testar alarme" no Perfil)
  // ---------------------------------------------------------------------

  Future<void> testeAgora() => _plugin.show(
        idTesteAgora,
        'Teste MedCerto',
        'Se você está vendo isto, as notificações estão funcionando.',
        _detalhes(comAcoes: false),
      );

  /// Agenda um alarme de teste daqui a [segundos]. Devolve o horário e o
  /// modo usado (exato ou inexato).
  Future<(DateTime, String)> testeAgendado(int segundos) async {
    final quando =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: segundos));
    final modo = await _agendar(
      idTesteAgendado,
      'Teste de alarme agendado',
      'Agendado para ${hhmmDe(quando)}. O agendamento nativo funciona!',
      quando,
      comAcoes: false,
    );
    return (DateTime.fromMillisecondsSinceEpoch(quando.millisecondsSinceEpoch), modo);
  }

  Future<List<PendingNotificationRequest>> pendentes() =>
      _plugin.pendingNotificationRequests();
}
