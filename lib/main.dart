import 'package:flutter/material.dart';

import 'screens/alarme_screen.dart';
import 'screens/inicio_screen.dart';
import 'services/acoes.dart';
import 'services/banco.dart';
import 'services/estado.dart';
import 'services/notificacoes.dart';
import 'theme/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await Banco.instance.lerPreferencias();
  prefsNotifier.value = prefs;

  final notif = Notificacoes.instance;
  notif.vibrar = prefs.vibrar;
  notif.somAlto = prefs.somAlto;
  notif.aoResponder = tratarNotificacao;
  await notif.init();
  if (prefs.modoReserva) {
    notif.ligarReserva(() => Banco.instance.listarMedicamentos(somenteAtivos: true));
  }

  runApp(const MedCertoApp());

  // Se o app foi aberto pela notificação (estava fechado), trata depois
  // que a primeira tela aparecer.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final r = notif.consumirRespostaDeAbertura();
    final dados = Notificacoes.lerPayload(r?.payload);
    if (dados != null) tratarNotificacao(dados.$1, dados.$2, r?.actionId);
  });
}

/// Toque na notificação ou em um dos botões dela.
Future<void> tratarNotificacao(int medId, String horario, String? acao) async {
  final m = await Banco.instance.buscarMedicamento(medId);
  if (m == null) return;
  if (acao == 'tomei') {
    await Acoes.tomar(m, horario);
  } else if (acao == 'adiar') {
    await Acoes.adiar(m, horario);
  } else {
    // Toque na notificação em si: abre a tela "Hora do remédio" (sem PIN,
    // para o idoso responder rápido).
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => AlarmeScreen(medId: medId, horario: horario),
    ));
  }
}

class MedCertoApp extends StatelessWidget {
  const MedCertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: prefsNotifier,
      builder: (context, prefs, _) => MaterialApp(
        title: 'MedCerto',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: mensageiroKey,
        theme: AppTema.claro(altoContraste: prefs.altoContraste),
        // Tamanho da letra escolhido no Perfil vale para o app inteiro.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(prefs.escalaTexto)),
          child: child!,
        ),
        home: const InicioScreen(),
      ),
    );
  }
}
