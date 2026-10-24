import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';

/// Tela de diagnóstico do alarme (acessada pelo Perfil).
/// Serve para o grupo testar e mostrar na apresentação da RT03.
class TesteNotificacoesScreen extends StatefulWidget {
  const TesteNotificacoesScreen({super.key});

  @override
  State<TesteNotificacoesScreen> createState() => _TesteNotificacoesScreenState();
}

class _TesteNotificacoesScreenState extends State<TesteNotificacoesScreen> {
  bool? _permitido;
  bool? _exato;
  List<PendingNotificationRequest> _pendentes = [];
  String? _ultimoTeste;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  Future<void> _atualizar() async {
    final n = Notificacoes.instance;
    final permitido = await n.notificacoesPermitidas();
    final exato = await n.alarmeExatoPermitido();
    final pendentes = [...await n.pendentes()]..sort((a, b) => a.id.compareTo(b.id));
    if (!mounted) return;
    setState(() {
      _permitido = permitido;
      _exato = exato;
      _pendentes = pendentes;
    });
  }

  Future<void> _testeAgendado(int segundos) async {
    final (quando, modo) = await Notificacoes.instance.testeAgendado(segundos);
    if (!mounted) return;
    setState(() => _ultimoTeste =
        'Agendado para ${hhmmDe(quando)}:${doisDigitos(quando.second)} — modo $modo.\n'
        'Agora BLOQUEIE a tela ou FECHE o app (tire dos recentes) e espere.');
    await _atualizar();
  }

  Future<void> _alternarReserva(bool ligar) async {
    final p = prefsNotifier.value.copyWith(modoReserva: ligar);
    await Banco.instance.salvarPreferencias(p);
    prefsNotifier.value = p;
    if (ligar) {
      Notificacoes.instance.ligarReserva(
          () => Banco.instance.listarMedicamentos(somenteAtivos: true));
    } else {
      Notificacoes.instance.desligarReserva();
    }
    setState(() {});
  }

  Future<void> _reagendarTudo() async {
    final meds = await Banco.instance.listarMedicamentos(somenteAtivos: true);
    await Notificacoes.instance.reagendarTodos(meds);
    mostrarAviso('${meds.length} remédio(s) reagendado(s).');
    await _atualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _atualizar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BotaoVoltar(),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Testar alarme',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Cartao(
                child: Column(
                  children: [
                    _Status(
                      titulo: 'Notificações permitidas',
                      ok: _permitido,
                      acao: 'Pedir',
                      onAcao: () async {
                        await Notificacoes.instance.pedirPermissoes();
                        await _atualizar();
                      },
                    ),
                    const Divider(),
                    _Status(
                      titulo: 'Alarme no horário exato',
                      ok: _exato,
                      acao: 'Permitir',
                      onAcao: () async {
                        await Notificacoes.instance.pedirAlarmeExato();
                        await _atualizar();
                      },
                    ),
                    const Divider(),
                    _Status(
                      titulo: 'Abrir em tela cheia (Android 14+)',
                      ok: null,
                      acao: 'Ajustar',
                      onAcao: () => Notificacoes.instance.pedirTelaCheia(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const TituloSecao('Testes'),
              const SizedBox(height: 10),
              BotaoGrande(
                texto: '1. Mostrar notificação agora',
                icone: Icons.notifications,
                fundo: Cores.vinho,
                onPressed: () => Notificacoes.instance.testeAgora(),
              ),
              const SizedBox(height: 12),
              BotaoGrande(
                texto: '2. Agendar daqui a 1 minuto',
                icone: Icons.alarm,
                fundo: Cores.vinhoEscuro,
                onPressed: () => _testeAgendado(60),
              ),
              if (_ultimoTeste != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Cores.cremeAmarelo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(_ultimoTeste!,
                      style: const TextStyle(fontSize: 16, color: Cores.marrom)),
                ),
              ],
              const SizedBox(height: 12),
              BotaoGrande(
                texto: 'Reagendar todos os remédios',
                icone: Icons.refresh,
                fundo: Colors.white,
                corTexto: Cores.vinhoEscuro,
                onPressed: _reagendarTudo,
              ),
              const SizedBox(height: 20),
              Cartao(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: prefsNotifier.value.modoReserva,
                  onChanged: _alternarReserva,
                  title: const Text('Modo reserva',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                    'Liga o método antigo (Timer) junto com o agendamento. Só funciona '
                    'com o app aberto ou em segundo plano. Use se o teste 2 falhar.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TituloSecao('Alarmes agendados no Android (${_pendentes.length})'),
              const SizedBox(height: 8),
              if (_pendentes.isEmpty)
                Text('Nenhum. Cadastre um remédio ou use o teste 2.',
                    style: TextStyle(fontSize: 16, color: corSuave(context))),
              for (final p in _pendentes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• #${p.id}  ${p.title ?? ''}',
                      style: const TextStyle(fontSize: 15)),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Dica para celulares Samsung: Configurações > Aplicativos > este app > '
                  'Bateria > "Sem restrições". Sem isso a economia de bateria pode '
                  'atrasar ou bloquear o alarme.',
                  style: TextStyle(fontSize: 15, color: corSuave(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final String titulo;
  final bool? ok;
  final String acao;
  final VoidCallback onAcao;

  const _Status({
    required this.titulo,
    required this.ok,
    required this.acao,
    required this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icone, Color cor) = switch (ok) {
      true => (Icons.check_circle, Cores.verde),
      false => (Icons.cancel, Cores.erro),
      null => (Icons.help_outline, Cores.textoSuave),
    };
    return Row(
      children: [
        Icon(icone, color: cor, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(titulo, style: const TextStyle(fontSize: 17))),
        if (ok != true)
          TextButton(onPressed: onAcao, child: Text(acao, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
