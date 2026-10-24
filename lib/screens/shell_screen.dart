import 'package:flutter/material.dart';

import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../widgets/barra_inferior.dart';
import 'adicionar_screen.dart';
import 'hoje_screen.dart';
import 'perfil_screen.dart';
import 'remedios_screen.dart';

/// Esqueleto com a barra inferior: Hoje · Remédios · Adicionar · Perfil.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    abaAtual.value = 0;
    // Pede as permissões depois que a tela aparece (Android 13+).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Notificacoes.instance.pedirPermissoes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: abaAtual,
      builder: (context, aba, _) => Scaffold(
        body: IndexedStack(
          index: aba,
          children: const [
            HojeScreen(),
            RemediosScreen(),
            AdicionarScreen(),
            PerfilScreen(),
          ],
        ),
        bottomNavigationBar: BarraInferior(
          indice: aba,
          aoTocar: (i) => abaAtual.value = i,
        ),
      ),
    );
  }
}
