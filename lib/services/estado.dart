import 'package:flutter/material.dart';

import '../models/preferencias.dart';

/// Estado global simples, sem pacotes de gerenciamento de estado.

final navigatorKey = GlobalKey<NavigatorState>();
final mensageiroKey = GlobalKey<ScaffoldMessengerState>();

/// Preferências do Perfil (tamanho da letra, contraste, etc.).
final prefsNotifier = ValueNotifier<Preferencias>(const Preferencias());

/// Aumenta sempre que algum remédio ou dose muda; as telas escutam isso
/// para recarregar.
final dadosMudaram = ValueNotifier<int>(0);
void avisarMudanca() => dadosMudaram.value++;

/// Aba selecionada na barra inferior (0 Hoje, 1 Remédios, 2 Adicionar, 3 Perfil).
final abaAtual = ValueNotifier<int>(0);

void mostrarAviso(String texto, {SnackBarAction? acao}) {
  final m = mensageiroKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(texto, style: const TextStyle(fontSize: 16)),
    action: acao,
    duration: Duration(seconds: acao == null ? 3 : 6),
  ));
}
